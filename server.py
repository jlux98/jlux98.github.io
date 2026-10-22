import http.server

class UTF8Handler(http.server.SimpleHTTPRequestHandler):
    def send_head(self):
        # Setzt den Standard-Zeichensatz für HTML-Dateien auf UTF-8
        self.extensions_map.update({
            '.html': 'text/html; charset=utf-8',
            '.htm': 'text/html; charset=utf-8',
        })
        return super().send_head()

if __name__ == '__main__':
    http.server.test(HandlerClass=UTF8Handler, port=8080)
