# Guía de Ejecución del Proyecto GAV

## Requisitos Previos

Antes de ejecutar el proyecto, asegúrate de tener instalado:

- Java JDK (versión compatible con Spring Boot)
- Maven
- Node.js + npm
- Python
- Virtual Environment (.venv)
- Uvicorn
- MySQL Server
- MySQL Workbench

---
# 1. Configuración de Base de Datos (MySQL)

Antes de ejecutar el backend, debes crear la base de datos en MySQL Workbench.

### Abrir MySQL Workbench
Conéctate a tu instancia local de MySQL o al servidor donde tengas acceso.

### Crear base de datos
Ejecuta la siguiente consulta SQL:

```sql
CREATE DATABASE gav1;
```

### Verificar que la base de datos fue creada
```sql
SHOW DATABASES;
```

Debe aparecer la base de datos:

```bash
gav1
```

---

# 2. Ejecutar Backend (Spring Boot)

Ubícate en la carpeta raíz del proyecto donde esté almacenado en tu equipo.

### Ruta del proyecto
```bash
C:\ruta\donde\almacenes\gav
```

### Ejecutar backend
```bash
mvn spring-boot:run
```

Esto iniciará el servidor backend de Spring Boot.

---

# 3. Ejecutar Frontend (React / Vite)

Ubícate en la carpeta del frontend del proyecto.

### Ruta del proyecto
```bash
C:\ruta\donde\almacenes\gav\.claude\worktrees\competent-yonath-e9d9d8\frontend
```

### Instalar dependencias
```bash
npm install
```

### Ejecutar frontend
```bash
npm run dev
```

Esto iniciará la aplicación frontend en modo desarrollo.

---

# 4. Ejecutar Modelo / API de Optimización (Python)

Ubícate en la carpeta del optimizador/modelo.

### Ruta del proyecto
```bash
C:\ruta\donde\almacenes\gav\optimizer
```

### Activar entorno virtual
```bash
.venv\Scripts\activate
```

### Ejecutar API del modelo
```bash
python -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```

Esto levantará el servicio del modelo en el puerto **8001**.

---

# Orden recomendado de ejecución

Se recomienda iniciar los servicios en este orden:

1. Modelo (Python / Optimizer)
2. Backend (Spring Boot)
3. Frontend (React / Vite)

---

# Resumen rápido de comandos

## Backend
```bash
cd C:\ruta\donde\almacenes\gav
mvn spring-boot:run
```

## Frontend
```bash
cd C:\ruta\donde\almacenes\gav\.claude\worktrees\competent-yonath-e9d9d8\frontend
npm install
npm run dev
```

## Modelo
```bash
cd C:\ruta\donde\almacenes\gav\optimizer
.venv\Scripts\activate
python -m uvicorn main:app --host 0.0.0.0 --port 8001 --reload
```
