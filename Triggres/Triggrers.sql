-- =============================
-- TRIGGERS
-- =============================

-- Auditoría de cambios de precio en productos
CREATE TABLE IF NOT EXISTS audit_products (
    audit_id SERIAL PRIMARY KEY,
    product_id INTEGER,
    old_price NUMERIC(10,2),
    new_price NUMERIC(10,2),
    changed_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION audit_product_changes() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.product_price <> NEW.product_price THEN
        INSERT INTO audit_products(product_id, old_price, new_price)
        VALUES (OLD.product_id, OLD.product_price, NEW.product_price);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_product_price ON products;
CREATE TRIGGER trg_audit_product_price
AFTER UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION audit_product_changes();

-- ===== 
-- USO 
-- =====
SELECT*FROM products;
INSERT INTO products (product_id,product_name,product_description,product_price,product_stock,product_publication_date,profile_id,category_id)
VALUES (1000,'Cámara HD','Cámara de alta definición para fotografía profesional',100.00,'available','2025-08-04',1,3);

UPDATE products
SET product_price = 120.00
WHERE product_id = 1000;

SELECT * FROM audit_products;

-- ===== 
-- Control de stock
CREATE OR REPLACE FUNCTION check_product_stock() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.product_stock != 'available' THEN
        RAISE EXCEPTION 'Stock insuficiente';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trg_check_stock ON products;
CREATE TRIGGER trg_check_stock
BEFORE INSERT OR UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION check_product_stock();

-- ===== 
-- USO 
-- =====
INSERT INTO products (product_id,product_name,product_description,product_price,product_stock,product_publication_date,profile_id,category_id)
VALUES (1001,'PS5 SLIM','Consola que acepta juegos digital y fisicos',500.00,'unavailable','2025-08-04',35,36);


-- Notificaciones por nuevos comentarios
CREATE TABLE IF NOT EXISTS notification_log (
    notification_id SERIAL PRIMARY KEY,
    profile_id INTEGER,
    product_id INTEGER,
    message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION notify_comment_insert() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notification_log(profile_id, product_id, message)
    VALUES (
        NEW.profile_id, NEW.product_id,
        'Nuevo comentario registrado en un producto que sigues.'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_notify_comment ON comment_users;
CREATE TRIGGER trg_notify_comment
AFTER INSERT ON comment_users
FOR EACH ROW
EXECUTE FUNCTION notify_comment_insert();
-- ===== 
-- USO 
-- ====
SELECT * FROM comment_users;
INSERT INTO comment_users (comment_text,comment_date,comment_update,comment_rate,profile_id,product_id)
VALUES ('¡Me encanta este producto!',NOW(),NOW(),5,1,1000 );

SELECT * FROM notification_log ORDER BY created_at DESC;
