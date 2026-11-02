"""Verify real two-way LiveKit media with simulated browser devices.
Only the ART KID classroom signalling is mocked; media crosses LiveKit Cloud.
Reads the ignored backend/.local/livekit-config.json for test credentials.
"""
import argparse
import urllib.request
import json,re,time,uuid,base64,hmac,hashlib
from pathlib import Path
from playwright.sync_api import sync_playwright
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--base-url',default='http://localhost:8080')
BASE=parser.parse_args().base_url.rstrip('/')
cfg=json.loads(Path('backend/.local/livekit-config.json').read_text())
room_name='artkid-media-test-'+uuid.uuid4().hex
identities={'instructor':'instructor:media-test','parent':'student:media-test'}
state={role:{'identity':identity,'displayName':role+' Media Test','role':'instructor' if role=='instructor' else 'student','micEnabled':True,'cameraEnabled':True,'connectionState':'connected'} for role,identity in identities.items()}
def sign(role):
 def enc(x):return base64.urlsafe_b64encode(json.dumps(x,separators=(',',':')).encode()).rstrip(b'=').decode()
 now=int(time.time());head=enc({'alg':'HS256','typ':'JWT'});payload=enc({'iss':cfg['ApiKey'],'sub':identities[role],'name':state[role]['displayName'],'nbf':now-5,'exp':now+600,'video':{'roomJoin':True,'room':room_name,'canPublish':True,'canSubscribe':True,'canPublishData':True,'canPublishSources':['camera','microphone']}})
 raw=head+'.'+payload
 return raw+'.'+base64.urlsafe_b64encode(hmac.new(cfg['ApiSecret'].encode(),raw.encode(),hashlib.sha256).digest()).rstrip(b'=').decode()
def mock_room(role):
 def handler(route):
  action=route.request.url.rsplit('/',1)[-1]
  if action in ['token','connect','disconnect']:print('SIGNAL '+role+' '+action,flush=True)
  if action=='token':data={'sessionId':'media-smoke','classId':'media-class','className':'Media test','sessionTitle':'Media test','capacity':20,'roomName':room_name,'roomToken':'test-signalling-only','participantIdentity':identities[role],'participantName':state[role]['displayName'],'participantRole':state[role]['role'],'permissions':{'canPublishAudio':True,'canPublishVideo':True,'canSubscribe':True,'canEndSession':role=='instructor'},'sfu':{'isConfigured':True,'url':cfg['Url'],'accessToken':sign(role)}}
  else:
   if action in ['connect','state']:
    body=route.request.post_data_json or {};state[role].update({k:body[k] for k in ['micEnabled','cameraEnabled','cameraFacing'] if k in body})
   data={'participants':list(state.values()),'screenShare':None,'canShareScreen':False}
  route.fulfill(status=200,content_type='application/json',body=json.dumps(data))
 return handler
with sync_playwright() as p:
 b=p.chromium.launch(channel='msedge',headless=True,args=['--use-fake-ui-for-media-stream','--use-fake-device-for-media-stream','--autoplay-policy=no-user-gesture-required'])
 pages=[]
 passed=False
 try:
  for role in ['instructor','parent']:
   context=b.new_context(viewport={'width':1280,'height':1000},permissions=['camera','microphone'])
   context.add_init_script("""window.testStreams=[];const gum=navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);navigator.mediaDevices.getUserMedia=async c=>{const s=await gum(c);window.testStreams.push(s);return s;};""")
   page=context.new_page();pages.append(page)
   page.on('console',lambda msg:print('BROWSER '+re.sub(r'eyJ[A-Za-z0-9_-]+[.][A-Za-z0-9_-]+[.][A-Za-z0-9_-]+','[TOKEN]',msg.text)[:1200],flush=True) if msg.type in ['error','warning'] or 'Classroom media connection failed' in msg.text else None)
   page.on('websocket',lambda ws: print('WS '+ws.url.split('?')[0],flush=True))
   page.on('requestfailed',lambda req:print('FAILED '+req.url.split('?')[0]+' '+str(req.failure),flush=True))
   request=urllib.request.Request('https://artkid-api.onrender.com/api/v1/auth/login',data=json.dumps({'email':role+'.test@example.com','password':'ArtKids-Test-2026!'}).encode(),headers={'Content-Type':'application/json'})
   with urllib.request.urlopen(request,timeout=20) as response:auth=json.load(response)
   saved={'accessToken':auth['accessToken'],'refreshToken':auth['refreshToken'],'userId':auth['user']['id'],'selectedChildId':'child-1' if role=='parent' else None}
   context.add_init_script('sessionStorage.setItem("artkids.session.v1",'+json.dumps(json.dumps(saved))+');')
   page.route('**/api/v1/live/sessions/media-smoke/room/**',mock_room(role))
   page.goto(BASE+'/#/parent/live/sessions/media-smoke/room',wait_until='domcontentloaded')
   page.wait_for_selector('flt-semantics-placeholder',state='attached',timeout=45000)
   page.locator('flt-semantics-placeholder').evaluate('(e)=>e.click()')
   page.wait_for_function("[...document.querySelectorAll('video')].some(v=>v.videoWidth>0 && !v.paused)",timeout=45000)
   for cycle in range(2):
    for device,kind in [('cam','Video'),('mic','Audio')]:
     page.get_by_role('button',name=re.compile('^T.t '+device)).click()
     page.wait_for_function("window.testStreams.flatMap(s=>s.get"+kind+"Tracks()).every(t=>t.readyState==='ended')")
     page.get_by_role('button',name=re.compile('^B.t '+device)).click()
     page.wait_for_function("window.testStreams.flatMap(s=>s.get"+kind+"Tracks()).some(t=>t.readyState==='live')")
    page.wait_for_function("[...document.querySelectorAll('video')].some(v=>v.videoWidth>0 && !v.paused)")
   print(role+': repeated pre-join camera/microphone restart: PASS',flush=True)
   page.get_by_role('button',name=re.compile('^V.o ph.ng (d.y|h.c) tr.c tuy.n$')).click()
   page.get_by_role('button',name=re.compile('^R.i ph.ng')).wait_for(timeout=45000)
   print(role+': joined actual LiveKit Cloud room',flush=True)
  for page in pages:
   page.wait_for_function("[...document.querySelectorAll('video')].filter(v=>v.videoWidth>0 && !v.paused).length>=2",timeout=45000)
   page.wait_for_function("()=>[...document.querySelectorAll('audio')].some(a=>a.srcObject&&a.srcObject.getAudioTracks().some(t=>t.readyState==='live')&&!a.paused&&a.currentTime>0)",timeout=45000)
  print('Two-way remote video and playing remote audio: PASS',flush=True)
  page=pages[0]
  page.get_by_role('button',name=re.compile('^T.t cam')).click()
  page.wait_for_function("window.testStreams.flatMap(s=>s.getVideoTracks()).every(t=>t.readyState==='ended')")
  page.get_by_role('button',name=re.compile('^B.t cam')).click()
  page.wait_for_function("[...document.querySelectorAll('video')].filter(v=>v.videoWidth>0&&!v.paused).length>=2")
  page.get_by_role('button',name=re.compile('^T.t mic')).click()
  page.wait_for_function("window.testStreams.flatMap(s=>s.getAudioTracks()).every(t=>t.readyState==='ended')")
  page.get_by_role('button',name=re.compile('^B.t mic')).click()
  page.wait_for_function("window.testStreams.flatMap(s=>s.getAudioTracks()).some(t=>t.readyState==='live')")
  print('Camera and microphone restart in room: PASS',flush=True)
  for page in pages:
   page.get_by_role('button',name=re.compile('^R.i ph.ng')).click()
   page.wait_for_function("window.testStreams.flatMap(s=>s.getTracks()).every(t=>t.readyState==='ended')")
  print('Both participants leave and release devices: PASS',flush=True)
  passed=True
 finally:
  if not passed:
   artifacts=Path('backend/tests/artifacts');artifacts.mkdir(parents=True,exist_ok=True)
   for idx,page in enumerate(pages):
    try:page.screenshot(path=str(artifacts/('livekit-failure-'+str(idx)+'.png')))
    except Exception:pass
  b.close()
