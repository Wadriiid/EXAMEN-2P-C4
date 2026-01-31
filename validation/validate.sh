#!/bin/bash
# ============================================
# SymmetricDS Validation Script
# Valida la replicación bidireccional PostgreSQL ↔ MySQL
# ============================================

set -e

echo "============================================"
echo "  SymmetricDS Validation Script"
echo "  Replicación Bidireccional PostgreSQL ↔ MySQL"
echo "============================================"
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

# Función para verificar resultado
check_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASSED${NC}: $2"
        ((PASSED++))
    else
        echo -e "${RED}✗ FAILED${NC}: $2"
        ((FAILED++))
    fi
}

echo "=== FASE 1: Verificando Contenedores ==="
echo ""

# Verificar que los contenedores están corriendo
docker ps | grep -q "postgres-america" && check_result 0 "PostgreSQL América corriendo" || check_result 1 "PostgreSQL América corriendo"
docker ps | grep -q "mysql-europe" && check_result 0 "MySQL Europa corriendo" || check_result 1 "MySQL Europa corriendo"
docker ps | grep -q "symmetricds-america" && check_result 0 "SymmetricDS América corriendo" || check_result 1 "SymmetricDS América corriendo"
docker ps | grep -q "symmetricds-europe" && check_result 0 "SymmetricDS Europa corriendo" || check_result 1 "SymmetricDS Europa corriendo"

echo ""
echo "=== FASE 2: Verificando Conexiones a BD ==="
echo ""

# Verificar conexión a PostgreSQL
docker exec postgres-america psql -U symmetricds -d globalshop -c "SELECT 1" > /dev/null 2>&1 && check_result 0 "Conexión a PostgreSQL" || check_result 1 "Conexión a PostgreSQL"

# Verificar conexión a MySQL
docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -e "SELECT 1" > /dev/null 2>&1 && check_result 0 "Conexión a MySQL" || check_result 1 "Conexión a MySQL"

echo ""
echo "=== FASE 3: Verificando Tablas SymmetricDS ==="
echo ""

# Verificar tablas sym_* en PostgreSQL
PG_SYM_TABLES=$(docker exec postgres-america psql -U symmetricds -d globalshop -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name LIKE 'sym_%'" | tr -d ' ')
[ "$PG_SYM_TABLES" -gt 30 ] && check_result 0 "Tablas sym_* en PostgreSQL ($PG_SYM_TABLES tablas)" || check_result 1 "Tablas sym_* en PostgreSQL ($PG_SYM_TABLES tablas)"

# Verificar tablas sym_* en MySQL
MY_SYM_TABLES=$(docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_name LIKE 'sym_%' AND table_schema='globalshop'" 2>/dev/null | tr -d ' ')
[ "$MY_SYM_TABLES" -gt 30 ] && check_result 0 "Tablas sym_* en MySQL ($MY_SYM_TABLES tablas)" || check_result 1 "Tablas sym_* en MySQL ($MY_SYM_TABLES tablas)"

echo ""
echo "=== FASE 4: Verificando Registro de Nodos ==="
echo ""

# Verificar que Europa está registrado en América
EUROPE_REGISTERED=$(docker exec postgres-america psql -U symmetricds -d globalshop -t -c "SELECT COUNT(*) FROM sym_node WHERE external_id='002'" | tr -d ' ')
[ "$EUROPE_REGISTERED" -eq 1 ] && check_result 0 "Nodo Europa registrado en América" || check_result 1 "Nodo Europa registrado en América"

echo ""
echo "=== FASE 5: Prueba de Replicación INSERT ==="
echo ""

# Generar ID único para la prueba
TEST_ID="TEST-VAL-$(date +%s)"

# INSERT en PostgreSQL -> verificar en MySQL
echo "Insertando producto de prueba en PostgreSQL..."
docker exec postgres-america psql -U symmetricds -d globalshop -c "INSERT INTO products VALUES ('$TEST_ID', 'Validation Product', 'Testing', 123.45, 'Validation test', true, NOW(), NOW())" > /dev/null 2>&1

sleep 10

# Verificar en MySQL
MYSQL_COUNT=$(docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -N -e "SELECT COUNT(*) FROM products WHERE product_id='$TEST_ID'" 2>/dev/null | tr -d ' ')
[ "$MYSQL_COUNT" -eq 1 ] && check_result 0 "Replicación INSERT PostgreSQL → MySQL" || check_result 1 "Replicación INSERT PostgreSQL → MySQL"

# INSERT en MySQL -> verificar en PostgreSQL
TEST_ID2="TEST-VAL2-$(date +%s)"
echo "Insertando producto de prueba en MySQL..."
docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -e "INSERT INTO products (product_id, product_name, category, base_price, description, is_active, created_at, updated_at) VALUES ('$TEST_ID2', 'Validation Product 2', 'Testing', 234.56, 'Validation test 2', 1, NOW(), NOW())" 2>/dev/null

sleep 10

# Verificar en PostgreSQL
PG_COUNT=$(docker exec postgres-america psql -U symmetricds -d globalshop -t -c "SELECT COUNT(*) FROM products WHERE product_id='$TEST_ID2'" | tr -d ' ')
[ "$PG_COUNT" -eq 1 ] && check_result 0 "Replicación INSERT MySQL → PostgreSQL" || check_result 1 "Replicación INSERT MySQL → PostgreSQL"

echo ""
echo "=== FASE 6: Prueba de Replicación UPDATE ==="
echo ""

# UPDATE en PostgreSQL -> verificar en MySQL
echo "Actualizando producto en PostgreSQL..."
docker exec postgres-america psql -U symmetricds -d globalshop -c "UPDATE products SET base_price = 999.99 WHERE product_id='$TEST_ID'" > /dev/null 2>&1

sleep 10

# Verificar en MySQL
MYSQL_PRICE=$(docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -N -e "SELECT base_price FROM products WHERE product_id='$TEST_ID'" 2>/dev/null | tr -d ' ')
[ "$MYSQL_PRICE" = "999.99" ] && check_result 0 "Replicación UPDATE PostgreSQL → MySQL" || check_result 1 "Replicación UPDATE PostgreSQL → MySQL (precio: $MYSQL_PRICE)"

# UPDATE en MySQL -> verificar en PostgreSQL
echo "Actualizando producto en MySQL..."
docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -e "UPDATE products SET base_price = 888.88 WHERE product_id='$TEST_ID2'" 2>/dev/null

sleep 10

# Verificar en PostgreSQL
PG_PRICE=$(docker exec postgres-america psql -U symmetricds -d globalshop -t -c "SELECT base_price FROM products WHERE product_id='$TEST_ID2'" | tr -d ' ')
[ "$PG_PRICE" = "888.88" ] && check_result 0 "Replicación UPDATE MySQL → PostgreSQL" || check_result 1 "Replicación UPDATE MySQL → PostgreSQL (precio: $PG_PRICE)"

echo ""
echo "=== FASE 7: Limpieza ==="
echo ""

# Limpiar datos de prueba
docker exec postgres-america psql -U symmetricds -d globalshop -c "DELETE FROM products WHERE product_id LIKE 'TEST-VAL%'" > /dev/null 2>&1
docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -e "DELETE FROM products WHERE product_id LIKE 'TEST-VAL%'" 2>/dev/null

echo "Datos de prueba limpiados"

echo ""
echo "============================================"
echo "  RESUMEN DE VALIDACIÓN"
echo "============================================"
echo ""
echo -e "Pruebas pasadas: ${GREEN}$PASSED${NC}"
echo -e "Pruebas fallidas: ${RED}$FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}¡TODAS LAS PRUEBAS PASARON!${NC}"
    echo "La replicación bidireccional funciona correctamente."
    exit 0
else
    echo -e "${RED}ALGUNAS PRUEBAS FALLARON${NC}"
    echo "Revisa los logs de SymmetricDS para más detalles."
    exit 1
fi
