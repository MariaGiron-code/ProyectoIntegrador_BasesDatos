# EPNprendeDB - Sistema de Gestión de Bases de Datos Seguras

Sistema avanzado de gestión y protección de bases de datos PostgreSQL para el entorno **EPNprende**. Este proyecto implementa medidas de seguridad de alto nivel para garantizar la confidencialidad, integridad y disponibilidad de los datos.

---

## Descripción del Proyecto

EPNprendeDB es un sistema orientado a la **seguridad de bases de datos PostgreSQL**, que combina cifrado, control de accesos, respaldo automatizado y monitoreo en tiempo real. Está diseñado para operar en entornos sensibles donde se requiere proteger datos personales, credenciales y operaciones críticas.

---

## 🚀 Características Principales

- 🔐 **Cifrado avanzado**  
  Protección de datos sensibles mediante **AES-256**, tanto en reposo como en tránsito.

- 👥 **Roles personalizados**  
  Cinco niveles de acceso:  
  `Administrador`, `Auditor`, `Operador`, `Cliente` y `Usuario final`, con permisos específicos.

- 🧱 **Protección contra amenazas**  
  Medidas integradas contra **SQL Injection** y validación estricta de entradas.

- 📋 **Auditoría completa**  
  Registro detallado de cambios, accesos y eventos para trazabilidad.

- 💾 **Sistema de respaldo**  
  Soporta backups en **caliente** (sin detener el sistema) y en **frío**, con restauración total o parcial.

---

## 🗂️ Estructura de la Base de Datos

Organizada en **tres esquemas**:

- **`operaciones`**: Usuarios, productos, transacciones, etc.  
- **`auditoria`**: Logs de accesos, cambios, intentos de intrusión.  
- **`configuracion`**: Parámetros críticos, claves de cifrado, control de roles.

---

## ⚙️ Procedimientos Clave

### Configuración inicial

- Activación de extensiones como `pgcrypto`.
- Definición de roles y políticas de acceso.

### 🔐 Cifrado de datos

- Funciones que cifran automáticamente campos sensibles antes de guardarlos en la base.

### 🔑 Gestión de accesos

- Permisos granulares por usuario y esquema.
- Acceso restringido por nivel de rol.

---

## Respaldo y Recuperación

- ✅ **Backup en caliente**: Copia de seguridad sin interrumpir el sistema.  
- 🛑 **Backup en frío**: Sistema detenido para asegurar coherencia total.  
- 🔁 **Recuperación parcial** o total desde cualquier backup.

---

## 🔬 Pruebas de Seguridad

- **Simulación de ataques**: SQL Injection controlado para validación de defensas.  
- **Verificación de cifrado**: Confirmación de protección en reposo y tránsito.

---

## Documentación Requerida

- Evidencias gráficas de:
  - Proceso de backup.
  - Resultados de auditoría.
  - Logs de intentos de intrusión.

---

## 🌐 Integración con Neon Wireless

Sistema conectado a **Neon Wireless**, plataforma serverless para PostgreSQL.

### 🌩️ Beneficios:

- 🔄 **Escalabilidad automática**
- 🔐 **Conexiones seguras** (SSL/TLS)
- 🌍 **Alta disponibilidad** con replicación multi-región
- ** Monitoreo de actividades y consumo de recursos.

---

### 📊 Monitoreo Integrado

A través de **Neon Console**:

- Métricas de CPU / Memoria
- Detección de accesos no autorizados
- Análisis del rendimiento de consultas

### 📁 Políticas de Retención

- **Backups**: Conservados 30 días en Neon Storage  
---

## ⚠️ Limitaciones Conocidas

| Limitación                       | Detalle                              |
|----------------------------------|--------------------------------------|
| Latencia en cifrado              | 2–5 ms en operaciones AES-256        |
| Conexiones simultáneas (plan básico) | Máximo 100 conexiones concurrentes |
