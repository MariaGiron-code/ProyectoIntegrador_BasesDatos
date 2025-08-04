-- =============================
-- ÍNDICES
-- =============================
-- Índice simple
CREATE INDEX IF NOT EXISTS idx_product_name ON products(product_name);
-- ====
-- USO
-- ===
SELECT * FROM products
WHERE product_name ILIKE '%Cámara%';

-- O:
SELECT * FROM products
ORDER BY product_name;

-- Índice compuesto en comentarios
CREATE INDEX IF NOT EXISTS idx_comment_product_profile
ON comment_users(product_id, profile_id);
-- ====
-- USO
-- ===
-- Búsqueda por producto:
SELECT * FROM comment_users
WHERE product_id = 10;

-- Búsqueda combinada:
SELECT * FROM comment_users
WHERE product_id = 1000 AND profile_id = 1;

-- Índice compuesto en ofertas
select*from offers;
CREATE INDEX IF NOT EXISTS idx_offer_product_dates
ON offers(product_id, valid_from, valid_until);
-- ====
-- USO
-- ===
SELECT * FROM offers
WHERE product_id = 50 AND valid_from >= CURRENT_DATE;

