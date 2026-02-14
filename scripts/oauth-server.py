#!/usr/bin/env python3
"""
Simple OAuth callback server for Google Ads API
Listens on localhost:8080 for the OAuth callback and exchanges the code for tokens
"""

import http.server
import urllib.parse
import json
import urllib.request
import sys
import os
from datetime import datetime
import shutil

# OAuth Configuration
CLIENT_ID = os.environ.get("GOOGLE_ADS_CLIENT_ID", "")
CLIENT_SECRET = os.environ.get("GOOGLE_ADS_CLIENT_SECRET", "")
REDIRECT_URI = "http://localhost:8080/oauth2callback"
PORT = 8080

auth_code = None
refresh_token = None

class OAuthHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Suppress default logging

    def do_GET(self):
        global auth_code, refresh_token

        if self.path.startswith('/oauth2callback'):
            # Parse the query parameters
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)

            if 'code' in params:
                auth_code = params['code'][0]
                print(f"\n✅ Authorization code received: {auth_code[:20]}...")

                # Send success response to browser
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(b"""
                    <html>
                    <head><title>Authorization Successful</title></head>
                    <body style="font-family: Arial; padding: 50px; text-align: center;">
                        <h1 style="color: green;">✅ Authorization Successful!</h1>
                        <p>You can close this window and return to the terminal.</p>
                    </body>
                    </html>
                """)

                # Exchange code for tokens
                print("Exchanging authorization code for tokens...")
                data = urllib.parse.urlencode({
                    'code': auth_code,
                    'client_id': CLIENT_ID,
                    'client_secret': CLIENT_SECRET,
                    'redirect_uri': REDIRECT_URI,
                    'grant_type': 'authorization_code'
                }).encode()

                req = urllib.request.Request('https://oauth2.googleapis.com/token', data=data)
                try:
                    with urllib.request.urlopen(req) as response:
                        result = json.loads(response.read().decode())

                        if 'refresh_token' in result:
                            refresh_token = result['refresh_token']
                            access_token = result['access_token']

                            print("\n" + "="*60)
                            print("✅ SUCCESS! Tokens received:")
                            print("="*60)
                            print(f"\nREFRESH_TOKEN={refresh_token}")
                            print(f"\nAccess Token (expires in 1 hour): {access_token[:30]}...")

                            # Update .claude/settings.env
                            script_dir = os.path.dirname(os.path.abspath(__file__))
                            settings_file = os.path.join(script_dir, '..', '.claude', 'settings.env')

                            if os.path.exists(settings_file):
                                # Backup
                                backup_file = f"{settings_file}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                                shutil.copy2(settings_file, backup_file)
                                print(f"\n✅ Backed up settings to: {os.path.basename(backup_file)}")

                                # Read and update
                                with open(settings_file, 'r') as f:
                                    lines = f.readlines()

                                updated = False
                                for i, line in enumerate(lines):
                                    if line.startswith('REFRESH_TOKEN='):
                                        lines[i] = f"REFRESH_TOKEN={refresh_token}\n"
                                        updated = True
                                        break

                                if not updated:
                                    # Add if not exists
                                    lines.append(f"\nREFRESH_TOKEN={refresh_token}\n")

                                with open(settings_file, 'w') as f:
                                    f.writelines(lines)

                                print(f"✅ Updated {settings_file}")
                            else:
                                print(f"\n⚠️  Settings file not found: {settings_file}")
                                print("Please manually add the refresh token above to your settings.")

                            print("\n" + "="*60)
                            print("🎉 Setup Complete!")
                            print("="*60)
                            print("\nYou can now use the Google Ads API.")
                            print("The refresh token has been saved to .claude/settings.env")

                        else:
                            print("\n❌ Error: No refresh token in response")
                            print("Response from Google:")
                            print(json.dumps(result, indent=2))

                except Exception as e:
                    print(f"\n❌ Error exchanging code for tokens: {e}")
                    import traceback
                    traceback.print_exc()

            elif 'error' in params:
                error = params['error'][0]
                print(f"\n❌ OAuth error: {error}")

                self.send_response(400)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(f"""
                    <html>
                    <body style="font-family: Arial; padding: 50px; text-align: center;">
                        <h1 style="color: red;">❌ Authorization Failed</h1>
                        <p>Error: {error}</p>
                        <p>Please check the terminal for details.</p>
                    </body>
                    </html>
                """.encode())
            else:
                self.send_response(400)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(b"""
                    <html>
                    <body style="font-family: Arial; padding: 50px; text-align: center;">
                        <h1>Error</h1>
                        <p>No authorization code or error received.</p>
                    </body>
                    </html>
                """)

if __name__ == "__main__":
    print("="*60)
    print("Google Ads API - OAuth Token Generator")
    print("="*60)
    print("\nStarting local server on http://localhost:8080...")

    try:
        server = http.server.HTTPServer(('localhost', PORT), OAuthHandler)
        print("✅ Server started successfully")
        print("\nWaiting for OAuth callback...")
        print("(The authorization page should open in your browser)")
        print("\nPress Ctrl+C to cancel")
        print("")

        # Handle one request then shut down
        server.handle_request()
        server.server_close()

        print("\n✅ Server stopped.")

    except KeyboardInterrupt:
        print("\n\n⚠️  Cancelled by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n❌ Error starting server: {e}")
        sys.exit(1)
