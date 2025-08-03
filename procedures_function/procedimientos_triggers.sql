
-- Creación de los procedimientos almacenados en las tablas más criticas del sistema (users, products, profiles, offers y reports)
-- Tabla de usuarios
CREATE OR REPLACE PROCEDURE insertar_usuario(
    IN p_user_firebase VARCHAR(128),
	OUT p_mensaje_resultado TEXT,
    IN p_user_rol users_rol DEFAULT 'user')
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar que el ID de Firebase no esté vacío
    IF p_user_firebase IS NULL OR p_user_firebase = '' THEN
        p_mensaje_resultado := 'Error: El ID de Firebase no puede estar vacío';
        RETURN;
    END IF;
    
    -- Validar que el rol sea válido
    IF p_user_rol NOT IN ('admin', 'user') THEN
        p_mensaje_resultado := 'Error: Rol de usuario no válido';
        RETURN;
    END IF;
    
    -- Validar que el usuario no exista ya
    IF EXISTS (SELECT 1 FROM users WHERE user_firebase = p_user_firebase) THEN
        p_mensaje_resultado := 'Error: El usuario ya está registrado';
        RETURN;
    END IF;
    
    -- Insertar el nuevo usuario
    INSERT INTO users(user_firebase, user_rol)
    VALUES (p_user_firebase, p_user_rol);
    
    p_mensaje_resultado := 'Usuario registrado correctamente con ID: ' || currval('users_user_id_seq');
END;
$$;

-- Llamada 
CALL insertar_usuario(
    p_user_firebase := 'abc123xyz456', 
    p_user_rol := 'user', 
    p_mensaje_resultado := '');

-- Tabla de productos: Procedimiento para Actualizar Estado de Productos (products)
CREATE OR REPLACE PROCEDURE actualizar_estado_productos(
    IN p_categoria_id INT,
    IN p_nuevo_estado products_stock,
    OUT p_productos_actualizados INT,
    OUT p_mensaje_resultado TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar que la categoría existe
    IF NOT EXISTS (SELECT 1 FROM categories WHERE category_id = p_categoria_id) THEN
        p_mensaje_resultado := 'Error: La categoría especificada no existe';
        RETURN;
    END IF;
    
    -- Actualizar los productos de la categoría
    UPDATE products
    SET product_stock = p_nuevo_estado
    WHERE category_id = p_categoria_id;
    
    -- Obtener el número de filas afectadas
    GET DIAGNOSTICS p_productos_actualizados = ROW_COUNT;
    
    p_mensaje_resultado := 'Actualización completada. Productos modificados: ' || p_productos_actualizados;
END;
$$;

-- Cambiar estado a 'unavailable' para categoría 5
CALL actualizar_estado_productos(
    p_categoria_id := 5, 
    p_nuevo_estado := 'unavailable', 
    p_productos_actualizados := 0, 
    p_mensaje_resultado := ''
);

-- Tabla perfiles: Procedimiento para Eliminar Perfil y sus Dependencias (profiles)
CREATE OR REPLACE PROCEDURE eliminar_perfil_seguro(
    IN p_profile_id INT,
    OUT p_mensaje_resultado TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_productos_eliminados INT;
    v_comentarios_eliminados INT;
BEGIN
    -- Validar que el perfil existe
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE profile_id = p_profile_id) THEN
        p_mensaje_resultado := 'Error: El perfil especificado no existe';
        RETURN;
    END IF;
    
    -- Contar productos que serán eliminados (ON CASCADE)
    SELECT COUNT(*) INTO v_productos_eliminados
    FROM products
    WHERE profile_id = p_profile_id;
    
    -- Contar comentarios que serán eliminados (ON CASCADE)
    SELECT COUNT(*) INTO v_comentarios_eliminados
    FROM comment_users
    WHERE profile_id = p_profile_id;
    
    -- Eliminar el perfil 
    DELETE FROM profiles WHERE profile_id = p_profile_id;
    
    p_mensaje_resultado := 'Perfil eliminado correctamente. ' ||
                          'Productos eliminados: ' || v_productos_eliminados || ', ' ||
                          'Comentarios eliminados: ' || v_comentarios_eliminados;
END;
$$;

-- Llamada
CALL eliminar_perfil_seguro(10, '');


-- Procedimiento para Actualización Masiva de Precios (products + offers)
CREATE OR REPLACE PROCEDURE actualizar_precios_masivo(
    IN p_porcentaje_aumento NUMERIC(5,2),
	OUT p_productos_actualizados INT,
    OUT p_ofertas_actualizadas INT,
    OUT p_mensaje_resultado TEXT,
    IN p_categoria_id INT DEFAULT NULL
    
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Validar porcentaje válido
    IF p_porcentaje_aumento <= 0 THEN
        p_mensaje_resultado := 'Error: El porcentaje de aumento debe ser positivo';
        RETURN;
    END IF;
    
    -- Actualizar productos (según categoría si se especifica)
    IF p_categoria_id IS NULL THEN
        UPDATE products
        SET product_price = product_price * (1 + p_porcentaje_aumento/100);
    ELSE
        UPDATE products
        SET product_price = product_price * (1 + p_porcentaje_aumento/100)
        WHERE category_id = p_categoria_id;
    END IF;
    
    GET DIAGNOSTICS p_productos_actualizados = ROW_COUNT;
    
    -- Actualizar ofertas relacionadas a los productos modificados
    UPDATE offers o
    SET 
        old_price = p.product_price,
        new_price = p.product_price * (1 + p_porcentaje_aumento/100)
    FROM products p
    WHERE o.product_id = p.product_id
    AND (p_categoria_id IS NULL OR p.category_id = p_categoria_id);
    
    GET DIAGNOSTICS p_ofertas_actualizadas = ROW_COUNT;
    
    p_mensaje_resultado := 'Actualización masiva completada. ' ||
                          'Productos actualizados: ' || p_productos_actualizados || ', ' ||
                          'Ofertas ajustadas: ' || p_ofertas_actualizadas;
END;
$$;
-- Aumento del 10% para todos los productos
CALL actualizar_precios_masivo(
    p_porcentaje_aumento := 10,
    p_categoria_id := NULL,
    p_productos_actualizados := 0,
    p_ofertas_actualizadas := 0,
    p_mensaje_resultado := ''
);

-- Procedimiento en reports: Inserta un nuevo reporte en la tabla reports, asegurando que el perfil que lo genera
-- existe y que se reporta al menos un perfil o producto, cumpliendo con las restricciones de integridad definidas.
CREATE OR REPLACE PROCEDURE insertar_reporte(
    IN p_descripcion TEXT,
    IN p_perfil_generador INT,
    IN p_perfil_reportado INT DEFAULT NULL,
    IN p_producto_reportado INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    existe_generador INT;
BEGIN
    -- Verificar si el perfil que genera el reporte existe
    SELECT COUNT(*) INTO existe_generador
    FROM profiles
    WHERE profile_id = p_perfil_generador;

    IF existe_generador = 0 THEN
        RAISE EXCEPTION 'El perfil generador del reporte no existe: %', p_perfil_generador;
    END IF;

    -- Validar que al menos uno de los campos objetivo esté presente
    IF p_perfil_reportado IS NULL AND p_producto_reportado IS NULL THEN
        RAISE EXCEPTION 'Debe especificar un perfil o producto reportado (no ambos vacíos)';
    END IF;

    -- Insertar reporte
    INSERT INTO reports (
        report_description,
        report_date,
        reporting_profile,
        reported_profile,
        reported_product
    ) VALUES (
        p_descripcion,
        NOW(),
        p_perfil_generador,
        p_perfil_reportado,
        p_producto_reportado
    );

    RAISE NOTICE 'Reporte insertado correctamente.';
END;
$$;
CALL insertar_reporte('Comportamiento sospechoso', 1, 3, NULL);
CALL insertar_reporte('Producto con imágenes inapropiadas', 2, NULL, 15);
select*from reports;

-- Función para calcular el descuento promedio de ofertas
CREATE OR REPLACE FUNCTION calcular_descuento_promedio()
RETURNS NUMERIC(5,2) AS $$
DECLARE
    v_descuento_promedio NUMERIC(5,2);
BEGIN
    SELECT AVG(100 - (new_price * 100 / old_price))
    INTO v_descuento_promedio
    FROM offers
    WHERE valid_until > CURRENT_DATE;
    
    RETURN COALESCE(v_descuento_promedio, 0);
END;
$$ LANGUAGE plpgsql;
SELECT calcular_descuento_promedio() AS descuento_promedio;

-- Función para determinar la popularidad de un producto
CREATE OR REPLACE FUNCTION determinar_popularidad(p_product_id INT)
RETURNS VARCHAR(20) AS $$
DECLARE
    v_clicks INT;
    v_promedio_clicks NUMERIC(10,2);
    v_popularidad VARCHAR(20);
BEGIN
    -- Obtener clicks del producto
    SELECT click_counter INTO v_clicks
    FROM click_statistics
    WHERE product_id = p_product_id;
    
    -- Obtener promedio de clicks
    SELECT AVG(click_counter) INTO v_promedio_clicks
    FROM click_statistics;
    
    -- Determinar popularidad
    IF v_clicks > v_promedio_clicks * 2 THEN
        v_popularidad := 'Muy Popular';
    ELSIF v_clicks > v_promedio_clicks THEN
        v_popularidad := 'Popular';
    ELSE
        v_popularidad := 'Normal';
    END IF;
    
    RETURN v_popularidad;
END;
$$ LANGUAGE plpgsql;
SELECT product_name, determinar_popularidad(product_id) AS popularidad
FROM products;

-- Función para validar nueva oferta en la tabla (offers)
CREATE OR REPLACE FUNCTION validar_oferta_basica(
    p_product_id INT
) RETURNS BOOLEAN AS $$
DECLARE
    v_producto_valido BOOLEAN;
    v_oferta_activa BOOLEAN;
BEGIN
    -- Verificar si el producto existe y está disponible
    SELECT EXISTS (
        SELECT 1 FROM products 
        WHERE product_id = p_product_id 
        AND product_stock = 'available'
    ) INTO v_producto_valido;
    
    -- Verificar si ya tiene una oferta activa
    SELECT EXISTS (
        SELECT 1 FROM offers 
        WHERE product_id = p_product_id 
        AND valid_until > CURRENT_DATE
    ) INTO v_oferta_activa;
    
    -- Retornar TRUE solo si el producto es válido y no tiene oferta activa
    RETURN v_producto_valido AND NOT v_oferta_activa;
END;
$$ LANGUAGE plpgsql;
SELECT validar_oferta_basica(5) AS es_oferta_valida;


