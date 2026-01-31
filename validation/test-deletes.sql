-- ============================================
-- Test DELETEs para validación de replicación
-- ============================================

-- ====================
-- PRUEBA DESDE POSTGRESQL (AMÉRICA) -> MYSQL (EUROPA)
-- ====================

-- IMPORTANTE: Eliminar en orden correcto por dependencias de FK

-- Primero eliminar registros dependientes
DELETE FROM regional_pricing WHERE pricing_id = 'PRICE-TEST-001';

-- Luego eliminar inventario
DELETE FROM inventory WHERE inventory_id = 'INV-TEST-001';

-- Eliminar cliente
DELETE FROM customers WHERE customer_id = 'CUST-TEST-001';

-- Finalmente eliminar producto
DELETE FROM products WHERE product_id = 'PROD-TEST-001';

-- ====================
-- VERIFICACIÓN EN POSTGRESQL (deberían estar vacíos)
-- ====================
SELECT 'PostgreSQL - Products después DELETE' as test, COUNT(*) as count FROM products WHERE product_id LIKE 'PROD-TEST%';
SELECT 'PostgreSQL - Customers después DELETE' as test, COUNT(*) as count FROM customers WHERE customer_id LIKE 'CUST-TEST%';
SELECT 'PostgreSQL - Inventory después DELETE' as test, COUNT(*) as count FROM inventory WHERE inventory_id LIKE 'INV-TEST%';
SELECT 'PostgreSQL - Regional Pricing después DELETE' as test, COUNT(*) as count FROM regional_pricing WHERE pricing_id LIKE 'PRICE-TEST%';

-- ====================
-- NOTAS
-- ====================
-- Después de ejecutar estos DELETEs, esperar 10-15 segundos
-- y verificar que los registros también fueron eliminados en MySQL:
-- docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -e "SELECT COUNT(*) as products_count FROM products WHERE product_id LIKE 'PROD-TEST%';"
-- docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -e "SELECT COUNT(*) as customers_count FROM customers WHERE customer_id LIKE 'CUST-TEST%';"

-- Para ejecutar este script:
-- docker exec -i postgres-america psql -U symmetricds -d globalshop < validation/test-deletes.sql

-- ====================
-- LIMPIEZA COMPLETA DE DATOS DE PRUEBA
-- ====================
-- Si hay datos de prueba residuales, ejecutar:
-- DELETE FROM regional_pricing WHERE pricing_id LIKE 'PRICE-TEST%';
-- DELETE FROM inventory WHERE inventory_id LIKE 'INV-TEST%';
-- DELETE FROM customers WHERE customer_id LIKE 'CUST-TEST%';
-- DELETE FROM products WHERE product_id LIKE 'PROD-TEST%';
