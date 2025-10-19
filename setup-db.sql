-- Conectarse a PostgreSQL como superusuario y ejecutar:

-- Crear usuario para ManejApp
CREATE USER manejapp_user WITH PASSWORD 'manejapp123';

-- Crear base de datos
CREATE DATABASE manejapp OWNER manejapp_user;

-- Otorgar permisos
GRANT ALL PRIVILEGES ON DATABASE manejapp TO manejapp_user;
GRANT ALL ON SCHEMA public TO manejapp_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO manejapp_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO manejapp_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO manejapp_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO manejapp_user;