"""Expose only the development VNPay callbacks to a local HTTPS tunnel."""

import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import urllib.error
import urllib.parse
import urllib.request


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None


class CallbackProxy(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass  # Callback query strings must not end up in request logs.

    def do_HEAD(self):
        self.do_GET()

    def do_POST(self):
        self.send_error(405)

    def do_GET(self):
        path = urllib.parse.urlsplit(self.path).path
        if len(self.path) > 8192:
            self.send_error(414)
            return
        if path == '/':
            body = b'<!doctype html><html><head><meta charset="utf-8"><title>ART KID - VNPay Sandbox</title></head><body><h1>ART KID</h1><p>VNPay Sandbox development callback service.</p><p>Local application: http://localhost:8080</p></body></html>'
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(body)))
            self.end_headers()
            if self.command != 'HEAD':
                self.wfile.write(body)
            return
        if path not in ('/health', '/api/v1/payments/vnpay/ipn', '/api/v1/payments/vnpay/return'):
            self.send_error(404)
            return
        opener = urllib.request.build_opener(NoRedirect)
        try:
            try:
                response = opener.open('http://127.0.0.1:5080' + self.path, timeout=15)
            except urllib.error.HTTPError as error:
                response = error
            with response:
                body = response.read(1024 * 1024)
                self.send_response(response.code)
                self.send_header('Content-Type', response.headers.get('Content-Type', 'application/json'))
                if response.headers.get('Location'):
                    self.send_header('Location', response.headers['Location'])
                self.send_header('Content-Length', str(len(body)))
                self.send_header('Cache-Control', 'no-store')
                self.end_headers()
                if self.command != 'HEAD':
                    self.wfile.write(body)
        except (urllib.error.URLError, TimeoutError):
            self.send_error(502, 'Local backend is not available')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=5081)
    arguments = parser.parse_args()
    print(f'VNPay callback proxy listening on 127.0.0.1:{arguments.port}', flush=True)
    ThreadingHTTPServer(('127.0.0.1', arguments.port), CallbackProxy).serve_forever()
