-- ============================================
-- Test UPDATEs para validación de replicación
-- ============================================

-- ====================
-- PRUEBA DESDE POSTGRESQL (AMÉRICA) -> MYSQL (EUROPA)
-- ====================

-- Actualizar producto en PostgreSQL
-- Debería replicarse a MySQL
UPDATE products 
SET base_price = 149.99, 
    description = 'Producto actualizado desde PostgreSQL',
    updated_at = NOW()
WHERE product_id = 'PROD-TEST-001';

-- Actualizar cliente en PostgreSQL
UPDATE customers 
SET tier = 'Premium',
    updated_at = NOW()
WHERE customer_id = 'CUST-TEST-001';

-- Actualizar inventario en PostgreSQL
UPDATE inventory 
SET quantity_available = 75,
    quantity_reserved = 25
WHERE inventory_id = 'INV-TEST-001';

-- Actualizar precio regional en PostgreSQL
UPDATE regional_pricing 
SET local_price = 159.99,
    tax_rate = 0.10
WHERE pricing_id = 'PRICE-TEST-001';

-- ====================
-- VERIFICACIÓN EN POSTGRESQL
-- ====================
SELECT 'PostgreSQL - Products UPDATE' as test, product_id, base_price, description FROM products WHERE product_id = 'PROD-TEST-001';
SELECT 'PostgreSQL - Customers UPDATE' as test, customer_id, tier FROM customers WHERE customer_id = 'CUST-TEST-001';
SELECT 'PostgreSQL - Inventory UPDATE' as test, inventory_id, quantity_available, quantity_reserved FROM inventory WHERE inventory_id = 'INV-TEST-001';
SELECT 'PostgreSQL - Regional Pricing UPDATE' as test, pricing_id, local_price, tax_rate FROM regional_pricing WHERE pricing_id = 'PRICE-TEST-001';

-- ====================
-- NOTAS
-- ====================
-- Después de ejecutar estos UPDATEs, esperar 10-15 segundos
-- y verificar que los cambios aparecen en MySQL:
-- docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -e "SELECT product_id, base_price, description FROM products WHERE product_id = 'PROD-TEST-001';"

-- Para ejecutar este script:
-- docker exec -i postgres-america psql -U symmetricds -d globalshop < validation/test-updates.sql

-- ====================
-- PRUEBA INVERSA: MYSQL (EUROPA) -> POSTGRESQL (AMÉRICA)
-- ====================
-- Ejecutar en MySQL:
-- docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -e "UPDATE products SET base_price = 199.99, description = 'Actualizado desde MySQL' WHERE product_id = 'PROD-TEST-001';"
-- Luego verificar en PostgreSQL:
-- docker exec postgres-america psql -U symmetricds -d globalshop -c "SELECT product_id, base_price, description FROM products WHERE product_id = 'PROD-TEST-001';"
