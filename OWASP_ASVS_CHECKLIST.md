# OWASP ASVS Security Checklist

## 1. Authentication
- [ ] Verify passwords are hashed with bcrypt/argon2 (checked: uses bcrypt).
- [ ] Enforce password complexity (min length, mixed case).
- [ ] Implement rate limiting on login endpoints (checked: `authRateLimit`).
- [ ] Use secure session management (JWT with short expiry + refresh tokens).
- [ ] Ensure proper logout invalidated sessions/tokens.

## 2. Access Control
- [ ] Verify all sensitive endpoints are protected by `authenticate` middleware.
- [ ] Verify role-based access control (RBAC) works (Student vs Instructor vs Admin).
- [ ] Test Horizontal Privilege Escalation (Student A cannot edit Student B).

## 3. Input Validation
- [ ] Validate all inputs against schemas (Zod).
- [ ] Sanitize inputs to prevent XSS/SQLi (Prisma handles SQLi, helmet for headers).
- [ ] Validate file uploads (MIME type, size limits).

## 4. Data Protection
- [ ] Encrypt sensitive data in transit (HTTPS/TLS - handled by reverse proxy).
- [ ] Do not expose sensitive data in API responses (password hashes, PII).
- [ ] Implement proper error handling (no stack traces in production).

## 5. Logging & Monitoring
- [ ] Ensure logs do not contain sensitive data.
- [ ] Log security events (login failures, permission denied).
- [ ] Centralize logs for monitoring.
