-- ============================================
-- Test INSERTs para validación de replicación
-- ============================================

-- ====================
-- PRUEBA DESDE POSTGRESQL (AMÉRICA)
-- ====================

-- Insertar producto en PostgreSQL
-- Debería replicarse a MySQL
INSERT INTO products (product_id, product_name, category, base_price, description, is_active, created_at, updated_at)
VALUES ('PROD-TEST-001', 'Test Product INSERT', 'Testing', 99.99, 'Producto de prueba INSERT', true, NOW(), NOW());

-- Insertar cliente en PostgreSQL
-- Debería replicarse a MySQL
INSERT INTO customers (customer_id, first_name, last_name, email, country, tier, created_at, updated_at)
VALUES ('CUST-TEST-001', 'Test', 'Customer', 'test@test.com', 'USA', 'Standard', NOW(), NOW());

-- Insertar inventario en PostgreSQL
-- Debería replicarse a MySQL
INSERT INTO inventory (inventory_id, product_id, warehouse_location, quantity_available, quantity_reserved, reorder_point, last_restock_date)
VALUES ('INV-TEST-001', 'PROD-TEST-001', 'WAREHOUSE-A', 100, 0, 10, NOW());

-- Insertar precio regional en PostgreSQL
-- Debería replicarse a MySQL
INSERT INTO regional_pricing (pricing_id, product_id, region_code, local_price, currency, tax_rate, effective_date)
VALUES ('PRICE-TEST-001', 'PROD-TEST-001', 'US', 99.99, 'USD', 0.08, NOW());

-- ====================
-- VERIFICACIÓN EN POSTGRESQL
-- ====================
SELECT 'PostgreSQL - Products' as tabla, product_id, product_name FROM products WHERE product_id LIKE 'PROD-TEST%';
SELECT 'PostgreSQL - Customers' as tabla, customer_id, first_name, last_name FROM customers WHERE customer_id LIKE 'CUST-TEST%';
SELECT 'PostgreSQL - Inventory' as tabla, inventory_id, quantity_available FROM inventory WHERE inventory_id LIKE 'INV-TEST%';
SELECT 'PostgreSQL - Regional Pricing' as tabla, pricing_id, local_price FROM regional_pricing WHERE pricing_id LIKE 'PRICE-TEST%';

-- ====================
-- NOTAS
-- ====================
-- Después de ejecutar estos INSERTs en PostgreSQL, esperar 10-15 segundos
-- y verificar que los datos aparecen en MySQL:
-- docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -e "SELECT * FROM products WHERE product_id LIKE 'PROD-TEST%';"

-- Para ejecutar este script:
-- docker exec -i postgres-america psql -U symmetricds -d globalshop < validation/test-inserts.sql
