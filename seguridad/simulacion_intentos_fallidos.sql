-- SCHEMA: auditoria

-- DROP SCHEMA IF EXISTS auditoria ;

CREATE SCHEMA IF NOT EXISTS auditoria
    AUTHORIZATION neondb_owner;

GRANT USAGE ON SCHEMA auditoria TO admin_db;

GRANT USAGE ON SCHEMA auditoria TO auditor_db;

GRANT ALL ON SCHEMA auditoria TO neondb_owner;

-- Registro de intentos fallidos o sospechosos (simulado).
-- Crear tabla para registrar intentos fallidos
CREATE TABLE auditoria.intentos_fallidos (
    id SERIAL PRIMARY KEY,
    usuario TEXT,               -- Usuario que intentó acceder
    ip INET,                    -- Dirección IP del intento
    fecha TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    accion TEXT,                --  'LOGIN_FAILED', 'SQL_INJECTION_ATTEMPT'
    detalles TEXT               -- Detalles del error o payload sospechoso
);

GRANT INSERT ON auditoria.intentos_fallidos TO admin_db;
GRANT SELECT ON auditoria.intentos_fallidos TO auditor_db;

-- Simular intentos fallidos
-- Intento de login fallido
INSERT INTO auditoria.intentos_fallidos (usuario, ip, accion, detalles)
VALUES ('usuario_inexistente', '192.168.1.100', 'LOGIN_FAILED', 'Credenciales incorrectas');

-- Intento de SQL Injection
INSERT INTO auditoria.intentos_fallidos (usuario, ip, accion, detalles)
VALUES ('hacker', '10.0.0.5', 'SQL_INJECTION_ATTEMPT', 'Payload: " OR ''1''=''1');


-- Registro de intentos fallidos o sospechosos (simulado).
-- Ver todos los registros
SELECT * FROM auditoria.intentos_fallidos
ORDER BY fecha DESC;

-- Filtrar por tipo de acción (ej: intentos de SQL Injection)
SELECT * FROM auditoria.intentos_fallidos
WHERE accion = 'SQL_INJECTION_ATTEMPT';


