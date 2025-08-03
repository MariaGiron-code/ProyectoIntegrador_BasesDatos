-- SCHEMA: auditoria

-- DROP SCHEMA IF EXISTS auditoria ;

CREATE SCHEMA IF NOT EXISTS auditoria
    AUTHORIZATION neondb_owner;

GRANT USAGE ON SCHEMA auditoria TO admin_db;

GRANT USAGE ON SCHEMA auditoria TO auditor_db;

GRANT ALL ON SCHEMA auditoria TO neondb_owner;

-- Simulación de roles (Oficial de Seguridad) 
-- Auditoría de roles:
SELECT grantee, privilege_type, table_name 
FROM information_schema.role_table_grants;

-- Creamos tabla para lleva el regditro de la actividad realizada
CREATE TABLE IF NOT EXISTS auditoria.cambios_credenciales (
    id SERIAL PRIMARY KEY,
    rol TEXT NOT NULL,
    tipo_cambio TEXT NOT NULL CHECK (tipo_cambio IN ('ROTACION_CONTRASEÑA', 'CAMBIO_PERMISOS', 'CREACION_ROL')),
    ejecutado_por TEXT NOT NULL,
    fecha_cambio TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    detalles TEXT,
    ip_origen INET
);
-- Asignar permisos (solo para roles autorizados)
GRANT INSERT, SELECT ON auditoria.cambios_credenciales TO admin_db;
GRANT SELECT ON auditoria.cambios_credenciales TO auditor_db;

-- Rotación de Credenciales de los roles de usuario
ALTER ROLE operador_db WITH PASSWORD 'EPNprendeAuditor@@2025';

-- Revocar conexiones activas dentro de sistemas por los usarios permitidos
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE usename = 'operador_db';

-- Registro de la auditoria
INSERT INTO auditoria.cambios_credenciales 
(rol, tipo_cambio, ejecutado_por) 
VALUES ('operador_db', 'ROTACION_CONTRASEÑA', 'admin_seguridad');

-- Verificar el registro de la actividad
-- Consultar los últimos cambios
SELECT * FROM auditoria.cambios_credenciales
ORDER BY fecha_cambio DESC
LIMIT 5;

-- Usuario Final con acceso controlado
-- Vistas permitidas:
CREATE VIEW view_product AS
SELECT product_name, product_description, product_price FROM products
WHERE product_stock = 'available';

GRANT SELECT ON view_product TO usuario_final;

-- Consulta típica en el sistema
SELECT * FROM view_product; 



