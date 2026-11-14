import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { calcularEstadoPlan } from '../plans/plan-estado.util';
import { calcularEdad } from '../common/utils/edad.util';

const DIA_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class DashboardService {
  constructor(private prisma: PrismaService) {}

  /**
   * KPIs + alertas de vencimiento para el Dashboard administrativo.
   *
   * Las alertas se calculan SIEMPRE a partir de `fechaVencimiento` en el
   * momento de la consulta (no del campo `estado` guardado), porque hasta
   * que exista el job diario de la Fase 6 ese campo puede estar desfasado.
   * Esto garantiza que el Dashboard nunca muestre una alerta vieja o le
   * falte una nueva, incluso sin el cron.
   */
  async adminResumen() {
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);
    const inicioMes = new Date(hoy.getFullYear(), hoy.getMonth(), 1);
    const finMes = new Date(hoy.getFullYear(), hoy.getMonth() + 1, 1);
    const manana = new Date(hoy.getTime() + DIA_MS);

    // Ventana amplia: desde ayer (vencidos recientes) hasta en 2 días.
    const ventanaInicio = new Date(hoy.getTime() - 1 * DIA_MS);
    const ventanaFin = new Date(hoy.getTime() + 3 * DIA_MS);

    const [miembrosActivos, ingresosHoy, ingresosMes, planesEnVentana] =
      await Promise.all([
        this.prisma.user.count({
          where: { estado: 'ACTIVO', role: { nombre: 'MIEMBRO' } },
        }),
        this.prisma.ingreso.findMany({
          where: { fecha: { gte: hoy, lt: manana } },
          select: { valor: true },
        }),
        this.prisma.ingreso.findMany({
          where: { fecha: { gte: inicioMes, lt: finMes } },
          select: { valor: true },
        }),
        this.prisma.plan.findMany({
          where: { fechaVencimiento: { gte: ventanaInicio, lt: ventanaFin } },
          include: {
            miembro: {
              select: { id: true, nombres: true, apellidos: true, foto: true },
            },
          },
        }),
      ]);

    const gananciaDia = ingresosHoy.reduce((s: number, i: any) => s + Number(i.valor), 0);
    const gananciaMes = ingresosMes.reduce((s: number, i: any) => s + Number(i.valor), 0);

    const alertas = planesEnVentana
      .map((plan: any) => {
        const diasParaVencer = Math.ceil(
          (plan.fechaVencimiento.getTime() - Date.now()) / DIA_MS,
        );

        let severidad: 'DOS_DIAS' | 'UN_DIA' | 'VENCIDA_RECIENTE' | null = null;
        if (diasParaVencer === 2) severidad = 'DOS_DIAS';
        else if (diasParaVencer === 1) severidad = 'UN_DIA';
        else if (diasParaVencer <= 0 && diasParaVencer >= -1) {
          severidad = 'VENCIDA_RECIENTE';
        }
        if (!severidad) return null;

        return {
          planId: plan.id,
          miembroId: plan.miembro.id,
          nombreMiembro: `${plan.miembro.nombres} ${plan.miembro.apellidos}`,
          foto: plan.miembro.foto,
          tipoPlan: plan.tipoPlan,
          fechaVencimiento: plan.fechaVencimiento,
          severidad,
        };
      })
      .filter((a: any): a is NonNullable<typeof a> => a !== null)
      .sort((a: any, b: any) => a.fechaVencimiento.getTime() - b.fechaVencimiento.getTime());

    return { miembrosActivos, gananciaDia, gananciaMes, alertas };
  }

  /**
   * Resumen para el Dashboard de la app de miembros (sección 12): sus planes
   * con el estado REAL de hoy, medidas actuales y lo recomendado para hoy.
   * Se muestran los planes vigentes y los vencidos/agotados de los últimos
   * 30 días; el historial completo vive en "Línea de Plan".
   */
  async miembroResumen(userId: string) {
    const inicioHoy = new Date();
    inicioHoy.setHours(0, 0, 0, 0);

    const [user, planes, ultimoFisico, rutina, recomendacion]: any[] =
      await Promise.all([
        this.prisma.user.findUnique({ where: { id: userId } }),
        this.prisma.plan.findMany({
          where: { miembroId: userId },
          include: { horario: true },
          orderBy: { fechaVencimiento: 'desc' },
        }),
        this.prisma.historialFisico.findFirst({
          where: { miembroId: userId },
          orderBy: { fecha: 'desc' },
        }),
        this.prisma.rutinaGenerada.findFirst({
          where: { miembroId: userId, fecha: { gte: inicioHoy } },
          orderBy: { fecha: 'desc' },
        }),
        this.prisma.recomendacionAlimentaria.findFirst({
          where: { miembroId: userId, fecha: { gte: inicioHoy } },
          orderBy: { fecha: 'desc' },
        }),
      ]);

    const hace30Dias = Date.now() - 30 * DIA_MS;
    const planesVisibles = planes
      .map((p: any) => ({ ...p, estado: calcularEstadoPlan(p) }))
      .filter(
        (p: any) =>
          p.estado === 'ACTIVO' ||
          p.estado === 'POR_VENCER' ||
          p.fechaVencimiento.getTime() >= hace30Dias,
      );

    return {
      usuario: user
        ? {
            id: user.id,
            nombres: user.nombres,
            apellidos: user.apellidos,
            foto: user.foto,
            edad: calcularEdad(user.fechaNacimiento),
          }
        : null,
      planes: planesVisibles,
      pesoActual: ultimoFisico?.peso ?? null,
      estaturaActual: ultimoFisico?.estatura ?? null,
      ultimoRegistroFisico: ultimoFisico?.fecha ?? null,
      rutinaDelDia: rutina ?? null,
      recomendacionDelDia: recomendacion ?? null,
    };
  }
}
