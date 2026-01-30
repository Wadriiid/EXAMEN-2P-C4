# 🔄 EXAMEN 2P - Replicación Bidireccional SymmetricDS

## 📂 Repositorio
**GitHub:** https://github.com/Wadriiid/EXAMEN-2P-C4.git

## 👤 Estudiante
| Campo | Valor |
|-------|-------|
| **Nombre** | Rolando Jair Delgado Parraga |
| **Cédula** | 1313463208 |
| **Fecha** | 29/01/2026 |
| **Asignatura** | Administración de Bases de Datos Distribuidas |

---

## 📝 Descripción del Proyecto

Este proyecto implementa una **replicación lógica bidireccional heterogénea** entre:

- **PostgreSQL 15** (Nodo América) ↔ **MySQL 8.0** (Nodo Europa)

Utilizando **SymmetricDS 3.16** como motor de replicación dentro de contenedores Docker.

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                 DOCKER COMPOSE NETWORK                       │
│                 (globalshop-network)                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────┐              ┌────────────────┐         │
│  │ POSTGRES       │              │ MYSQL          │         │
│  │ (América)      │              │ (Europa)       │         │
│  │ Puerto: 5432   │              │ Puerto: 3306   │         │
│  └───────┬────────┘              └───────┬────────┘         │
│          │                               │                   │
│          ▼                               ▼                   │
│  ┌────────────────┐              ┌────────────────┐         │
│  │ SYMMETRICDS    │◄────────────►│ SYMMETRICDS    │         │
│  │ AMERICA        │ Bidireccional│ EUROPE         │         │
│  │ Puerto: 31415  │              │ Puerto: 31416  │         │
│  │ (Nodo Raíz)    │              │ (Nodo Cliente) │         │
│  └────────────────┘              └────────────────┘         │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Cómo Usar

### 1. Clonar el repositorio
```bash
git clone https://github.com/Wadriiid/EXAMEN-2P-C4.git
cd EXAMEN-2P-C4
```

### 2. Levantar los contenedores
```bash
docker-compose up -d
```

### 3. Verificar que todo esté corriendo
```bash
docker-compose ps
```
Debes ver 4 contenedores en estado "Up":
- `postgres-america`
- `mysql-europe`
- `symmetricds-america`
- `symmetricds-europe`

### 4. Esperar inicialización
Esperar **2-3 minutos** para que:
- Las bases de datos se inicialicen
- SymmetricDS cree sus tablas `sym_*`
- El nodo Europa se registre en América

---

## 🧪 Probar la Replicación

### INSERT PostgreSQL → MySQL
```bash
# Insertar en PostgreSQL
docker exec postgres-america psql -U symmetricds -d globalshop -c "
INSERT INTO products (product_id, product_name, category, base_price, description, is_active, created_at, updated_at)
VALUES ('TEST-001', 'Producto Test', 'Testing', 99.99, 'Prueba', true, NOW(), NOW());
"

# Esperar 10 segundos y verificar en MySQL
docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -e "
SELECT * FROM products WHERE product_id='TEST-001';
"
```

### INSERT MySQL → PostgreSQL
```bash
# Insertar en MySQL
docker exec mysql-europe mysql -u symmetricds -psymmetricds globalshop -e "
INSERT INTO customers (customer_id, first_name, last_name, email, country, tier, created_at, updated_at)
VALUES ('CUST-001', 'Juan', 'Perez', 'juan@test.com', 'España', 'Premium', NOW(), NOW());
"

# Esperar 10 segundos y verificar en PostgreSQL
docker exec postgres-america psql -U symmetricds -d globalshop -c "
SELECT * FROM customers WHERE customer_id='CUST-001';
"
```

---

## 📁 Estructura del Proyecto

```
EXAMEN-2P-C4/
├── docker-compose.yml              # Orquestación de 4 servicios
├── init-db/
│   ├── postgres/
│   │   └── 01-init.sql             # Esquema PostgreSQL
│   └── mysql/
│       └── 01-init.sql             # Esquema MySQL
├── symmetricds/
│   ├── america/
│   │   ├── symmetric.properties    # Config nodo raíz (PostgreSQL)
│   │   └── engines/
│   │       └── america.properties  # SQL: grupos, canales, triggers, routers
│   └── europe/
│       ├── symmetric.properties    # Config nodo cliente (MySQL)
│       └── engines/
│           └── europe.properties   # Vacío (hereda de América)
├── evidencias/
│   └── README.md                   # Documentación de pruebas
└── docs/
    ├── SYMMETRICDS_GUIDE.md
    └── TROUBLESHOOTING.md
```

---

## ⚙️ Configuración Implementada

### Tablas Replicadas
| Tabla | Canal | Dirección |
|-------|-------|-----------|
| `products` | products_channel | ↔ Bidireccional |
| `inventory` | inventory_channel | ↔ Bidireccional |
| `customers` | customers_channel | ↔ Bidireccional |
| `regional_pricing` | promotions_channel | ↔ Bidireccional |

### Nodos
| Nodo | group.id | external.id | Puerto | BD |
|------|----------|-------------|--------|-----|
| América | america-store | 001 | 31415 | PostgreSQL |
| Europa | europe-store | 002 | 31416 | MySQL |

### Enlaces
- `america-store` → `europe-store` (W - Wait/Write)
- `europe-store` → `america-store` (W - Wait/Write)

---

## 🛠️ Comandos Útiles

```bash
# Ver logs de SymmetricDS
docker-compose logs -f symmetricds-america
docker-compose logs -f symmetricds-europe

# Reiniciar todo
docker-compose down -v
docker-compose up -d

# Verificar tablas sym_* en PostgreSQL
docker exec postgres-america psql -U symmetricds -d globalshop -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_name LIKE 'sym_%';"

# Verificar nodos registrados
docker exec postgres-america psql -U symmetricds -d globalshop -c "SELECT * FROM sym_node;"
```

---

## ✅ Puntuación del Examen

| Sección | Puntos | Estado |
|---------|--------|--------|
| docker-compose.yml | 40 | ✅ |
| Config América | 30 | ✅ |
| Config Europa | 30 | ✅ |
| **TOTAL** | **100** | ✅ |
| BONUS Funcionalidad | +20 | ✅ |

---

## 📚 Tecnologías Utilizadas

- **Docker** & **Docker Compose**
- **PostgreSQL 15**
- **MySQL 8.0**
- **SymmetricDS 3.16**

---

*Examen Práctico - Administración de Bases de Datos Distribuidas 2025-2*
