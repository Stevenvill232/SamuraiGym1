import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import configuration from './config/configuration';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { SchedulesModule } from './schedules/schedules.module';
import { PlansModule } from './plans/plans.module';
import { AccountingModule } from './accounting/accounting.module';
import { StoreModule } from './store/store.module';
import { DashboardModule } from './dashboard/dashboard.module';

@Module({
  imports: [
    // Variables de entorno disponibles vía ConfigService en toda la app.
    ConfigModule.forRoot({ isGlobal: true, load: [configuration] }),

    // Habilita tareas programadas (@Cron) — se usará en la Fase 6 para el
    // job diario que recalcula vencimientos de planes y dispara FCM.
    ScheduleModule.forRoot(),

    PrismaModule,
    AuthModule,
    UsersModule,
    SchedulesModule, // horarios de Boxeo/Karate/MMA
    PlansModule, // Planes, tiqueteras y su ingreso automático
    AccountingModule, // ingresos, gastos y resumen financiero
    StoreModule, // productos y ventas (con descuento de stock atómico)
    DashboardModule, // KPIs + alertas de vencimiento del panel admin

    // ------------------------------------------------------------------
    // Módulos pendientes (mismo patrón que los de arriba):
    //   AiModule            -> Fase 7 (rutinas, alimentación, chat)
    //   NotificationsModule -> Fase 6 (FCM + historial + job diario)
    //   ConfigModule (dominio) -> ajustes editables (precios, categorías)
    // ------------------------------------------------------------------
  ],
})
export class AppModule {}

