-- Activa el temporizador para medir el tiempo de ejecución
\timing on;

-- Ejecuta la consulta con análisis de ejecución
EXPLAIN ANALYZE
select*from users;
EXPLAIN ANALYZE
select*from products;
EXPLAIN ANALYZE
select*from profiles;
EXPLAIN ANALYZE
select*from categories;
EXPLAIN ANALYZE
select*from comment_users;
EXPLAIN ANALYZE
select*from offers;



