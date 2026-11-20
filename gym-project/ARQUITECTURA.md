# Arquitectura del Sistema de Gestión de Gimnasio

Este documento es el entregable de la **Fase 1** pedida en el proyecto:
análisis de requerimientos, inconsistencias detectadas y su resolución,
arquitectura general, modelo de datos, estructura de carpetas, endpoints,
flujos de negocio y plan de fases. Se actualiza a medida que avanzamos.

---

## 1. Inconsistencias detectadas en el documento original y su resolución

Antes de escribir código se revisó todo el documento buscando contradicciones
o puntos técnicamente inviables. Esto es lo que se encontró y cómo se
resolvió:

### 1.1 "API REST" vs. "información en tiempo real"
El documento pide backend por API REST **y** que ambas apps compartan
información "en tiempo real". Una API REST pura es petición/respuesta, no
empuja datos por sí sola.

**Resolución:** REST sigue siendo la fuente de verdad para todo el CRUD.
"Tiempo real" se logra con la combinación:
- Refrescos automáticos al entrar/volver a una pantalla (`pull to refresh` /
  recarga al enfocar).
- Firebase Cloud Messaging como **disparador**: cuando algo relevante cambia
  en el servidor (ej. un pago se registró, un plan está por vencer), se
  envía una notificación push que la app usa como señal para refrescar sus
  datos, no solo para mostrar un mensaje.
- Si más adelante se necesita una vista realmente "en vivo" (ej. el contador
  de ganancia del día actualizándose solo mientras el admin lo mira),
  se puede agregar un canal WebSocket puntual para el Dashboard, sin tocar
  el resto de la API REST. No se construye desde ya para no sobre-diseñar.

### 1.2 Notificaciones push en la app de escritorio (Windows)
El documento pide FCM para "notificaciones push" en general, pero el plugin
oficial de Flutter (`firebase_messaging`) **no soporta Windows Desktop**
(sí Android, iOS, web y macOS).

**Resolución:** FCM se usa para la **app de miembros** (móvil), que es
además donde más aporta valor (avisos de vencimiento al usuario final fuera
de la app). La app administrativa, al ser de uso activo por el staff, cubre
su necesidad de alertas con el propio panel del Dashboard (las alertas de
vencimiento ya están siempre visibles ahí) y, si se requiere, un refresco
periódico. No se pierde funcionalidad real, solo se ajusta el mecanismo a
lo que la plataforma permite.

### 1.3 Precios/tarifas que cambian pero no deben afectar el histórico
El documento pide que un cambio de precio no altere ventas o planes ya
registrados.

**Resolución:** el precio se guarda como "foto" (`snapshot`) en el momento
de la transacción, nunca como referencia a una tabla de precios "actual":
- `Plan.precio` guarda lo que el miembro pagó, no el precio vigente de hoy.
- `DetalleVenta.precioUnitario` guarda el precio del producto en el momento
  exacto de la venta, aunque `Producto.precioVenta` cambie después.

### 1.4 Roles más allá de Administrador/Miembro
El documento pide mínimo 2 roles pero menciona Recepción, Entrenador y
Contador como futuros, "sin tener que reescribir el sistema".

**Resolución:** los roles NO son un enum fijo en el código; son una tabla
(`Role`) + permisos (`Permission`) en la base de datos. Agregar
"Entrenador" o "Contador" es una fila nueva, no una migración de código. Los
guards del backend (`@Roles('ADMINISTRADOR', 'RECEPCION')`) trabajan con el
nombre del rol como string, así que un rol nuevo solo requiere decidir a
qué endpoints tiene acceso.

### 1.5 Edad y estados calculados no deben "desincronizarse"
Edad (desde fecha de nacimiento) y estado del plan (activo/por
vencer/vencido/agotado) son datos que cambian solos con el tiempo.

**Resolución:** ninguno de los dos se guarda como valor fijo:
- La edad se calcula al vuelo en cada respuesta del backend
  (`UsersService.calcularEdad`), nunca se almacena.
- El estado del plan se recalculará con una tarea programada diaria
  (`@nestjs/schedule`, Fase 6) que revisa fechas de vencimiento y días
  restantes de tiqueteras, y dispara las notificaciones correspondientes.

### 1.6 Consistencia transaccional en Ventas → Stock → Contabilidad
Una venta de producto debe, a la vez: descontar stock, no permitir stock
negativo, y generar un ingreso contable. Si un paso falla, no puede quedar
el sistema a medias (ej. stock descontado pero sin ingreso registrado).

**Resolución:** esta operación se implementará (Fase 4) como una única
transacción de base de datos (`prisma.$transaction`): o se completan los
tres pasos, o no se aplica ninguno.

### 1.7 Costo y seguridad de la IA
Los endpoints de IA (rutina, alimentación, chat) son costosos si se abusa de
ellos y NUNCA deben exponer la API key a Flutter.

**Resolución:** toda llamada a IA pasa por el backend (`AI_API_KEY` vive
solo en `backend/.env`). En la Fase 7 se agrega *rate limiting* por usuario
a estos endpoints específicamente.

---

## 2. Decisiones de stack tecnológico

| Capa | Elección | Por qué |
|---|---|---|
| Backend | **NestJS + TypeScript** | Estructura modular obligatoria (módulo = carpeta con controller/service/dto), Guards nativos para roles, Swagger integrado, encaja con el pedido explícito de "arquitectura limpia y modular". |
| Base de datos | **PostgreSQL** | Datos relacionales (miembros-planes-pagos-contabilidad), transacciones ACID reales para dinero e inventario, tipo `Decimal` exacto para montos. |
| ORM | **Prisma** | Migraciones versionadas, tipado automático de principio a fin, `schema.prisma` sirve también como documentación viva del modelo de datos. |
| Auth | **JWT + bcrypt + Passport** | Estándar, sin estado en el servidor, fácil de validar desde Flutter. |
| Estado en Flutter | **Riverpod** | Sin `BuildContext` para lógica de negocio, fácil de testear, encaja con "controllers/providers" mencionado en el documento. |
| Ruteo en Flutter | **go_router** | Manejo declarativo de rutas + redirects según sesión (usado para proteger pantallas). |
| HTTP en Flutter | **Dio**, envuelto en `ApiClient` (paquete compartido) | Interceptores para adjuntar el JWT automáticamente y traducir errores a mensajes de usuario. |
| Código compartido | **Paquete local `shared_models`** | Los modelos, el tema visual y el cliente HTTP se escriben una sola vez y ambas apps los referencian (`path: ../shared_models`), evitando duplicar lógica de negocio. |
| IA | **API de un proveedor LLM (Anthropic u OpenAI) llamada desde el backend** | Permite pedir salidas estructuradas (JSON) para rutinas/alimentación, mantiene la key segura, y da control de costos vía rate limiting. |

---

## 3. Arquitectura general

El sistema son 3 piezas independientes que hablan entre sí solo por HTTP:

- **Admin App** (Flutter Desktop) — usada por Administrador/Recepción/
  Entrenador/Contador.
- **Member App** (Flutter móvil) — usada por los miembros del gimnasio.
- **Backend API REST** (NestJS) — única puerta de entrada a los datos;
  ninguna app toca la base de datos directamente.

La base de datos (PostgreSQL) es compartida y es la única fuente de verdad.
Firebase Cloud Messaging entrega notificaciones a la app móvil. El
proveedor de IA solo es alcanzable desde el backend, nunca desde Flutter.

*(Ver el diagrama de componentes enviado en el chat.)*

---

## 4. Modelo de datos (resumen de entidades y relaciones)

El detalle exacto -con cada campo, tipo, enum e índice- vive en
`backend/prisma/schema.prisma`, que es la fuente de verdad. Resumen de
relaciones:

- **Role 1—N User**, **Role N—N Permission** (permisos granulares por
  módulo+acción, para poder crear roles nuevos sin migrar código).
- **User 1—N Plan** (un miembro tiene muchos planes a lo largo del tiempo,
  nunca se borran).
- **Plan 1—N UsoTiquetera** (cada vez que se usa un día de tiquetera).
- **Plan N—1 Horario** (opcional; usado por Boxeo/Karate/MMA).
- **User 1—N Ingreso** (como miembro que pagó) y **User 1—N Ingreso**
  (como admin que lo registró) - son dos relaciones distintas a la misma
  tabla, nombradas explícitamente en el schema para no ambigüarlas.
- **Plan 1—N Ingreso**, **Venta 1—1 Ingreso** (una venta genera
  automáticamente su ingreso).
- **Producto 1—N DetalleVenta N—1 Venta**.
- **User 1—N HistorialFisico**, **User 1—1 PreferenciaAlimentacion**,
  **User 1—N RutinaGenerada**, **User 1—N RecomendacionAlimentaria**,
  **User 1—N HistorialNotificacion**.
- **Configuracion** es una tabla clave-valor (JSON) aparte, para ajustes
  del gimnasio (precios, categorías, info general) que deben poder cambiar
  sin migrar el schema.

---

## 5. Estructura de carpetas

### Backend (`backend/src/`)
```
auth/            # login, JWT, estrategia Passport
users/           # miembros y staff (CRUD ya implementado)
prisma/          # PrismaService (conexión a la BD)
common/
  guards/        # JwtAuthGuard, RolesGuard
  decorators/    # @Roles(), @CurrentUser()
  filters/       # formato de error consistente
config/          # variables de entorno tipadas
# Próximos módulos (mismo patrón que `users/`):
# plans/ accounting/ store/ schedules/ dashboard/ ai/ notifications/
```

### Admin app (`admin_app/lib/`)
```
core/router/         # go_router + redirects según sesión
presentation/
  screens/           # una carpeta por módulo (dashboard, members, plans...)
  widgets/           # AppShell (menú lateral), KpiCard, tarjetas reutilizables
providers/           # AuthProvider (Riverpod)
```

### Member app (`member_app/lib/`)
```
core/router/
presentation/
  screens/           # dashboard, plan_line, ai_chat, maintenance, profile
  widgets/           # MemberShell (barra inferior)
providers/
```

### Compartido (`shared_models/lib/`)
```
src/models/      # Usuario, Plan (con sus enums)
src/network/     # ApiClient (Dio), ApiException
src/theme/       # AppTheme, AppColors - mismo sistema visual en ambas apps
```

---

## 6. Endpoints (implementados y planeados)

Prefijo global: `/api`. Documentación interactiva en `/api/docs`.

**Implementadas (Fase 3):**

| Método | Ruta | Rol requerido | Descripción |
|---|---|---|---|
| POST | `/auth/login` | público | Login con cédula + contraseña |
| GET | `/auth/me` | cualquiera autenticado | Datos del token actual |
| POST | `/users` | ADMIN, RECEPCION | Crear miembro/usuario |
| GET | `/users` | ADMIN, RECEPCION, ENTRENADOR | Listar/buscar |
| GET | `/users/:id` | ADMIN, RECEPCION, ENTRENADOR | Detalle |
| PATCH | `/users/:id` | ADMIN, RECEPCION | Editar |
| DELETE | `/users/:id` | ADMIN | Desactivar (borrado lógico) |

**Implementadas (Fase 4):**

| Método | Ruta | Rol requerido | Descripción |
|---|---|---|---|
| POST | `/schedules` | ADMIN | Crear horario de Boxeo/Karate/MMA |
| GET | `/schedules` | cualquiera autenticado | Listar horarios (filtro por deporte) |
| PATCH/DELETE | `/schedules/:id` | ADMIN | Editar / desactivar horario |
| POST | `/plans` | ADMIN, RECEPCION | Registrar plan (crea su Ingreso en la misma transacción) |
| GET | `/plans` | ADMIN, RECEPCION, ENTRENADOR | Listar (filtro por miembroId/estado) |
| GET | `/plans/me` | cualquiera autenticado | Planes del usuario logueado (app de miembros) |
| GET | `/plans/:id` | ADMIN, RECEPCION, ENTRENADOR | Detalle con historial de uso de tiquetera |
| PATCH | `/plans/:id/usar-tiquetera` | ADMIN, RECEPCION, ENTRENADOR | Descuenta un día de tiquetera |
| GET | `/accounting/ingresos` \| `/gastos` | ADMIN, CONTADOR | Listado con filtro de fechas |
| POST | `/accounting/gastos` | ADMIN, CONTADOR | Registrar gasto |
| GET | `/accounting/resumen` | ADMIN, CONTADOR | Totales + utilidad del rango |
| POST/GET | `/store/productos` | ADMIN (POST) / +RECEPCION (GET) | CRUD de productos |
| GET | `/store/productos/stock-bajo` | ADMIN | Productos en o bajo el mínimo |
| POST | `/store/ventas` | ADMIN, RECEPCION | Venta (descuenta stock + genera Ingreso, todo en una transacción) |
| GET | `/store/ventas` | ADMIN, CONTADOR | Historial de ventas |
| GET | `/dashboard/admin` | ADMIN, RECEPCION, ENTRENADOR, CONTADOR | KPIs + alertas de vencimiento en vivo |

**Implementadas (Fase 5):**

| Método | Ruta | Rol requerido | Descripción |
|---|---|---|---|
| GET | `/settings` | cualquiera autenticado | Toda la configuración (con valores por defecto) |
| PUT | `/settings/:clave` | ADMIN | Guarda un ajuste (validado en backend) |
| PATCH | `/auth/password` | cualquiera autenticado | Cambia la contraseña propia |
| PATCH | `/users/:id/password` | ADMIN, RECEPCION | Restablece la clave de un miembro (ADMIN: también del personal) |
| GET | `/users?staff=true` | ADMIN | Lista el personal (roles distintos de MIEMBRO) |
| GET | `/profile` | cualquiera autenticado | Perfil propio + medidas actuales + preferencias |
| PATCH | `/profile` | cualquiera autenticado | Edita datos propios (cédula inmutable; fecha de nacimiento una sola vez) |
| PUT | `/profile/nutrition` · `/profile/training` | cualquiera autenticado | Preferencias de alimentación / perfil de entrenamiento |
| GET/POST/DELETE | `/progress` | cualquiera autenticado | Historial de peso y estatura propio |
| GET | `/dashboard/miembro` | cualquiera autenticado | Resumen del miembro (planes con estado real, medidas, recomendaciones) |

Los endpoints de autoservicio (`/profile`, `/progress`, `/dashboard/miembro`,
`/plans/me`) **nunca reciben un id**: operan siempre sobre el usuario del
token, así que un miembro no puede ver ni tocar datos de otro.

**Implementadas (Fase 5.1 — correcciones y mejoras):**

| Método | Ruta | Rol requerido | Descripción |
|---|---|---|---|
| POST | `/auth/password-reset/request` | público | Envía un código de 6 dígitos al correo del personal |
| POST | `/auth/password-reset/confirm` | público | Valida el código y fija la nueva contraseña |
| POST | `/schedules/bulk` | ADMIN, ENTRENADOR | Crea varios días/horas de un deporte en un solo paso |
| PUT | `/users/:id/staff-roles` | ADMIN | Define los roles de personal de una persona |
| DELETE | `/users/:id?como=miembro\|personal` | ADMIN, RECEPCION | Quita solo una condición (miembro o personal) |

`POST /plans` ahora recibe `horarioIds` (lista) en lugar de un único
`horarioId`.

**Implementadas (Fase 6):**

| Método | Ruta | Rol requerido | Descripción |
|---|---|---|---|
| GET | `/notifications/me` | cualquiera autenticado | Últimos 50 avisos del usuario |
| GET | `/notifications/me/unread-count` | cualquiera autenticado | Cantidad sin leer (campana) |
| PATCH | `/notifications/:id/read` · `/notifications/me/read-all` | cualquiera autenticado | Marcar como leído(s) |
| POST | `/notifications/run-job` | ADMIN | Genera los avisos ahora (para probar) |

**Planeadas por fase:**
- Fase 6: `/notifications`, job diario (`@Cron`, no expuesto por HTTP) que
  recalcula estados de planes y dispara FCM.
- Fase 7: `/ai/rutina`, `/ai/alimentacion`, `/ai/chat`.

---

## 7. Flujos de negocio clave

### 7.1 Autenticación
1. Flutter envía `{ cedula, password }` a `POST /auth/login`.
2. Backend valida contra `passwordHash` (bcrypt) y arma un JWT con
   `{ sub, cedula, role }`.
3. Flutter guarda el token en almacenamiento seguro (`flutter_secure_storage`,
   vía `ApiClient`) y lo adjunta automáticamente en cada petición.
4. Al abrir la app, se valida el token guardado contra `GET /auth/me`; si
   falló o expiró, se manda a Login.
5. La app admin además bloquea el acceso si el rol devuelto es `MIEMBRO`.

### 7.2 Vencimiento de planes
1. Al crear un plan (Fase 4), su vigencia se calcula así: Gimnasio-Sesión
   +1 día, Quincena +15, Mes +30, Boxeo/Karate/MMA +30. Las tiqueteras
   valen el **doble** de sus días en vigencia máxima (ej. tiquetera de 10
   días → 20 días calendario para usarlos); es un valor por defecto,
   ajustable sin tocar código cuando exista el módulo de Configuración.
2. Mientras no exista el job diario de la Fase 6, `PlansService` y
   `DashboardService` recalculan el `estado` real a partir de
   `fechaVencimiento` **en cada lectura** (y lo persisten si cambió), para
   que nunca se muestre un estado desactualizado. El job de la Fase 6
   solo añade el disparo proactivo de notificaciones (`HistorialNotificacion`
   + FCM) cuando el estado cambia, sin el cual igual hay que abrir la app
   para ver la alerta.
3. El Dashboard admin colorea las alertas con la regla exacta del proyecto
   (naranja=2 días, rojo=1 día, gris=vencido reciente), calculada en vivo
   por `DashboardService.adminResumen()`.

### 7.3 Pago → Contabilidad
1. Se registra un `Plan` (o el uso de un cupo de tiquetera).
2. En la misma transacción se crea un `Ingreso` enlazado a ese plan, con el
   monto pagado y el método de pago.
3. Contabilidad simplemente agrega `Ingreso` por fecha/tipo: nunca
   recalcula desde `Plan`, evitando inconsistencias.

### 7.4 Venta → Inventario → Contabilidad
1. Se valida que haya stock suficiente para cada producto del carrito.
2. Transacción única: crear `Venta` + `DetalleVenta[]`, descontar
   `Producto.stock`, crear el `Ingreso` asociado (`tipo: PRODUCTO`).
3. Si cualquier paso falla (ej. se agotó el stock a mitad de camino), toda
   la operación se revierte - nunca queda stock descontado sin venta
   registrada, ni venta sin ingreso.

### 7.5 IA (rutinas, alimentación, chat)
1. Flutter nunca llama directamente al proveedor de IA.
2. El backend arma el contexto del miembro (edad, peso/estatura más
   reciente, objetivo, preferencias/alergias guardadas una sola vez) y lo
   envía al LLM pidiendo una salida en JSON estructurado.
3. La respuesta se guarda (`RutinaGenerada` / `RecomendacionAlimentaria`)
   para tener historial, y se devuelve a Flutter.
4. El chat (`/ai/chat`) es conversacional y no se persiste como
   recomendación formal, pero sí puede loguearse para auditoría/costos.

### 7.6 Notificaciones (FCM)
1. Al iniciar sesión en la app de miembros, se registra el token FCM del
   dispositivo asociado a ese usuario (Fase 6).
2. El backend usa `firebase-admin` para enviar la notificación cuando el
   job diario detecta un evento relevante.
3. Toda notificación enviada queda en `HistorialNotificacion`, visible en
   el Perfil del miembro.

---

## 8. Plan de fases

| Fase | Contenido | Estado |
|---|---|---|
| 1 | Arquitectura general (este documento) | Listo |
| 2 | Modelo de base de datos completo | Listo |
| 3 | Backend base: auth + roles + módulo Miembros | Listo |
| 4 | Planes y Pagos, Tiqueteras, Contabilidad, Tienda (backend + UI admin) | Listo |
| 5 | Configuración (admin) + app de miembros completa: dashboard, línea de plan, perfil, progreso | Listo |
| 6 | Notificaciones: avisos dentro de la app + job automático | Listo (el envío push por FCM queda pendiente) |
| 7 | Integración de IA (rutina, alimentación, chat) | Pendiente |
| 8 | Gráficos avanzados, pulido visual, pruebas, empaquetado final | Pendiente |

Cada módulo nuevo se construirá siguiendo el mismo patrón ya usado en
`users/` (backend) y en las pantallas ya creadas (Flutter), para que el
código se sienta como un solo sistema y no como piezas sueltas.

---

## 9. Decisiones de la Fase 5

### 9.1 Catálogos configurables (categorías de gastos y métodos de pago)
La sección 26 del proyecto pide que el administrador pueda modificarlos.
Como enums de base de datos eso exigiría una migración por cada categoría
nueva, así que `metodoPago` y `categoria` pasaron a ser **texto**, y la lista
válida vive en Configuración (`metodos_pago`, `categorias_gasto`). El backend
valida cada gasto/venta/plan contra esa lista (`SettingsService.assertMetodoPago`
/ `assertCategoriaGasto`). Los registros existentes conservan sus valores
(`'EFECTIVO'`, `'LUZ'`...), y quitar una opción de la lista no altera el
histórico.

### 9.2 Configuración como clave-valor
Tabla `configuracion` (ya existía). Claves: `precios_planes`,
`tiquetera_factor_vigencia`, `categorias_gasto`, `metodos_pago`,
`stock_minimo_default`, `info_gimnasio`, `notificaciones`. Cada clave tiene
valor por defecto y validación propia; los campos nuevos que se agreguen en
el futuro toman su default sin romper lo guardado. Los precios configurados
son **sugerencias** al registrar un plan: cada plan guarda el precio
realmente cobrado.

### 9.3 Roles y permisos
- El menú de la app admin se filtra por rol (`core/permissions.dart`),
  alineado con los `@Roles()` del backend (que sigue siendo la barrera real).
- Recepción: miembros, planes y pagos, ventas. Entrenador: consulta de
  miembros/planes, usar tiquetera y horarios. Contador: contabilidad.
- Salvaguardas añadidas en `UsersService`: solo un administrador crea o
  modifica cuentas de personal (evita escalada de privilegios); nadie puede
  desactivarse a sí mismo; no se puede desactivar ni degradar al último
  administrador; la cédula es inmutable también vía API.
- Recepción puede desactivar y restablecer la contraseña de **miembros**
  (no de personal).

### 9.4 Perfil del miembro
- El miembro edita contacto y dirección; **no** puede editar cédula, planes,
  pagos ni datos contables.
- Fecha de nacimiento ("según reglas administrativas"): el miembro puede
  registrarla **una sola vez**; para corregirla debe pedirlo al gimnasio.
- Datos permanentes para la IA: `PreferenciaAlimentacion` (ampliada con
  alimentos que no le gustan, restricciones y número de comidas) y la nueva
  `PerfilEntrenamiento` (nivel, lesiones, equipamiento, días y tiempo
  disponibles). Se piden una vez y se reutilizan en la Fase 7.

### 9.5 Seguimiento de errores de la API
Un 401 en el login significa "credenciales incorrectas"; en cualquier otra
llamada significa "sesión vencida". Un 403 muestra "no tienes permiso". La
contraseña actual incorrecta responde 400 (no 401) para no confundirse con
una sesión vencida.

### 9.6 Pendiente
- Fotos de perfil y de productos (requiere decidir dónde se almacenan).
- Notificaciones: job diario + historial + FCM (Fase 6).
- IA: rutinas, alimentación y chat (Fase 7).
- Cierre automático de sesión al vencer el token (hoy se muestra el aviso).

---

## 10. Decisiones de la Fase 5.1

### 10.1 Una persona, varios roles
Quien es recepcionista y además paga clases de boxeo es **una sola persona**
(una cédula, una cuenta, una contraseña) con dos roles. Modelo: `User.role`
es el rol **principal** y `User.rolesAdicionales` (relación muchos a muchos)
guarda el resto. Invariante: si la persona tiene algún rol de personal, el
principal es de personal y `MIEMBRO` va como adicional (así la app
administrativa la reconoce). El JWT lleva `role` (principal) y `roles` (todos);
`RolesGuard` permite el acceso si tiene **alguno** de los roles requeridos.
- Crear personal o miembro con una cédula que ya existe **suma el rol** a la
  cuenta existente (conserva nombre y contraseña) en vez de rechazar; si la
  cuenta estaba desactivada, se **reactiva** con los datos nuevos.
- Dar roles de personal sigue siendo exclusivo del administrador; sumar el
  rol de miembro lo puede hacer también Recepción (no otorga poder alguno).
- "Quitar" es parcial: quitar la condición de miembro o el acceso de personal
  no desactiva la cuenta si la persona conserva la otra condición.
- Los roles viajan en el token: un cambio de roles se refleja cuando la
  persona vuelve a iniciar sesión.

### 10.2 Varios horarios por plan (Boxeo, Karate, MMA)
Un miembro entrena 1, 2 o 3 días a la semana, cada uno en su horario. La
relación Plan–Horario pasó a muchos a muchos (`PlanHorario`). El backend
valida que haya al menos un horario, que existan y estén activos, y que sean
del mismo deporte del plan. `Plan.horarioId` queda solo por compatibilidad
con planes anteriores (se muestra si el plan no tiene horarios nuevos). En
Configuración los horarios se crean **por lote** (varios días, cada uno con
su hora).

### 10.3 Recuperación de contraseña del personal por correo
Flujo: cédula → código de 6 dígitos al correo registrado → código + nueva
contraseña. Seguridad: respuesta idéntica exista o no la cuenta (no revela
qué cédulas están registradas); el código se guarda solo como hash, vence en
15 minutos, sirve una vez y se bloquea tras 5 intentos; máximo 1 envío por
minuto y 5 por hora; aplica solo a cuentas con rol de personal. Sin SMTP
configurado, en desarrollo el código se imprime en la consola del backend.
Extensible a miembros cuando la app móvil tenga la pantalla.

### 10.4 Datos frescos en pantallas
Contabilidad, Miembros y Tienda cargaban una sola vez y conservaban el
resultado mientras la app estuviera abierta (por eso los ingresos nuevos no
aparecían). Ahora sus providers son `autoDispose`: se recargan cada vez que
se entra a la pantalla; Contabilidad y Dashboard tienen además botón
"Actualizar".

### 10.5 Idioma y diagnóstico
- Calendarios y selector de hora en español (`flutter_localizations`).
- Los errores 5xx muestran en modo debug qué petición falló, y el backend
  registra método y ruta de cada error, para ubicar rápido cualquier falla.

---

## 11. Decisiones de la Fase 6 (notificaciones)

- **Generación automática:** `NotificationsService` corre al iniciar el servidor y **cada hora** (`@nestjs/schedule`).
  Recalcula el estado real de los planes y crea los avisos de vencimiento (2 días, 1 día, vencido) según
  Configuración > Notificaciones. Cada aviso tiene una clave única `<plan>:<evento>`, por lo que repetir la
  ejecución nunca duplica avisos y, si el servidor estuvo apagado, los avisos se generan al volver.
- **Avisos por eventos:** pago registrado (plan creado) y día de tiquetera usado / tiquetera agotada. La creación
  de un aviso nunca interrumpe la operación que la origina.
- **Privacidad:** los endpoints `/notifications/me/*` operan siempre sobre el usuario del token.
- **Pendiente — push (FCM):** requiere un proyecto de Firebase propio (`flutterfire configure`, cuenta de servicio en
  el backend, registro del token del dispositivo). Todo el historial y la generación ya existen; el push solo
  añade el aviso en el teléfono con la app cerrada.
