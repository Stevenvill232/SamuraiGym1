import {
  Injectable,
  Logger,
  NotFoundException,
  OnApplicationBootstrap,
} from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { SettingsService } from '../settings/settings.service';
import { DIA_MS, calcularEstadoPlan } from '../plans/plan-estado.util';

const MESES = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
export const formatearFecha = (d: Date) => `${d.getDate()} de ${MESES[d.getMonth()]}`;

const ETIQUETAS: Record<string, string> = {
  GIMNASIO_SESION: 'plan Gimnasio - Sesión',
  GIMNASIO_QUINCENA: 'plan Gimnasio - Quincena',
  GIMNASIO_MES: 'plan Gimnasio - Mes',
  TIQUETERA_10: 'tiquetera de 10 días',
  TIQUETERA_15: 'tiquetera de 15 días',
  TIQUETERA_20: 'tiquetera de 20 días',
  TIQUETERA_30: 'tiquetera de 30 días',
  BOXEO: 'plan de Boxeo',
  KARATE: 'plan de Karate',
  MMA: 'plan de MMA',
};

/**
 * Avisos al miembro (historial dentro de su app).
 *
 * Los avisos de vencimiento se generan SOLOS: al iniciar el servidor y cada
 * hora. La operación es idempotente (cada aviso tiene una clave única
 * "<plan>:<evento>"), así que correrla muchas veces no repite avisos, y si el
 * servidor estuvo apagado a cierta hora, los avisos se generan al volver.
 * Respeta Configuración > Notificaciones (2 días, 1 día, vencido).
 */
@Injectable()
export class NotificationsService implements OnApplicationBootstrap {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private prisma: PrismaService,
    private settings: SettingsService,
  ) {}

  async onApplicationBootstrap() {
    try {
      const r = await this.generarAvisos();
      this.logger.log(
        `Avisos al iniciar: ${r.nuevas} nuevos, ${r.estadosActualizados} estados de plan actualizados.`,
      );
    } catch (e) {
      this.logger.error(`No se pudieron generar avisos al iniciar: ${String(e)}`);
    }
  }

  @Cron(CronExpression.EVERY_HOUR)
  async jobHorario() {
    try {
      const r = await this.generarAvisos();
      if (r.nuevas > 0 || r.estadosActualizados > 0) {
        this.logger.log(
          `Job de avisos: ${r.nuevas} nuevos, ${r.estadosActualizados} estados actualizados.`,
        );
      }
    } catch (e) {
      this.logger.error(`Falló el job de avisos: ${String(e)}`);
    }
  }

  /** Crea un aviso. Nunca lanza: no debe romper la operación que lo origina. */
  async notificar(
    miembroId: string,
    tipo: string,
    titulo: string,
    mensaje: string,
    claveUnica?: string,
  ) {
    try {
      await this.prisma.historialNotificacion.create({
        data: { miembroId, tipo, titulo, mensaje, claveUnica },
      });
    } catch (e) {
      this.logger.warn(`No se pudo crear el aviso "${titulo}": ${String(e)}`);
    }
  }

  async generarAvisos() {
    const cfg: any = await this.settings.get('notificaciones');
    const ahora = Date.now();

    // 1) Estado real de los planes vigentes (activo / por vencer / vencido).
    const vivos: any[] = await this.prisma.plan.findMany({
      where: { estado: { in: ['ACTIVO', 'POR_VENCER'] as any } },
    });
    let estadosActualizados = 0;
    for (const p of vivos) {
      const estado = calcularEstadoPlan(p);
      if (estado !== p.estado) {
        await this.prisma.plan.update({
          where: { id: p.id },
          data: { estado: estado as any },
        });
        estadosActualizados++;
      }
    }

    // 2) Avisos de vencimiento (ventana: vencidos hace <2 días hasta en 3 días).
    const planes: any[] = await this.prisma.plan.findMany({
      where: {
        fechaVencimiento: {
          gte: new Date(ahora - 2 * DIA_MS),
          lt: new Date(ahora + 3 * DIA_MS),
        },
        miembro: { estado: 'ACTIVO' },
      },
    });

    const data: any[] = [];
    for (const p of planes) {
      // Una tiquetera ya agotada no necesita aviso de vencimiento.
      if (p.diasTotales != null && p.diasUtilizados >= p.diasTotales) continue;

      const dias = Math.ceil((p.fechaVencimiento.getTime() - ahora) / DIA_MS);
      const etiqueta = ETIQUETAS[p.tipoPlan] ?? p.tipoPlan;
      const fecha = formatearFecha(p.fechaVencimiento);
      const tipo = p.diasTotales != null ? 'TIQUETERA' : 'VENCIMIENTO_PLAN';

      let evento: string;
      let titulo: string;
      let mensaje: string;
      if (dias === 2 && cfg.avisarDosDias) {
        evento = '2D';
        titulo = 'Tu plan vence en 2 días';
        mensaje = `Tu ${etiqueta} vence el ${fecha}. Renueva a tiempo para no perder tu acceso.`;
      } else if (dias === 1 && cfg.avisarUnDia) {
        evento = '1D';
        titulo = 'Tu plan vence mañana';
        mensaje = `Tu ${etiqueta} vence mañana (${fecha}). Renueva a tiempo para no perder tu acceso.`;
      } else if (dias <= 0 && dias >= -1 && cfg.avisarVencido) {
        evento = 'VENCIDO';
        titulo = 'Tu plan venció';
        mensaje = `Tu ${etiqueta} venció el ${fecha}. Comunícate con el gimnasio para renovarlo.`;
      } else {
        continue;
      }
      data.push({
        miembroId: p.miembroId,
        tipo,
        titulo,
        mensaje,
        claveUnica: `${p.id}:${evento}`,
      });
    }

    const r: any = data.length
      ? await this.prisma.historialNotificacion.createMany({
          data,
          skipDuplicates: true,
        })
      : { count: 0 };
    return { estadosActualizados, nuevas: r.count as number };
  }

  // ---------------- consultas del propio miembro ----------------

  listar(userId: string) {
    return this.prisma.historialNotificacion.findMany({
      where: { miembroId: userId },
      orderBy: { fechaEnvio: 'desc' },
      take: 50,
    });
  }

  async noLeidas(userId: string) {
    const count = await this.prisma.historialNotificacion.count({
      where: { miembroId: userId, leida: false },
    });
    return { count };
  }

  async marcarLeida(userId: string, id: string) {
    const r: any = await this.prisma.historialNotificacion.updateMany({
      where: { id, miembroId: userId },
      data: { leida: true },
    });
    if (r.count === 0) throw new NotFoundException('Aviso no encontrado');
    return { message: 'Aviso marcado como leído' };
  }

  async marcarTodas(userId: string) {
    await this.prisma.historialNotificacion.updateMany({
      where: { miembroId: userId, leida: false },
      data: { leida: true },
    });
    return { message: 'Avisos marcados como leídos' };
  }
}
