-- =============================
-- CONSULTA PREPARADA (SQL Injection Mitigación)
-- =============================
select * from profiles;
-- Consultar por id del usuario 
SELECT * FROM profiles WHERE user_id = 40;
-- Inyeccion 
SELECT * FROM profiles WHERE user_id = 0 OR '1'='1';

-- Consulta segura usando PREPARE y EXECUTE
PREPARE get_profile_by_user_id(INT) AS
    SELECT * FROM profiles WHERE user_id = $1;

-- Ejecutar la consulta con un valor real 
EXECUTE get_profile_by_user_id(40);