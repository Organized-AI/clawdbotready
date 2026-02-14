#!/usr/bin/env bash
set -euo pipefail

# OAuth Token Generator for Web App
# This creates a simple local server to handle OAuth callbacks

CLIENT_ID="${GOOGLE_ADS_CLIENT_ID:?Set GOOGLE_ADS_CLIENT_ID env var}"
CLIENT_SECRET="${GOOGLE_ADS_CLIENT_SECRET:?Set GOOGLE_ADS_CLIENT_SECRET env var}"
REDIRECT_URI="http://localhost:8080/oauth2callback"
SCOPE="https://www.googleapis.com/auth/adwords"
PORT=8080

echo "=== Google Ads API - OAuth Token Generator (Web App) ==="
echo ""

# Generate authorization URL
AUTH_URL="https://accounts.google.com/o/oauth2/v2/auth?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&scope=${SCOPE}&response_type=code&access_type=offline&prompt=consent"

echo "Step 1: Opening browser for authorization..."
echo ""
echo "If the browser doesn't open automatically, visit this URL:"
echo "$AUTH_URL"
echo ""

# Open browser
if command -v open &> /dev/null; then
    open "$AUTH_URL"
elif command -v xdg-open &> /dev/null; then
    xdg-open "$AUTH_URL"
fi

echo "Step 2: Waiting for OAuth callback on port $PORT..."
echo ""
echo "A simple web server will start to capture the authorization code."
echo "After you authorize in the browser, the code will be captured automatically."
echo ""

# Create a simple Python HTTP server to capture the callback
export CLIENT_ID CLIENT_SECRET REDIRECT_URI
python3 << 'PYTHON_EOF'
import http.server
import urllib.parse
import sys
import os
import json
import urllib.request

CLIENT_ID = os.environ.get('CLIENT_ID')
CLIENT_SECRET = os.environ.get('CLIENT_SECRET')
REDIRECT_URI = os.environ.get('REDIRECT_URI')
auth_code = None

class OAuthHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # Suppress logging

    def do_GET(self):
        global auth_code

        if self.path.startswith('/oauth2callback'):
            # Parse the query parameters
            query = urllib.parse.urlparse(self.path).query
            params = urllib.parse.parse_qs(query)

            if 'code' in params:
                auth_code = params['code'][0]

                # Send success response
                self.send_response(200)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(b"""
                    <html>
                    <body style="font-family: Arial; padding: 50px; text-align: center;">
                        <h1 style="color: green;">Authorization Successful!</h1>
                        <p>You can close this window and return to the terminal.</p>
                    </body>
                    </html>
                """)

                # Exchange code for tokens
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
                            print("\n✅ Success! Tokens received:")
                            print(f"REFRESH_TOKEN={result['refresh_token']}")
                            print(f"\nAccess Token (expires in 1 hour): {result['access_token'][:20]}...")

                            # Update .claude/settings.env
                            settings_file = os.path.join(os.path.dirname(__file__), '..', '.claude', 'settings.env')
                            if os.path.exists(settings_file):
                                # Backup
                                import shutil
                                from datetime import datetime
                                backup_file = f"{settings_file}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                                shutil.copy2(settings_file, backup_file)

                                # Update
                                with open(settings_file, 'r') as f:
                                    content = f.read()

                                # Replace REFRESH_TOKEN line
                                if 'REFRESH_TOKEN=' in content:
                                    lines = content.split('\n')
                                    for i, line in enumerate(lines):
                                        if line.startswith('REFRESH_TOKEN='):
                                            lines[i] = f"REFRESH_TOKEN={result['refresh_token']}"
                                    content = '\n'.join(lines)
                                else:
                                    content += f"\nREFRESH_TOKEN={result['refresh_token']}\n"

                                with open(settings_file, 'w') as f:
                                    f.write(content)

                                print(f"\n✅ Updated {settings_file}")

                            print("\n=== Setup Complete ===")
                            print("You can now use the Google Ads API!")
                        else:
                            print("\n❌ Error: No refresh token received")
                            print(json.dumps(result, indent=2))

                except Exception as e:
                    print(f"\n❌ Error exchanging code for tokens: {e}")

            else:
                self.send_response(400)
                self.send_header('Content-type', 'text/html')
                self.end_headers()
                self.wfile.write(b"<html><body><h1>Error: No authorization code received</h1></body></html>")

# Set environment variables for Python script
os.environ['CLIENT_ID'] = CLIENT_ID
os.environ['CLIENT_SECRET'] = CLIENT_SECRET
os.environ['REDIRECT_URI'] = REDIRECT_URI

# Start server
server = http.server.HTTPServer(('localhost', 8080), OAuthHandler)
print("Server started on http://localhost:8080")
print("Waiting for authorization...")

# Handle one request then shut down
server.handle_request()
server.server_close()

PYTHON_EOF

echo ""
echo "Server stopped."
