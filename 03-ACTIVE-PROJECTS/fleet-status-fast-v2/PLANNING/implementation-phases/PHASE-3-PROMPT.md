# Phase 3: Fleet Status Fast v2 — Apple Shortcut

**Project:** Fleet Status Fast v2 — Gateway Control API
**Dependencies:** Phase 1 complete
**Context Files:** Read PLANNING/IMPLEMENTATION-MASTER-PLAN.md

---

## Objective

Apple Shortcut with full read+write: check status, view system info, trigger remote gateway restarts from iPhone, Apple Watch, and Mac.

---

## Tasks

### Task 1: Design Shortcut Flow
Menu: Quick Status | Restart Gateway | System Info | Restart History

### Task 2: Quick Status Action
GET /fleet/health → notification with status and response time. If unhealthy, prompt to restart.

### Task 3: Restart Gateway Action
Confirmation dialog → POST /fleet/restart → success/failure notification.

### Task 4: System Info Action
GET /fleet/info → formatted display of host, uptime, memory, CPU, versions.

### Task 5: Restart History Action
GET /fleet/history → list of recent restart events.

### Task 6: Apple Watch Support
Simplified version — single tap for status, long press for restart.

### Task 7: Document Shortcut Installation
Step-by-step guide in DOCUMENTATION/SHORTCUT-INSTALL.md.

### Task 8: Test across iPhone, Apple Watch, MacBook Pro.

---

## Success Criteria

- [ ] Quick Status works from iPhone with notification
- [ ] Restart Gateway works with confirmation dialog
- [ ] System Info displays formatted device information
- [ ] Apple Watch can check status and trigger restart
- [ ] Graceful error messages when API unreachable
