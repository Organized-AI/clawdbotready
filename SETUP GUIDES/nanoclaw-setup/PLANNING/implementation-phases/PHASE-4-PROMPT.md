# Phase 4: WhatsApp Authentication

## Objective
Connect NanoClaw to your WhatsApp account via QR code authentication.

## Background
NanoClaw uses the `baileys` library (unofficial WhatsApp Web API) to connect to WhatsApp. Authentication requires scanning a QR code from your phone, similar to linking WhatsApp Web. The session is stored in `store/auth/` and persists across restarts.

## Steps

1. **Run the authentication script**
   ```bash
   cd ~/nanoclaw
   npm run auth
   ```

2. **Scan the QR code**
   - Open WhatsApp on your phone
   - Go to **Settings → Linked Devices → Link a Device**
   - Point your camera at the QR code in the terminal
   - Wait for "Authentication successful" message

3. **Verify session was saved**
   ```bash
   ls -la store/auth/
   # Should contain session files (creds.json, etc.)
   ```

## Important Notes

- **QR code expires quickly** — scan within 30 seconds of it appearing
- **If QR code expires**, the script will generate a new one automatically
- **The session persists** — you only need to scan once. NanoClaw reconnects automatically on restart.
- **Multi-device supported** — this creates a linked device, your phone stays connected independently
- **WhatsApp Web limits** — you can have up to 4 linked devices at a time

## Session Recovery

If WhatsApp disconnects (e.g., phone cleared linked devices):

```bash
# Clear the old session
rm -rf store/auth

# Re-authenticate
npm run auth
```

## Security

- The `store/auth/` directory is **never** mounted into agent containers
- Only the host process uses the WhatsApp connection
- Agents communicate back through IPC, not directly through WhatsApp

## Success Criteria
- [ ] QR code scanned successfully
- [ ] "Authentication successful" message received
- [ ] `store/auth/` contains session files
- [ ] NanoClaw can send a test message (verified in Phase 8)
