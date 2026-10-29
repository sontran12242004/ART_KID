// Real Flutter web + API smoke test. Requires Playwright and Edge.
// Start a seeded development API on 5080 and serve build/web on 8080.
// Writes development orders; never run against production. Run from repository root.
const { chromium } = require('playwright');
const fs = require('fs');
const artifacts = 'backend/tests/artifacts';
const webBase = process.env.ARTKIDS_WEB_URL || 'http://localhost:8080';
const apiBase = process.env.ARTKIDS_API_URL || 'http://localhost:5080';
fs.mkdirSync(artifacts, {recursive:true});
const png = Buffer.from('iVBORw0KGgoAAAANSUhEUgAAAUAAAADICAIAAAAWZq/8AAAD8ElEQVR4nO3TMVEdABRE0a8nMnCABtp4QUF6RGCHOgUFZfCQgp19e2augNucx8fXp6TSHvEDSf8dwFJxAEvFASwVB7BUHMBScQBLxQEsFQewVBzAUnEAS8UBLBUHsFQcwFJxAEvFASwVB7BUHMBScQBLxQEsFQewVBzAUnEAS8UBLBUHsFQcwFJxAEvFASwVB7BUHMBScY+/L89T/Xt/murXn9epfr+8TQXw8eKiAAYYYIABBhjggeKiAAYYYIABBhjggQA+XlwUwAADDDDAAAM8UFwUwAADDDDAAAM8EMDHi4sCGGCAAQYYYIAHiosCGGCAAQYYYIAHAvh4cVEAAwwwwAADDPBAcVEAAwwwwAADDPBAAB8vLgpggAEGGGCAAR4oLgpggAEGGGCAAR4I4OPFRQEMMMAAAwwwwAPFRQEMMMAAAwwwwAMBfLy4KIABBhhggAEGeKC4KIABBhhggAEGeCCAjxcXBTDAAAMMMMAADxQXBTDAAAMMMMAADwTw8eKiAAYYYIABBhjggeKiAAYYYIABBhjggQA+XlwUwAADDDDAAAM8UFwUwAADDDDAAAM8EMDHi4sCGGCAAQYYYIAHiosCGGCAAQYYYIAHAvh4cVEAAwwwwAADDPBAcVEAAwwwwAADDPBAAB8vLgpggAEGGGCAAR4oLgpggAEGGGCAAR4I4OPFRQEMMMAAAwwwwAPFRQEMMMAAAwwwwAMBfLy4KIABBhhggAEGeKC4KIABBhhggAEGeCCAjxcXBTDAAAMMMMAADxQXBTDAAAMMMMAADwTw8eKiAAYYYIABBhjggeKiAAYYYIABBhjggQA+XlwUwAADDDDAAAM8UFwUwAADDDDAAAM8EMDHi4sCGGCAAQYYYIAHiosCGGCAAQYYYIAHAvh4cVEAAwwwwAADDPBAcVEAAwwwwAADDPBAAB8vLgpggAEGGGCAAR4oLgpggAEGGGCAAR4I4OPFRQEMMMAAAwwwwAPFRQEMMMAAAwwwwAMBfLy4KIABBhhggAEGeKC4KIABBhhggAEGeCCAjxcXBTDAAAMMMMAADxQXBTDAAAMMMMAADwTw8eKiAAYYYIABBhjggeKiAAYYYIABBhjggQA+XlwUwAADDDDAAAM8UFwUwAADDDDAAAM8EMDHi4sCGGCAAQYYYIAHiosCGGCAAQYYYIAHAvh4cVEAAwwwwAADDPBAcVE/Dfjj61NSaQBLxQEsFQewVBzAUnEAS8UBLBUHsFQcwFJxAEvFASwVB7BUHMBScQBLxQEsFQewVBzAUnEAS8UBLBUHsFQcwFJxAEvFASwVB7BUHMBScQBLxQEsFQewVBzAUnEAS8V9A0UkY1Tq3s7LAAAAAElFTkSuQmCC', 'base64');
const pause = page => page.waitForTimeout(600);
async function go(page, path) { await page.evaluate(p => location.hash=p, path); await pause(page); }
async function field(page, name, value) {
  const input=page.getByRole('textbox',{name,exact:true});
  await input.click(); await page.keyboard.press('Control+A'); await page.keyboard.insertText(value); await pause(page);
}
async function login(browser, role) {
  const page=await browser.newPage({viewport:{width:1280,height:1100}});
  page.setDefaultTimeout(30000);
  page.on('pageerror', e => {throw e;});
  await page.goto(webBase + '/#/parent/login');
  const placeholder=page.locator('flt-semantics-placeholder');
  await placeholder.waitFor({state:'attached',timeout:45000});
  await placeholder.evaluate(e=>e.click()); await pause(page);
  await field(page,'Email',role+'.test@example.invalid');
  await page.keyboard.press('Tab'); await page.keyboard.insertText('ArtKids-Test-2026!');
  await page.getByRole('button',{name:'Đăng Nhập',exact:true}).click();
  await page.waitForURL(/\/#\/(parent|staff)$/);
  return page;
}
async function responseAction(page, method, path, action) {
  const response=page.waitForResponse(r=>r.request().method()===method && r.url().endsWith(path));
  await action(); const result=await response;
  if(result.status()!==200) throw Error(result.status()+': '+await result.text());
  return result.json();
}
(async()=>{
  const browser=await chromium.launch({channel:'msedge',headless:true});
  try {
    const teacher=await login(browser,'instructor');
    await go(teacher,'/staff/courses/course_basics/products/new');
    const chooser=teacher.waitForEvent('filechooser');
    await teacher.getByRole('button',{name:'Chọn hình ảnh học cụ',exact:true}).click();
    await (await chooser).setFiles({name:'kit.png',mimeType:'image/png',buffer:png});
    const title='Browser marketplace '+Date.now();
    await field(teacher,'Tiêu đề học cụ',title);
    await field(teacher,'Giá bán (VNĐ)','125000');
    await field(teacher,'Mô tả công dụng','Brushes and paper for lessons.');
    await teacher.screenshot({path:artifacts+'/marketplace-form-desktop.png'});
    const product=await responseAction(teacher,'POST','/marketplace/listings',()=>teacher.getByRole('button',{name:'Gửi duyệt',exact:true}).click());
    if(product.approvalStatus!=='pending'||product.courseId!=='course_basics')throw Error('Submission contract');
    if((await teacher.request.get(apiBase+product.thumbnailUrl)).status()!==404)throw Error('Pending image leaked');
    console.log('PASS real UI teacher submission, pending image private');
    const admin=await login(browser,'admin');
    let orderConfirmationRequests = 0;
    admin.on('request', r => { if (r.method() === 'POST' && /\/commerce\/orders\/[^/]+\/confirm$/.test(r.url())) orderConfirmationRequests++; });
    await go(admin,'/staff/marketplace/reviews/'+product.id);
    await admin.getByRole('button',{name:'Phê duyệt',exact:true}).waitFor();
    await admin.screenshot({path:artifacts+'/marketplace-review-desktop.png'});
    await responseAction(admin,'POST','/marketplace/reviews/'+product.id,()=>admin.getByRole('button',{name:'Phê duyệt',exact:true}).click());
    console.log('PASS real UI admin approval');
    const parent=await login(browser,'parent');
    await go(parent,'/parent/shop/product/'+product.id);
    await responseAction(parent,'PUT','/commerce/cart/items',()=>parent.getByRole('button',{name:/Thêm.*Giỏ/}).click());
    await go(parent,'/parent/shop/cart');
    await parent.getByRole('button',{name:/Tiến hành thanh toán/}).click();
    await field(parent,'Tên người nhận','Browser Parent');
    await field(parent,'Số điện thoại','0901234567');
    await field(parent,'Địa chỉ nhận học cụ (bắt buộc khi có bộ kit)','123 Browser Test');
    await parent.getByRole('button',{name:/Chuyển khoản/}).click();
    await pause(parent);
    await parent.getByLabel('Thanh toán khi nhận hàng',{exact:true}).last().click();
    const order=await responseAction(parent,'POST','/commerce/checkout',()=>parent.getByRole('button',{name:/Đặt hàng/}).click());
    if(order.order.status !== 'preparing' || order.order.paymentStatus !== 'cod') throw Error('COD checkout must prepare without verifying collection');
    console.log('PASS real UI COD checkout immediately ready for sellers');
    await go(admin,'/staff/orders');
    if(await admin.getByRole('button',{name:/Xác nhận thanh toán|Xác nhận phần hàng nền tảng/}).count()) throw Error('Seller-only COD must not have admin confirmation controls');
    await go(teacher,'/staff/marketplace/orders/'+order.order.id);
    await teacher.getByRole('button',{name:'Ghi nhận đã gửi hàng',exact:true}).waitFor();
    await teacher.screenshot({path:artifacts+'/marketplace-seller-order-desktop.png'});
    await responseAction(teacher,'PUT','/marketplace/orders/'+order.order.id+'/fulfillment',()=>teacher.getByRole('button',{name:'Ghi nhận đã gửi hàng',exact:true}).click());
    await teacher.getByRole('button',{name:'Xác nhận đã giao',exact:true}).waitFor();
    await responseAction(teacher,'PUT','/marketplace/orders/'+order.order.id+'/fulfillment',()=>teacher.getByRole('button',{name:'Xác nhận đã giao',exact:true}).click());
    if(orderConfirmationRequests !== 0) throw Error('Unexpected marketplace order confirmation');
    await go(parent,'/parent/orders');
    const finalResponse = parent.waitForResponse(r => r.request().method() === 'GET' && r.url().endsWith('/commerce/orders/'+order.order.id));
    await go(parent,'/parent/orders/'+order.order.id);
    const finalOrder = (await (await finalResponse).json()).order;
    if(finalOrder.status !== 'delivered' || finalOrder.paymentStatus !== 'cod' || finalOrder.paidAt !== null) throw Error('Delivery must not verify COD collection');
    console.log('PASS real UI seller shipping without admin confirmation; COD collection remains unverified');
    await teacher.setViewportSize({width:390,height:844});
    await go(teacher,'/staff/marketplace/new');
    await teacher.getByRole('button',{name:'Gửi duyệt',exact:true}).waitFor();
    await teacher.screenshot({path:artifacts+'/marketplace-form-mobile.png'});
    console.log('PASS mobile form rendered at 390x844');
  }finally{await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
