/**
 * QA: Verificación de endpoints usados por RoleRouter y ApiService (Flutter).
 * Uso: QA_EMAIL=... QA_PASSWORD=... [BASE_URL=http://localhost:3099] node scripts/qa-verify-endpoints.js
 * Evidencia: imprime status + body resumido por endpoint; fallos indican fix en backend o ApiService.
 */

const BASE_URL = process.env.BASE_URL || 'http://localhost:3099';
const API = `${BASE_URL}/api/v1`;
const QA_EMAIL = process.env.QA_EMAIL || 'fig@gmail.com';
const QA_PASSWORD = process.env.QA_PASSWORD || '02320648767Si.';

const log = (label, status, bodySummary) => {
  const summary = typeof bodySummary === 'string' ? bodySummary : JSON.stringify(bodySummary ?? '').slice(0, 200);
  console.log(`[${label}] status=${status} body=${summary}`);
};

const run = async () => {
  console.log('--- QA Endpoint verification ---');
  console.log(`BASE_URL=${BASE_URL} API=${API} QA_EMAIL=${QA_EMAIL}`);
  let accessToken = null;
  let userId = null;

  // 1) POST /api/v1/auth/login
  try {
    const res = await fetch(`${API}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: QA_EMAIL, password: QA_PASSWORD }),
    });
    const body = await res.json().catch(() => ({}));
    log('POST /auth/login', res.status, body);
    if (res.status === 200) {
      accessToken = body.accessToken ?? body.token;
      const user = body.user ?? body.data?.user;
      userId = user?.id ?? body.userId ?? body.data?.userId;
      if (!userId && accessToken && typeof accessToken === 'string' && accessToken.includes('.')) {
        try {
          const payload = JSON.parse(Buffer.from(accessToken.split('.')[1], 'base64url').toString());
          userId = payload.id ?? payload.userId ?? payload.sub;
        } catch (_) {}
      }
    }
  } catch (e) {
    log('POST /auth/login', 'ERR', e.message);
  }

  if (!accessToken || !userId) {
    console.log('--- No token/userId; skipping authenticated endpoints. ---');
    return;
  }

  const headers = { Authorization: `Bearer ${accessToken}` };

  // 2) GET /api/v1/auth/me
  try {
    const res = await fetch(`${API}/auth/me`, { headers });
    const body = await res.json().catch(() => ({}));
    log('GET /auth/me', res.status, body);
  } catch (e) {
    log('GET /auth/me', 'ERR', e.message);
  }

  // 3) GET /api/v1/users/:id (role real desde DB)
  try {
    const res = await fetch(`${API}/users/${userId}`, { headers });
    const body = await res.json().catch(() => ({}));
    log('GET /users/:id', res.status, body);
  } catch (e) {
    log('GET /users/:id', 'ERR', e.message);
  }

  // 4) GET /api/v1/instructors/me (200 ok instructor, 403 student)
  try {
    const res = await fetch(`${API}/instructors/me`, { headers });
    const body = await res.json().catch(() => ({}));
    log('GET /instructors/me', res.status, body);
  } catch (e) {
    log('GET /instructors/me', 'ERR', e.message);
  }

  // 5) PUT /api/v1/instructors/me (solo si es instructor; opcional para no modificar datos)
  try {
    const res = await fetch(`${API}/instructors/me`, {
      method: 'PUT',
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({}), // empty update to only verify endpoint exists
    });
    const body = await res.json().catch(() => ({}));
    log('PUT /instructors/me', res.status, res.status === 200 ? 'OK' : body);
  } catch (e) {
    log('PUT /instructors/me', 'ERR', e.message);
  }

  console.log('--- End ---');
};

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
