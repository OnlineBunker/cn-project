from http.server import BaseHTTPRequestHandler, HTTPServer
import json

ETAG = '"status-v1"'

class Handler(BaseHTTPRequestHandler):

    def send_json(self, status, payload, head=False):
        body = b"" if status == 304 else json.dumps(payload).encode()

        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("X-Backend", "B")
        self.send_header("Cache-Control", "max-age=30")
        self.send_header("ETag", ETAG)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()

        if not head and body:
            self.wfile.write(body)

    def do_HEAD(self):
        if self.path in ["/", "/api/status"]:
            self.send_json(200, {"backend": "B", "status": "ok"}, head=True)
        else:
            self.send_json(404, {"error": "not found"}, head=True)

    def do_GET(self):
        if self.headers.get("If-None-Match") == ETAG:
            self.send_json(304, {})
            return

        if self.path == "/":
            self.send_json(200, {
                "backend": "B",
                "message": "Backend B running"
            })
        elif self.path == "/api/status":
            self.send_json(200, {
                "backend": "B",
                "status": "ok"
            })
        else:
            self.send_json(404, {"error": "not found"})

    def log_message(self, format, *args):
        print(*args)

server = HTTPServer(("0.0.0.0", 3002), Handler)
print("Backend B running on port 3002")
server.serve_forever()