# Migraciones legacy (SQLite)

Estas carpetas son el historial **original** generado cuando el proyecto usaba SQLite
(`migration_lock.toml` tenía `provider = "sqlite"`).

## Por qué se archivaron (Fase 3.1)

- `schema.prisma` usa **PostgreSQL** (Neon en producción).
- Las migraciones `202603*` contienen SQL SQLite (`AUTOINCREMENT`, etc.) incompatible con `migrate deploy` en Postgres.
- Neon ya tenía el schema aplicado vía `db push` (sin tabla `_prisma_migrations`).

## Reemplazo

El historial activo vive en `prisma/migrations/20260530180000_postgresql_baseline/`,
generado con:

```bash
npx prisma migrate diff --from-empty --to-schema-datamodel prisma/schema.prisma --script
```

## No borrar

Se conservan aquí por trazabilidad. **No mover de vuelta** a `prisma/migrations/` sin revisión.
