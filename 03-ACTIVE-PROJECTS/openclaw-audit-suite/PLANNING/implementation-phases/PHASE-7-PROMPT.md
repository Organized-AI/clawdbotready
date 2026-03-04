# Phase 7: Integration Testing + Hardening

## Prerequisites
- All previous phases complete

## Context Files to Read First
- PLANNING/IMPLEMENTATION-MASTER-PLAN.md
- All PHASE-X-COMPLETE.md files

## Tasks

### Task 1: End-to-End Test Suite
Build `tests/e2e/`:
- Full flow: Leadsie webhook → adapter pull → engine audit → scoring → dashboard
- Test with 3 platforms connected (Meta Ads + Shopify + GA)
- Test with all 11 platforms connected
- Test with 1 platform connected (minimum viable audit)
- Test partial failures (2 of 5 adapters fail)

### Task 2: Load Testing
- Simulate 50 concurrent audits
- Measure adapter pull times under load
- Verify WebSocket connections scale
- Identify bottlenecks in scoring pipeline

### Task 3: Security Hardening
- Audit all token storage (encryption at rest)
- Rate limiting on all API routes
- Input validation on all user-facing endpoints
- CORS configuration for production
- CSP headers for dashboard
- Gmail/Slack: verify metadata-only access (no message bodies)

### Task 4: Error Handling
- Graceful degradation when platforms are partially accessible
- User-friendly error messages in dashboard
- Retry logic for transient API failures
- Audit state recovery (resume from last successful step)

### Task 5: Monitoring + Logging
- Structured logging (pino) across all services
- Audit completion metrics (success rate, duration, findings count)
- Platform adapter health dashboard
- Alert on Leadsie webhook failures

### Task 6: Documentation
- API documentation (OpenAPI spec)
- Adapter development guide (how to add a new platform)
- Engine development guide (how to add new audit checks)
- Deployment guide (Docker + environment setup)

### Task 7: Docker + CI
- Dockerfile for the Fastify server
- Docker Compose with all dependencies
- GitHub Actions: lint, test, build, deploy
- Environment-specific configs (dev, staging, prod)

## Success Criteria
- [ ] E2E tests pass for 1, 3, and 11 platform scenarios
- [ ] Load test handles 50 concurrent audits without degradation
- [ ] All tokens encrypted at rest
- [ ] No message body data stored for Gmail/Slack
- [ ] Error recovery works for partial failures
- [ ] API docs generated and accurate
- [ ] Docker builds and runs successfully
- [ ] CI pipeline green

## Completion
```bash
git add -A && git commit -m "Phase 7: Integration testing, security hardening, CI/CD"
```
