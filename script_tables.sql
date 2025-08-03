-- SCHEMA: public

-- DROP SCHEMA IF EXISTS public ;

CREATE SCHEMA IF NOT EXISTS public
    AUTHORIZATION pg_database_owner;

COMMENT ON SCHEMA public
    IS 'standard public schema';

GRANT USAGE ON SCHEMA public TO PUBLIC;

GRANT ALL ON SCHEMA public TO pg_database_owner;

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public
GRANT ALL ON TABLES TO neon_superuser WITH GRANT OPTION;

ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public
GRANT ALL ON SEQUENCES TO neon_superuser WITH GRANT OPTION;


CREATE TYPE products_stock
AS ENUM ('available', 'unavailable');

CREATE TABLE categories(
    category_id  SMALLSERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    category_description TEXT
);
CREATE TYPE users_rol
AS ENUM ('admin', 'user');

CREATE TABLE users(
    user_id       SMALLSERIAL PRIMARY KEY,
    user_firebase VARCHAR(128) NOT NULL UNIQUE,
    user_rol      USERS_ROL    NOT NULL DEFAULT 'user'
);

CREATE TABLE profiles(
    profile_id SMALLSERIAL PRIMARY KEY,
    profile_name VARCHAR(255) NOT NULL,
    profile_description TEXT NOT NULL,
    user_id INT NOT NULL,
    CONSTRAINT fk_user_id FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE
);

CREATE TYPE products_stock
AS ENUM ('available', 'unavailable');

CREATE TABLE products(
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    product_description TEXT NOT NULL,
    product_price NUMERIC(10, 2) NOT NULL,
    product_stock PRODUCTS_STOCK NOT NULL DEFAULT 'available',
    product_publication_date TIMESTAMP NOT NULL DEFAULT NOW(),
    profile_id INT NOT NULL,
	
    CONSTRAINT fk_profile_id FOREIGN KEY (profile_id)
    REFERENCES profiles (profile_id) ON DELETE CASCADE,
    category_id INT NOT NULL,
    
	CONSTRAINT fk_category_id FOREIGN KEY (category_id)
    REFERENCES categories (category_id) ON DELETE CASCADE
);

-- sirve para habilitar la extensión citext (case-insensitive text). 
-- Esto permite que las columnas de tipo citext se comporten como TEXT pero sin distinguir mayúsculas y minúsculasen comparaciones.
CREATE EXTENSION IF NOT EXISTS citext;

CREATE TABLE click_statistics(
    product_id INT PRIMARY KEY,
    CONSTRAINT fk_product_id
    FOREIGN KEY (product_id) REFERENCES products (product_id) ON DELETE CASCADE,
    click_counter INT NOT NULL DEFAULT 0 
	CONSTRAINT chk_click_counter
    CHECK (click_counter >= 0)
);

CREATE TABLE comment_users(
    comment_id SERIAL PRIMARY KEY,
    comment_text TEXT NOT NULL,
    comment_date TIMESTAMP NOT NULL DEFAULT NOW(),
    comment_update TIMESTAMP NOT NULL DEFAULT NOW(),
    comment_rate SMALLINT CHECK ( comment_rate BETWEEN 1 AND 5),
    profile_id INT NOT NULL,
    
	CONSTRAINT fk_profile FOREIGN KEY (profile_id)
    REFERENCES profiles (profile_id) ON DELETE CASCADE,

    product_id     INT       NOT NULL,
    CONSTRAINT fk_product FOREIGN KEY (product_id)
    REFERENCES products (product_id) ON DELETE CASCADE
);

CREATE TABLE favorites(
    favorite_id SERIAL PRIMARY KEY,
    profile_id  INT NOT NULL,
    CONSTRAINT fk_profile FOREIGN KEY (profile_id)
    REFERENCES profiles (profile_id) ON DELETE CASCADE,
    product_id  INT NOT NULL,
    
	CONSTRAINT fk_product FOREIGN KEY (product_id)
    REFERENCES products (product_id) ON DELETE CASCADE
);

CREATE TABLE offers(
    offer_id SERIAL PRIMARY KEY,
    old_price NUMERIC(10, 2) NOT NULL,
    new_price NUMERIC(10, 2) NOT NULL,
    valid_from TIMESTAMP NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMP NOT NULL,
    offer_description TEXT,
    product_id INT NOT NULL,
    CONSTRAINT fk_product FOREIGN KEY (product_id)
    REFERENCES products (product_id) ON DELETE CASCADE,

    CONSTRAINT chk_offer_dates CHECK (valid_until > valid_from)
);

CREATE TABLE reports(
    report_id SERIAL PRIMARY KEY,
    report_date TIMESTAMP NOT NULL DEFAULT NOW(),
    report_description TEXT NOT NULL,
    reporting_profile  INT NOT NULL,
    CONSTRAINT fk_reporting_profile FOREIGN KEY (reporting_profile)
    REFERENCES profiles (profile_id) ON DELETE CASCADE,
    reported_profile   INT NULL,
    
	CONSTRAINT fk_reported_profile FOREIGN KEY (reported_profile)
    REFERENCES profiles (profile_id) ON DELETE CASCADE,
    reported_product   INT       NULL,
    
	CONSTRAINT fk_reported_product FOREIGN KEY (reported_product)
    REFERENCES products (product_id) ON DELETE CASCADE,

    CONSTRAINT chk_one_target
        CHECK ((reported_profile IS NOT NULL AND reported_product IS NULL)
                OR (reported_profile IS NULL AND reported_product IS NOT NULL))
);

CREATE TABLE profile_photos(
    photo_id SERIAL PRIMARY KEY,
    photo_url VARCHAR(255) NOT NULL,
    photo_update TIMESTAMP NOT NULL DEFAULT NOW(),
    profile_id INT NOT NULL,
    CONSTRAINT fk_profile_photo FOREIGN KEY (profile_id)
    REFERENCES profiles (profile_id) ON DELETE CASCADE
);

CREATE TABLE product_photos(
    photo_id SERIAL PRIMARY KEY,
    photo_url VARCHAR(255) NOT NULL,
    photo_update TIMESTAMP NOT NULL DEFAULT NOW(),
    product_id INT NOT NULL,
    CONSTRAINT fk_product_photo FOREIGN KEY (product_id)
    REFERENCES products (product_id) ON DELETE CASCADE
);