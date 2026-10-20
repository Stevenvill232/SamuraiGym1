import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import configuration from './config/configuration';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    // Variables de entorno disponibles vía ConfigService en toda la app.
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),

    // Habilita tareas programadas (@Cron) — se usará en la Fase 6/7 para el
    // job diario que recalcula vencimientos de planes y dispara FCM.
    ScheduleModule.forRoot(),

    PrismaModule,
    AuthModule,
    UsersModule,

    // ------------------------------------------------------------------
    // Módulos pendientes (se agregan uno por uno en los próximos pasos,
    // cada uno con su propio schema, DTOs, controller, service y tests):
    //   PlansModule        -> Fase 4/6 (Planes y Pagos + Tiqueteras)
    //   AccountingModule   -> Fase 4 (Contabilidad: ingresos/gastos)
    //   StoreModule        -> Fase 4 (Tienda: productos/ventas)
    //   ScheduleAdminModule-> horarios de Boxeo/Karate/MMA
    //   DashboardModule    -> agregados para el Dashboard admin y del miembro
    //   AiModule           -> Fase 7 (rutinas, alimentación, chat)
    //   NotificationsModule-> Fase 6 (FCM + historial)
    //   ConfigModule (dominio) -> Fase de configuración (precios, horarios)
    // ------------------------------------------------------------------
  ],
})
export class AppModule {}
