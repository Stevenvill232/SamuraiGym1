# Sistema de Gestión de Gimnasio

Plataforma completa para administrar un gimnasio: **aplicación de escritorio para el personal**, **aplicación móvil para los miembros** y una **API REST** que las conecta con una base de datos PostgreSQL. Incluye planes y tiqueteras, contabilidad, tienda e inventario, notificaciones y un **asistente con inteligencia artificial** que genera rutinas y sugerencias de comida personalizadas.

![Flutter](https://img.shields.io/badge/Flutter-Dart%203-02569B?logo=flutter&logoColor=white)
![NestJS](https://img.shields.io/badge/NestJS-TypeScript-E0234E?logo=nestjs&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Prisma-4169E1?logo=postgresql&logoColor=white)
![IA](https://img.shields.io/badge/IA-Gemini%20%7C%20Claude%20%7C%20OpenAI-8E44AD)

---

## Contenido

1. [Características](#-características)
2. [Arquitectura](#-arquitectura)
3. [Tecnologías](#-tecnologías)
4. [Estructura del repositorio](#-estructura-del-repositorio)
5. [Modelo de datos](#-modelo-de-datos)
6. [Instalación y ejecución](#-instalación-y-ejecución)
7. [Variables de entorno](#-variables-de-entorno)
8. [Asistente de IA](#-asistente-de-ia)
9. [Roles y permisos](#-roles-y-permisos)
10. [API](#-api)
11. [Seguridad](#-seguridad)
12. [Notificaciones](#-notificaciones)
13. [Estado del proyecto y mejoras futuras](#-estado-del-proyecto-y-mejoras-futuras)
14. [Archivos que nunca deben subirse al repositorio](#-archivos-que-nunca-deben-subirse-al-repositorio)
15. [Licencia](#-licencia)

---

## Características

### 🖥️ Aplicación de administración (Windows)

| Módulo | Qué permite |
|---|---|
| **Dashboard** | Miembros activos, ganancia del día y del mes, y alertas de vencimiento con colores (naranja: 2 días, rojo: 1 día, gris: vencido) |
| **Miembros** | Búsqueda, registro, edición, desactivación y restablecimiento de contraseña |
| **Planes y Pagos** | Gimnasio (sesión, quincena, mes), tiqueteras (10/15/20/30 días con registro de uso) y Boxeo, Karate y MMA con **varios horarios por plan** |
| **Contabilidad** | Ingresos automáticos desde planes y ventas, gastos por categoría y resumen financiero del mes |
| **Tienda** | Inventario, alerta de stock bajo y ventas con descuento automático de stock |
| **Configuración** | Precios, categorías de gastos, métodos de pago, horarios, personal y roles, información del gimnasio y avisos |

### 📱 Aplicación de miembros (Android)

- **Inicio:** planes con barra de progreso y estado (activo, por vencer, vencido, agotado), medidas actuales y campana de notificaciones.
- **Mi plan:** detalle, horarios e historial de días de tiquetera usados.
- **Asistente IA:** chat, generador de rutinas y sugerencias de comida.
- **Progreso:** registro de peso y estatura con gráfico de evolución.
- **Perfil:** datos personales, preferencias de alimentación, perfil de entrenamiento y cambio de contraseña.
- **Notificaciones del sistema** cuando hay avisos nuevos.

### Transversales

- Una misma persona puede tener **varios roles** (por ejemplo, recepcionista y también miembro) con una sola cuenta.
- Recuperación de contraseña del personal **por correo** con código de un solo uso.
- Configuración editable sin tocar el código ni la estructura de la base de datos.
- Calendarios y formatos en español.

---

## Arquitectura

Ninguna aplicación accede directamente a la base de datos: ambas se comunican únicamente con la API.

```mermaid
flowchart LR
    A["App Administración<br/>Flutter · Windows"] -->|"HTTP + JSON"| API
    M["App Miembros<br/>Flutter · Android"] -->|"HTTP + JSON"| API
    API["Backend API<br/>NestJS · puerto 3000"] --> DB[("PostgreSQL")]
    API --> SMTP["Correo SMTP"]
    API --> IA["IA: Gemini / Claude / OpenAI"]
```

**Backend:** arquitectura modular. Cada funcionalidad es un módulo con `controller` (rutas y permisos), `dto` (validación de entrada) y `service` (lógica de negocio y acceso a datos con Prisma).

---

## Tecnologías

| Capa | Tecnología |
|---|---|
| Backend | NestJS, TypeScript |
| Base de datos | PostgreSQL, Prisma ORM |
| Autenticación | JWT, bcrypt, Passport |
| Tareas programadas | `@nestjs/schedule` |
| Correo | Nodemailer (SMTP) |
| IA | Google Gemini, Anthropic (Claude) u OpenAI, vía HTTP |
| Frontend | Flutter, Dart |
| Estado y navegación | Riverpod, go_router |
| Cliente HTTP | Dio (envuelto en `ApiClient`) |
| Almacenamiento seguro | flutter_secure_storage |
| Gráficos | fl_chart |
| Notificaciones | flutter_local_notifications |
| Documentación de la API | Swagger (OpenAPI) |

---

## Estructura del repositorio

```
.
├── backend/                 API REST (NestJS + TypeScript + Prisma)
│   ├── prisma/              schema.prisma, migraciones y seed
│   └── src/
│       ├── auth/            Login, JWT, recuperación de contraseña
│       ├── users/           Miembros y personal, roles múltiples
│       ├── plans/           Planes, tiqueteras y su ingreso contable
│       ├── schedules/       Horarios de Boxeo, Karate y MMA
│       ├── accounting/      Ingresos, gastos y resumen
│       ├── store/           Productos y ventas
│       ├── dashboard/       Indicadores y alertas
│       ├── settings/        Configuración editable
│       ├── profile/         Perfil y preferencias del miembro
│       ├── progress/        Historial de peso y estatura
│       ├── notifications/   Avisos automáticos e historial
│       ├── ai/              Rutinas, comidas y chat con IA
│       ├── mail/            Envío de correos
│       └── common/          Guards, decorators, filtros y utilidades
├── shared_models/           Paquete Dart compartido por las dos apps
│   └── lib/src/             models, network (ApiClient), theme, widgets
├── admin_app/               App de escritorio (Flutter · Windows)
└── member_app/              App móvil (Flutter · Android)
```

Cada app Flutter se organiza en `core/router` (rutas), `presentation/screens` (pantallas), `presentation/widgets` (componentes) y `providers` (estado y llamadas a la API).

---

## Modelo de datos

PostgreSQL con 20 modelos gestionados por Prisma (`backend/prisma/schema.prisma`).

```mermaid
erDiagram
    ROLE ||--o{ USER : "rol principal"
    USER ||--o{ PLAN : "compra"
    PLAN ||--o{ PLAN_HORARIO : "entrena en"
    HORARIO ||--o{ PLAN_HORARIO : "pertenece a"
    PLAN ||--o{ USO_TIQUETERA : "registra"
    PLAN ||--o{ INGRESO : "genera"
    VENTA ||--|| INGRESO : "genera"
    VENTA ||--o{ DETALLE_VENTA : "contiene"
    PRODUCTO ||--o{ DETALLE_VENTA : "se vende en"
    USER ||--o{ HISTORIAL_FISICO : "registra"
    USER ||--o| PERFIL_ENTRENAMIENTO : "tiene"
    USER ||--o| PREFERENCIA_ALIMENTACION : "tiene"
    USER ||--o{ RUTINA_GENERADA : "recibe"
    USER ||--o{ RECOMENDACION_ALIMENTARIA : "recibe"
    USER ||--o{ HISTORIAL_NOTIFICACION : "recibe"
```

**Decisiones de diseño**

- **UUID** como identificadores: no se pueden adivinar desde la API.
- **Dinero con `Decimal(10,2)`**, nunca `Float`.
- **El precio es una foto del momento:** planes y detalles de venta guardan lo que realmente se cobró; cambiar una tarifa no altera el historial.
- **Borrado lógico:** miembros y productos se desactivan, no se eliminan, para conservar el historial.
- **Estados calculados:** la edad y el estado de un plan se derivan de fechas, no se escriben a mano.
- **Configuración clave-valor (JSON):** precios, catálogos e información del gimnasio se editan desde la app.
- **Roles:** rol principal más roles adicionales (relación muchos a muchos) para una misma persona.
- **Transacciones:** registrar un plan (plan + ingreso) y vender (stock + venta + ingreso) son operaciones atómicas.

---

## Instalación y ejecución

### Requisitos

- **Node.js** 20 o superior
- **PostgreSQL** 14 o superior (local o en la nube)
- **Flutter** (canal estable) con soporte para Windows y la cadena de herramientas de Android

### 1. Clonar el repositorio

```bash
git clone <URL-del-repositorio>
cd <carpeta-del-repositorio>
```

### 2. Backend

```bash
cd backend
cp .env.example .env        # en Windows (CMD): copy .env.example .env
# Edita .env con tus valores (ver "Variables de entorno")
npm install
npx prisma migrate dev      # crea las tablas
npx prisma db seed          # crea los roles y un administrador inicial
npm run start:dev
```

- API: `http://localhost:3000/api`
- Documentación interactiva (Swagger): `http://localhost:3000/api/docs`

> El seed crea un usuario administrador inicial; sus credenciales están en `backend/prisma/seed.ts`. **Cámbialas apenas inicies sesión.**

### 3. App de administración (Windows)

```bash
cd admin_app
flutter create --platforms=windows .    # genera las carpetas nativas (no sobrescribe lib/ ni pubspec.yaml)
flutter pub get
flutter run -d windows
```

Usa `http://localhost:3000/api` por defecto (`kApiBaseUrl` en `admin_app/lib/providers/auth_provider.dart`), porque corre en el mismo computador que el backend.

### 4. App de miembros (Android)

```bash
cd member_app
flutter create --platforms=android .
flutter pub get
flutter run
```

**Antes de ejecutarla, configura tres cosas:**

**a) La dirección del backend** en `member_app/lib/providers/auth_provider.dart` (`kApiBaseUrl`):

| Dónde corre la app | Valor de `kApiBaseUrl` |
|---|---|
| Emulador de Android | `http://10.0.2.2:3000/api` |
| Teléfono físico (misma red WiFi que el computador) | `http://<IP-local-del-computador>:3000/api` |
| Teléfono por USB con `adb reverse tcp:3000 tcp:3000` | `http://localhost:3000/api` |

> `localhost` en un teléfono es el propio teléfono, por eso necesita la IP del computador (en Windows: `ipconfig`, dirección IPv4). Verifica además que el firewall permita conexiones entrantes al puerto 3000.

**b) `android/app/src/main/AndroidManifest.xml`:**

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<application
    android:usesCleartextTraffic="true"   <!-- SOLO en desarrollo (HTTP). En producción usa HTTPS y quítalo -->
    ... >
```

**c) `android/app/build.gradle.kts`** (requerido por `flutter_local_notifications`):

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        // ...
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

---

## Variables de entorno

Define estas variables en `backend/.env` (parte de `.env.example`). **Nunca subas el archivo `.env` real al repositorio.**

| Variable | Descripción |
|---|---|
| `DATABASE_URL` | Cadena de conexión a PostgreSQL |
| `PORT` | Puerto de la API (por defecto `3000`) |
| `NODE_ENV` | `development` o `production` |
| `JWT_SECRET` | Secreto para firmar los tokens (largo y aleatorio) |
| `JWT_EXPIRES_IN` | Duración de la sesión (por defecto `8h`) |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_SECURE` | Servidor de correo |
| `SMTP_USER` / `SMTP_PASS` | Credenciales de correo (con Gmail, una *contraseña de aplicación*) |
| `MAIL_FROM` | Remitente de los correos |
| `AI_PROVIDER` | `google`, `anthropic` u `openai` |
| `AI_API_KEY` | Clave del proveedor de IA |
| `AI_MODEL` | Nombre del modelo a usar |
| `AI_BASE_URL` | *(opcional)* Proxy o servidor de pruebas |
| `AI_MAX_POR_HORA` | Consultas de IA por usuario por hora (por defecto `30`) |

Ejemplo (valores de ejemplo, **reemplázalos**):

```env
DATABASE_URL="postgresql://usuario:password@localhost:5432/gym_db?schema=public"
PORT=3000
NODE_ENV=development
JWT_SECRET="cambia-esto-por-un-secreto-largo-y-aleatorio"
JWT_EXPIRES_IN="8h"

SMTP_HOST="smtp.ejemplo.com"
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER="usuario@ejemplo.com"
SMTP_PASS="contraseña-de-aplicación"
MAIL_FROM="Gym Admin <usuario@ejemplo.com>"

AI_PROVIDER="google"
AI_API_KEY="tu-clave-de-api"
AI_MODEL="nombre-del-modelo"
AI_MAX_POR_HORA=30
```

> Si `SMTP_HOST` está vacío, el sistema no envía correos: en desarrollo imprime el código de recuperación en la consola del backend. Si `AI_API_KEY` está vacío, el asistente responde que no está configurado.

---

## Asistente de IA

El backend actúa como intermediario con el proveedor de IA. **La clave vive únicamente en el servidor:** la app del teléfono nunca la ve.

- **Proveedor intercambiable:** `LlmService` expone una sola función y envía la solicitud a Google Gemini, Anthropic o OpenAI según `AI_PROVIDER`. Sin SDK: solo HTTP.
- **Funciones:** generar una rutina de entrenamiento, sugerir una comida (desayuno, media mañana, almuerzo, merienda o cena) y chat con historial.
- **Personalización:** se usa la edad, el sexo, el peso, la estatura, el objetivo, las lesiones, el equipamiento, las alergias y las restricciones del miembro, más lo que pide en el momento (enfoque, tiempo, lugar).
- **Privacidad:** a la IA **no se envía** cédula, nombre ni correo.
- **Seguridad del contenido:** el prompt obliga a respetar lesiones y alergias, no diagnosticar ni recetar, derivar a un profesional ante dolor o condiciones médicas y limitarse a entrenamiento y alimentación. Los datos del usuario se tratan como información, no como instrucciones.
- **Respuestas estructuradas:** rutinas y comidas se piden en JSON, se extraen, se normalizan y se reintenta una vez si la respuesta no es válida. Se guardan como historial.
- **Control de costo:** límite por usuario por hora, tiempo máximo de espera y errores del proveedor traducidos a mensajes claros.

> ⚠️ Si usas un plan gratuito de un proveedor de IA, revisa sus términos: algunos permiten usar los datos enviados para mejorar sus productos. Para uso real con datos de personas, considera un plan de pago con garantías de privacidad.

---

## Roles y permisos

| Rol | Acceso |
|---|---|
| **ADMINISTRADOR** | Todo, incluida la configuración y la gestión del personal |
| **RECEPCION** | Miembros, planes y pagos, y ventas de la tienda |
| **ENTRENADOR** | Consulta de miembros y planes, registro de días de tiquetera y horarios |
| **CONTADOR** | Contabilidad |
| **MIEMBRO** | App móvil: su plan, progreso, perfil, notificaciones y asistente de IA |

El menú de la app de administración muestra a cada rol solo lo que le corresponde, pero **la barrera real está en el backend** (`@Roles()` + `RolesGuard`).

---

## API

Prefijo global `/api`. Documentación completa en `/api/docs` (Swagger).

| Grupo | Ejemplos |
|---|---|
| `auth` | `POST /auth/login`, `GET /auth/me`, `PATCH /auth/password`, recuperación de contraseña |
| `users` | CRUD de miembros y personal, roles, restablecer contraseña |
| `plans` | Registrar plan, listar, `PATCH /plans/:id/usar-tiquetera`, `GET /plans/me` |
| `schedules` | Horarios por deporte, creación por lote |
| `accounting` | Ingresos, gastos y `GET /accounting/resumen` |
| `store` | Productos, stock bajo y ventas |
| `dashboard` | `GET /dashboard/admin`, `GET /dashboard/miembro` |
| `settings` | `GET /settings`, `PUT /settings/:clave` |
| `profile` / `progress` | Perfil, preferencias y registros de peso y estatura del propio usuario |
| `notifications` | Historial, contador de no leídos, marcar como leídas |
| `ai` | `POST /ai/routine`, `POST /ai/nutrition`, `POST /ai/chat` y sus historiales |

Los endpoints de autoservicio (`/profile`, `/progress`, `/plans/me`, `/notifications/me`, `/ai/*`) operan siempre sobre el usuario del token, nunca sobre un identificador enviado por el cliente.

---

## Seguridad

- Autenticación con **JWT** y contraseñas con **bcrypt**.
- Control de acceso por **roles** aplicado en el servidor.
- **Validación global** de datos de entrada: se rechaza cualquier campo no declarado.
- Filtro global de errores: formato uniforme y sin exponer detalles técnicos.
- Mensaje de login genérico («credenciales inválidas») para no revelar si una cédula existe.
- **Recuperación de contraseña:** código de 6 dígitos guardado solo como *hash*, vence en 15 minutos, un solo uso, bloqueo tras 5 intentos y límite de envíos; la respuesta es idéntica exista o no la cuenta.
- Salvaguardas de usuarios: solo un administrador otorga roles de personal, nadie puede desactivarse a sí mismo y siempre queda al menos un administrador.
- Borrado lógico para conservar el historial contable.

---

## Notificaciones

- **Servidor:** una tarea programada se ejecuta al iniciar y cada hora. Recalcula el estado de los planes y crea avisos de vencimiento (2 días, 1 día y vencido, configurables). Cada aviso tiene una clave única, por lo que nunca se repite.
- **Eventos:** aviso al registrar un plan y al usar o agotar una tiquetera.
- **Teléfono:** la app consulta cada 30 segundos si hay avisos nuevos y los muestra como **notificación del sistema**; además, una campana con contador dentro de la app. Funciona con la app abierta o recién enviada a segundo plano.

---

## Estado del proyecto y mejoras futuras

Funcionalidades completas: autenticación y roles, miembros, planes y tiqueteras, contabilidad, tienda, configuración, app de miembros, notificaciones, recuperación de contraseña por correo y asistente de IA.

**Pendiente / ideas:**

- [ ] Notificaciones *push* con la app cerrada (Firebase Cloud Messaging)
- [ ] Fotos de perfil y de productos
- [ ] Pruebas automatizadas (unitarias y de integración)
- [ ] Cierre de sesión automático al vencer el token
- [ ] Límite de intentos en el login
- [ ] Despliegue (Docker, HTTPS y variables de producción)

---

## Archivos que nunca deben subirse al repositorio

Agrega un `.gitignore` en la raíz con, como mínimo:

```gitignore
# Secretos y entorno
.env
.env.*
!.env.example
*.pem
*service-account*.json

# Backend
backend/node_modules/
backend/dist/

# Flutter / Dart
.dart_tool/
build/
.flutter-plugins
.flutter-plugins-dependencies
*.iml
.idea/
.vscode/

# Android / Windows generados
**/android/local.properties
**/android/.gradle/
**/android/key.properties
**/*.jks
**/*.keystore

# Sistema
.DS_Store
Thumbs.db
```

Antes de publicar, revisa que no hayan quedado **direcciones IP locales**, claves de API, contraseñas ni credenciales reales en el código (por ejemplo, en `kApiBaseUrl`).

