# If you are running your external HTTP auth server (for example, this script) on a PacketFence server,
# please make sure that you are configuring your authentication source using the appropriate hostname or IP.
# typically you need to use "containers-gateway.internal" or "100.64.0.1" instead of "127.0.0.1"
# because PacketFence services are now running inside containers using docker, and "127.0.0.1" refers to the
# loopback of the container, not the PacketFence server.

# When using external HTTP authentication source, PacketFence will take parameters such as username and password
# from Form Values. If the programming language you are using does not have a built-in method to extract POST fields,
# you might need to test and debug by specifying this header: "Content-Type: application/x-www-form-urlencoded"

import json
from http.server import BaseHTTPRequestHandler, HTTPServer
import urllib.parse


class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
    res_code_SUCCESS = 1
    res_code_FAILURE = 0

    def do_POST(self):
        if self.path == '/authenticate':
            self.handler_authenticate()
        elif self.path == '/authorize':
            self.handler_authorize()
        else:
            self.send_response(404)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            r = {
                "result": self.res_code_FAILURE,
                "message": "Not Found"
            }
            self.wfile.write(json.dumps(r).encode())

    def extract_credential(self):
        if 'Content-Length' not in self.headers:
            r = {
                "result": self.res_code_FAILURE,
                "message": "Invalid POST payload, missing header Content-Length"
            }
            return r, None, None

        try:
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
        except ValueError:
            r = {
                "result": self.res_code_FAILURE,
                "message": "Invalid Content-Length"
            }
            return r, None, None
        except Exception as e:
            r = {
                "result": self.res_code_FAILURE,
                "message": str(e)
            }
            return r, None, None

        try:
            data = urllib.parse.parse_qs(post_data.decode())

            if 'username' not in data or 'password' not in data:
                r = {
                    "result": self.res_code_FAILURE,
                    "message": "Invalid json payload, missing username or password"
                }
                return r, None, None
            else:
                username = data.get("username", [''])[0]
                password = data.get("password", [''])[0]

                return None, username, password

        except json.JSONDecodeError as e:
            r = {
                "result": self.res_code_FAILURE,
                "message": f"JSON decode error: {str(e)}"
            }
            return r, None, None
        except Exception as e:
            r = {
                "result": self.res_code_FAILURE,
                "message": f"JSON decode error: {str(e)}"
            }
            return r, None, None

    def handler_authenticate(self):
        err, username, password = self.extract_credential()

        if err is not None:
            self.send_response(400)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(err).encode())

        if username == 'test' and password == 'testing123':
            r = {
                "result": self.res_code_SUCCESS,
                "message": "ok"
            }
            self.send_response(200)
        else:
            r = {
                "result": self.res_code_FAILURE,
                "message": "Unauthorized: bad username or password"
            }
            self.send_response(401)

        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(r).encode())

    def handler_authorize(self):
        r = {
            "access_duration": "1D",
            "access_level": "ALL",
            "sponsor": 1,
            "unregdate": "2030-01-01 00:00:00",
            "category": "default",
        }
        self.send_response(200)

        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(r).encode())


def run(server_class=HTTPServer, handler_class=SimpleHTTPRequestHandler, port=10000):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f'Starting server on port {port}...')
    httpd.serve_forever()


if __name__ == '__main__':
    run()
