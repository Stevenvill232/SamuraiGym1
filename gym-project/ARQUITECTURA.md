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

**Implementados (Fase 3):**

| Método | Ruta | Rol requerido | Descripción |
|---|---|---|---|
| POST | `/auth/login` | público | Login con cédula + contraseña |
| GET | `/auth/me` | cualquiera autenticado | Datos del token actual |
| POST | `/users` | ADMIN, RECEPCION | Crear miembro/usuario |
| GET | `/users` | ADMIN, RECEPCION, ENTRENADOR | Listar/buscar |
| GET | `/users/:id` | ADMIN, RECEPCION, ENTRENADOR | Detalle |
| PATCH | `/users/:id` | ADMIN, RECEPCION | Editar |
| DELETE | `/users/:id` | ADMIN | Desactivar (borrado lógico) |

**Planeados por fase** (mismo patrón CRUD + reglas propias):
- Fase 4: `/plans`, `/plans/:id/usar-tiquetera`, `/accounting/ingresos`,
  `/accounting/gastos`, `/store/productos`, `/store/ventas`.
- Fase 5: `/dashboard/admin`, `/dashboard/miembro`.
- Fase 6: `/notifications`, job interno (no expuesto) que recalcula estados.
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
1. Job diario (Fase 6, `@Cron`) recorre planes activos y recalcula
   `estado` según `fechaVencimiento` y, si es tiquetera, días restantes.
2. Al pasar a "por vencer" (2 días) o "vence mañana" (1 día), se crea un
   `HistorialNotificacion` y se dispara FCM al miembro.
3. El Dashboard admin lee siempre el estado ya calculado, coloreado según la
   regla exacta del proyecto (naranja=2 días, rojo=1 día, gris=vencido
   reciente).

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
| 4 | Planes y Pagos, Tiqueteras, Contabilidad, Tienda (backend + UI) | En curso |
| 5 | App de miembros completa (plan, perfil, progreso) | Pendiente |
| 6 | Notificaciones push + job diario de vencimientos | Pendiente |
| 7 | Integración de IA (rutina, alimentación, chat) | Pendiente |
| 8 | Gráficos avanzados, pulido visual, pruebas, empaquetado final | Pendiente |

Cada módulo nuevo se construirá siguiendo el mismo patrón ya usado en
`users/` (backend) y en las pantallas ya creadas (Flutter), para que el
código se sienta como un solo sistema y no como piezas sueltas.
