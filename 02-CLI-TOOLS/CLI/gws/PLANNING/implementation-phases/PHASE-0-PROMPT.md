# Phase 0 — Project Setup

## Context
Read CLAUDE.md and PLANNING/IMPLEMENTATION-MASTER-PLAN.md first.

## Tasks
1. Create CONFIG/gws-config.template.json with fields: gcp_project_id, oauth_client_id, oauth_client_secret, credentials_path
2. Create CONFIG/clients.template.json with fields: name, workspace_domain, drive_root_folder_id, primary_email
3. Create .gitignore excluding: CONFIG/credentials/, *.json with secrets, .env, node_modules
4. Run `git init` and make initial commit
5. Verify `gws --version` works and log output to DOCUMENTATION/install-log.md

## Success Criteria
- [ ] CONFIG/gws-config.template.json exists
- [ ] CONFIG/clients.template.json exists
- [ ] .gitignore created
- [ ] git repo initialized
- [ ] gws version verified
