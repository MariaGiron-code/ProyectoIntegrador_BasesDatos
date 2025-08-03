-- SCHEMA: auditoria

-- DROP SCHEMA IF EXISTS auditoria ;

CREATE SCHEMA IF NOT EXISTS auditoria
    AUTHORIZATION neondb_owner;

GRANT USAGE ON SCHEMA auditoria TO admin_db;

GRANT USAGE ON SCHEMA auditoria TO auditor_db;

GRANT ALL ON SCHEMA auditoria TO neondb_owner;


-- Monitoreo de del rendimeinto y recursos de la base de datos
-- Tamaño total de la base de datos
SELECT pg_size_pretty(pg_database_size('EPNprendeDB')) AS tamaño_total;

-- Tamaño por tabla (incluyendo índices y otras transacciones en el sistema)
SELECT
    table_name,
    pg_size_pretty(pg_total_relation_size(quote_ident(table_name))) AS tamanio
FROM information_schema.tables
WHERE table_schema = 'public'


-- Crear tabla histórica
CREATE TABLE auditoria.crecimiento_semanal (
    tabla TEXT,
    registros BIGINT,
    fecha DATE DEFAULT CURRENT_DATE
);

-- Programar tarea semanal con pgAgent en las tablas claves del sistema
INSERT INTO auditoria.crecimiento_semanal (tabla, registros)
SELECT 'users', COUNT(*) FROM public.users;

INSERT INTO auditoria.crecimiento_semanal (tabla, registros)
SELECT 'offer_id', COUNT(*) FROM public.offers;

INSERT INTO auditoria.crecimiento_semanal (tabla, registros)
SELECT 'product_name', COUNT(*) FROM public.products;

INSERT INTO auditoria.crecimiento_semanal (tabla, registros)
SELECT 'category_id', COUNT(*) FROM public.categories;

INSERT INTO auditoria.crecimiento_semanal (tabla, registros)
SELECT 'report_id', COUNT(*) FROM public.reports;


-- Vizualizar las tendencias
SELECT tabla, fecha, registros 
FROM auditoria.crecimiento_semanal
ORDER BY fecha DESC;


-- Listar columnas de una vista del sistema para ejecutar funciones esspecificas de postgres
SELECT column_name 
FROM information_schema.columns 
WHERE table_name = 'pg_stat_activity';

-- Registro de Uso de Funciones y Recursos
SELECT usename, calls, total_time
FROM pg_stat_user_functions
ORDER BY total_time DESC;

-- Uso del recuso de CPU/memoria del sistema
-- Primero instalar la extensión (como superusuario)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Consulta
SELECT 
    query,
    calls,
    total_exec_time AS total_cpu_ms,
    mean_exec_time AS avg_cpu_ms,
    rows,
    100.0 * shared_blks_hit / NULLIF(shared_blks_hit + shared_blks_read, 0) AS cache_hit_ratio
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;

-- Recursos especificos
SELECT 
    pid,
    usename AS username,
    datname AS database,
    query,
    query_start,
    now() - query_start AS duration,
    state,
    wait_event_type,
    wait_event
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY duration DESC;

-- Estadísticas de las funciones ejecutadas.
SELECT 
    p.oid AS funcid,
    n.nspname AS schemaname,
    p.proname AS funcname,
    pg_stat_get_function_calls(p.oid) AS calls,
    pg_stat_get_function_total_time(p.oid) AS total_time_ms
FROM pg_proc p
LEFT JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY total_time_ms DESC;



