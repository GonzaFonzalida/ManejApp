# Prisma migrate deploy (PostgreSQL / Neon)

## Estado actual

- Provider: **postgresql** (`migration_lock.toml`).
- Baseline: `20260530180000_postgresql_baseline` (schema completo actual).
- Historial SQLite archivado en `prisma/migrations_legacy/`.

## Neon / producción (schema YA existe)

**No ejecutar** `migrate deploy` a ciegas si la base ya tiene tablas: el baseline intentaría crearlas de nuevo.

Marcar el baseline como aplicado (solo metadatos, sin SQL):

```bash
cd ManejApp
export DATABASE_URL="postgresql://..."   # Neon

npx prisma generate
npx prisma migrate resolve --applied 20260530180000_postgresql_baseline
npx prisma migrate status
npx prisma migrate deploy
```

Esperado: `Database schema is up to date!`

## Base PostgreSQL vacía (staging nuevo)

```bash
npx prisma generate
npx prisma migrate deploy
```

Aplica el baseline y crea todo el schema.

## Render (post-deploy)

Incluir en el pipeline **solo después** de `migrate resolve` en Neon:

```bash
npx prisma generate && npx prisma migrate deploy
```

No usar `db push` en producción salvo emergencia documentada.
