"""Локальный сервер разработки PWA без кэша: python3 tools/serve.py [порт]."""
import functools, http.server, pathlib, sys

class NoCache(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

root = pathlib.Path(__file__).resolve().parents[1] / "public"
port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
handler = functools.partial(NoCache, directory=str(root))
http.server.ThreadingHTTPServer(("127.0.0.1", port), handler).serve_forever()
