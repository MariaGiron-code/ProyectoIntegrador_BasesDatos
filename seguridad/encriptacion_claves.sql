-- SCHEMA: operaciones

-- DROP SCHEMA IF EXISTS operaciones ;

CREATE SCHEMA IF NOT EXISTS operaciones
    AUTHORIZATION neondb_owner;

GRANT ALL ON SCHEMA operaciones TO neondb_owner;

GRANT USAGE ON SCHEMA operaciones TO operador_db;

-- Cifrado de IDs de Firebase en la Tabla users
-- Activar pgcrypto 
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Asegurar permisos sobre el esquema de auditoria
GRANT USAGE ON SCHEMA auditoria TO admin_db;
REVOKE ALL ON SCHEMA auditoria FROM PUBLIC;

-- Modificar la tabla users para gardar las contraseñas cifradas y eliminar las visibles en los campos de la tabla
-- Añadir columna para el ID de firebase cifrado 
ALTER TABLE users ADD COLUMN user_firebase_cifrado BYTEA;

-- Añadir columna para el vector de inicialización (IV)
ALTER TABLE users ADD COLUMN user_firebase_iv BYTEA;

-- Función de cifrado (en esquema auditoria)
CREATE OR REPLACE FUNCTION auditoria.cifrar_firebase_id(id TEXT, clave TEXT) 
RETURNS BYTEA AS $$
BEGIN
    RETURN pgp_sym_encrypt(id, clave);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Ejecutar como admin_db la encriptación
UPDATE users 
SET user_firebase_cifrado = auditoria.cifrar_firebase_id(user_firebase, 'tu_clave_secreta_AES');
select*from users;

--  Backup de IDs Originales
-- Crear tabla de backup en el esquema de auditoria
CREATE TABLE auditoria.backup_firebase_ids AS
SELECT 
    user_id, 
    user_firebase AS firebase_id_original,
    CURRENT_TIMESTAMP AS backup_date
FROM users;

-- Verificar el backup
SELECT * FROM auditoria.backup_firebase_ids;

-- Eliminación de la clumna original e los IDs para que no sean visibles
-- 1. Deshabilitar dependencias (si hay claves foráneas)
ALTER TABLE users DROP CONSTRAINT users_user_firebase_key;

-- 2. Eliminar columna
ALTER TABLE users DROP COLUMN user_firebase;

-- 3. Renombrar columna cifrada (opcional)
ALTER TABLE users RENAME COLUMN user_firebase_cifrado TO user_firebase;

-- Columna del IV (Initialization Vector) se elimin ya que no se esta usando cifrado maunual si no automático
-- 1. Verificar que el IV no se esté usando (confirmar que todos los valores son NULL)
SELECT COUNT(*) FROM users WHERE user_firebase_iv IS NOT NULL;

-- 2. Eliminar la columna (si el conteo anterior fue 0)
ALTER TABLE users DROP COLUMN user_firebase_iv;



