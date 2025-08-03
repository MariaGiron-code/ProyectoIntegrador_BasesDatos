-- SCHEMA: config

-- DROP SCHEMA IF EXISTS config ;

CREATE SCHEMA IF NOT EXISTS config
    AUTHORIZATION neondb_owner;

COMMENT ON SCHEMA config
    IS 'Configuraciones básicas del sistema';

-- Definición de roles y privilegios (admin_db, auditor_db, operador_db, usuario_final).
-- Rol Administrador
-- 1. Crear el rol administrador 
CREATE ROLE admin_db WITH LOGIN
PASSWORD 'EPNprende@Admin20251';

-- 2. Asignar privilegios al esquema config 
GRANT ALL PRIVILEGES ON SCHEMA config TO admin_db;

-- Asignar todos los privilegios en la base
GRANT ALL PRIVILEGES ON DATABASE "EPNprendeDB" TO admin_db;


-- Rol de Auditor
CREATE ROLE auditor_db WITH LOGIN 
  PASSWORD 'EPNprende@Auditor2025*';

-- Dar acceso al esquema auditoria
GRANT USAGE ON SCHEMA auditoria TO auditor_db;

-- Permitir solo SELECT en las tablas
GRANT SELECT ON ALL TABLES IN SCHEMA public TO auditor_db;

-- Permitir ejecución de funciones de auditoría
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO auditor_db;


-- Rol Operador
CREATE ROLE operador_db WITH LOGIN 
  PASSWORD 'EPNprendeOperador@EPN2025%';
-- Dar acceso al esquema operaciones
GRANT USAGE ON SCHEMA operaciones TO operador_db;

-- Dar privilegios básicos CRUD (sin DELETE)
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA operaciones TO operador_db;

-- Permitir uso de secuencias (para IDs autoincrementales)
GRANT USAGE ON ALL SEQUENCES IN SCHEMA operaciones TO operador_db;


-- Rol usuario final
CREATE ROLE usuario_final WITH LOGIN
  PASSWORD 'EPNprende@Usuario2025#';
-- Conceder acceso de solo lectura a tablas específicas
GRANT SELECT ON TABLE public.products TO usuario_final;
GRANT SELECT ON TABLE public.categories TO usuario_final;
-- Restringir conexiones simultáneas dentro del sistema de la base
ALTER ROLE usuario_final CONNECTION LIMIT 10;

-- Configurar ruta de búsqueda
ALTER ROLE usuario_final SET search_path TO publico, public;

-- Denegar acceso a otros esquemas
REVOKE ALL ON SCHEMA auditoria, config, operaciones FROM usuario_final;

SELECT rolname FROM pg_roles;
