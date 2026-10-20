# Sistema de Gestión de Gimnasio

Monorepo con el backend y las dos apps Flutter del proyecto. Lee también
`ARQUITECTURA.md` (decisiones de diseño, inconsistencias detectadas y
resueltas, flujos de negocio, endpoints y plan de fases).

```
gym-project/
├── backend/         # API REST (NestJS + Prisma + PostgreSQL)
├── shared_models/   # Paquete Dart compartido por las 2 apps Flutter
├── admin_app/       # App de escritorio (Flutter Desktop / Windows)
└── member_app/      # App móvil de miembros (Flutter Android/iOS)
```

#### 0. Requisitos

- Node.js 20+ y npm
- Firebase en la nube
- Flutter con soporte Desktop habilitado:
  `flutter config --enable-windows-desktop`

## 1. Backend

```bash
cd backend
cp .env.example .env
# Edita .env: pon tu DATABASE_URL real y un JWT_SECRET propio
npm install
npx prisma migrate dev --name init   # crea las tablas
npx prisma db seed                    # crea roles + admin inicial
npm run start:dev
```

Con esto el backend queda en `http://localhost:3000/api`, con documentación
interactiva en `http://localhost:3000/api/docs` (Swagger).

Usuario administrador creado por el seed:
- Cédula: `0000000000`
- Contraseña: `Admin123!` 

## 2. App administrativa (Flutter Desktop)

Esta carpeta (`admin_app`) ya tiene el código; solo te falta el "esqueleto"
nativo que genera `flutter create` (carpetas `windows/`, `android/`, etc. si
las necesitas). La forma más simple:

```bash
# Desde la carpeta que contiene a admin_app/, member_app/, shared_models/:
cd admin_app
flutter create --platforms=windows,macos,linux .
flutter pub get
flutter run -d windows
```

`flutter create .` sobre una carpeta que YA tiene `lib/` y `pubspec.yaml` no
los sobrescribe: solo agrega lo que falta (las carpetas nativas). Es
seguro ejecutarlo.

## 3. App de miembros (Flutter móvil)

```bash
cd member_app
flutter create --platforms=android,ios .
flutter pub get
flutter run
```

Antes de probar en un dispositivo/emulador, revisa `kApiBaseUrl` en
`member_app/lib/providers/auth_provider.dart`:
- Emulador Android: `http://10.0.2.2:3000/api`
- Dispositivo físico en tu misma red: `http://TU_IP_LOCAL:3000/api`
- iOS simulator: `http://localhost:3000/api` funciona igual que en el host

## 4. Notificaciones push (Firebase) — cuando llegues a esa fase

1. Crea un proyecto en Firebase Console.
2. `dart pub global activate flutterfire_cli`
3. Dentro de `member_app/`: `flutterfire configure`
4. Descomenta `firebase_core` y `firebase_messaging` en
   `member_app/pubspec.yaml`.
5. En el backend, coloca el JSON de la cuenta de servicio y apunta
   `FCM_SERVICE_ACCOUNT_PATH` en `.env`.

La app admin (Flutter Desktop/Windows) NO recibe push vía FCM: el plugin
oficial no soporta Windows. Ver `ARQUITECTURA.md` → "Inconsistencias
detectadas" para la solución adoptada.

## 5. IA (rutinas, alimentación, chat)

La API key del proveedor de IA (Anthropic/OpenAI) vive **solo** en
`backend/.env` (`AI_API_KEY`). Flutter nunca la ve ni la llama directamente:
siempre pasa por el backend. Esto se implementa en la Fase 7.

## Estado actual del proyecto

✅ Fase 1 — Arquitectura general (este documento + ARQUITECTURA.md)
✅ Fase 2 — Modelo de base de datos completo (`backend/prisma/schema.prisma`)
✅ Fase 3 — Backend base: auth (JWT + roles) + módulo de Miembros (CRUD real)
🚧 Fase 4 — Planes y Pagos, Contabilidad, Tienda (estructura de pantallas
   lista en ambas apps; endpoints backend pendientes)
⏳ Fase 5 — Resto de la app de miembros (línea de plan, perfil, progreso)
⏳ Fase 6 — Notificaciones push (FCM) + job diario de vencimientos
⏳ Fase 7 — Integración de IA (rutinas, alimentación, chat)
⏳ Fase 8 — Pulido, gráficos avanzados, pruebas

Cada vez que avancemos una fase, actualiza esta lista.
