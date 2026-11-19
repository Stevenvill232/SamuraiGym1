import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SettingsService } from '../settings/settings.service';
import {
  CreatePlanDto,
  QueryPlanDto,
  UsarTiqueteraDto,
  TipoPlanDto,
} from './dto/plan.dto';
import { DIA_MS, calcularEstadoPlan } from './plan-estado.util';
import { INCLUDE_HORARIOS, aplanarHorarios } from './plan-horarios.util';
import { esMiembro, rolesEfectivos } from '../common/utils/roles.util';

const DEPORTES: TipoPlanDto[] = [
  TipoPlanDto.BOXEO,
  TipoPlanDto.KARATE,
  TipoPlanDto.MMA,
];

const MIEMBRO_SELECT = {
  id: true,
  nombres: true,
  apellidos: true,
  cedula: true,
  foto: true,
};

@Injectable()
export class PlansService {
  constructor(
    private prisma: PrismaService,
    private settings: SettingsService,
  ) {}

  async create(dto: CreatePlanDto, adminId: string) {
    const miembro = await this.prisma.user.findUnique({
      where: { id: dto.miembroId },
      include: { role: true, rolesAdicionales: true },
    });
    if (!miembro || miembro.estado === 'INACTIVO') {
      throw new NotFoundException('Miembro no encontrado');
    }
    if (!esMiembro(rolesEfectivos(miembro))) {
      throw new BadRequestException(
        'Solo se pueden registrar planes a miembros del gimnasio',
      );
    }

    await this.settings.assertMetodoPago(dto.metodoPago);

    const esDeporte = DEPORTES.includes(dto.tipoPlan);
    const horarioIds = Array.from(new Set(dto.horarioIds ?? []));
    if (esDeporte && horarioIds.length === 0) {
      throw new BadRequestException(
        'Selecciona al menos un horario (día y hora) para Boxeo, Karate o MMA',
      );
    }
    if (!esDeporte && horarioIds.length > 0) {
      throw new BadRequestException(
        'Solo los planes de Boxeo, Karate y MMA llevan horarios',
      );
    }
    if (horarioIds.length > 0) {
      const horarios: any[] = await this.prisma.horario.findMany({
        where: { id: { in: horarioIds }, estado: true },
      });
      if (horarios.length !== horarioIds.length) {
        throw new NotFoundException(
          'Alguno de los horarios no existe o está inactivo',
        );
      }
      // Un plan de Boxeo solo puede usar horarios de Boxeo, etc.
      if (horarios.some((h: any) => h.deporte !== dto.tipoPlan)) {
        throw new BadRequestException(
          `Los horarios deben ser de ${this.etiquetaPlan(dto.tipoPlan)}`,
        );
      }
    }

    const factor = await this.settings.get<number>('tiquetera_factor_vigencia');
    const fechaInicio = new Date();
    const { fechaVencimiento, diasTotales } = this.calcularVigencia(
      dto.tipoPlan,
      fechaInicio,
      factor,
    );

    const plan = await this.prisma.$transaction(async (tx: any) => {
      const nuevoPlan = await tx.plan.create({
        data: {
          miembroId: dto.miembroId,
          tipoPlan: dto.tipoPlan as any,
          precio: dto.precio,
          fechaInicio,
          fechaVencimiento,
          diasTotales,
          metodoPago: dto.metodoPago,
          horarios: {
            create: horarioIds.map((horarioId) => ({ horarioId })),
          },
          observaciones: dto.observaciones,
        },
      });

      // Todo plan pagado genera su ingreso en la misma transacción.
      await tx.ingreso.create({
        data: {
          miembroId: dto.miembroId,
          concepto: `Pago de plan: ${this.etiquetaPlan(dto.tipoPlan)}`,
          tipo: this.tipoIngresoDesde(dto.tipoPlan) as any,
          planId: nuevoPlan.id,
          valor: dto.precio,
          metodoPago: dto.metodoPago,
          usuarioAdminId: adminId,
        },
      });

      return nuevoPlan;
    });

    return this.findOne(plan.id);
  }

  async findAll(query: QueryPlanDto, incluirUsos = false) {
    const planes = await this.prisma.plan.findMany({
      where: {
        miembroId: query.miembroId,
        estado: query.estado as any,
      },
      include: {
        miembro: { select: MIEMBRO_SELECT },
        ...INCLUDE_HORARIOS,
        ...(incluirUsos
          ? { usosTiquetera: { orderBy: { fechaUso: 'asc' } } }
          : {}),
      },
      orderBy: { fechaCompra: 'desc' },
    });

    return Promise.all(
      planes.map(async (p: any) =>
        aplanarHorarios(await this.conEstadoActualizado(p)),
      ),
    );
  }

  async findOne(id: string) {
    const plan = await this.prisma.plan.findUnique({
      where: { id },
      include: {
        miembro: { select: MIEMBRO_SELECT },
        ...INCLUDE_HORARIOS,
        usosTiquetera: { orderBy: { fechaUso: 'desc' } },
      },
    });
    if (!plan) throw new NotFoundException('Plan no encontrado');
    return aplanarHorarios(await this.conEstadoActualizado(plan));
  }

  /** Planes del propio miembro, con el historial de días de tiquetera. */
  findByMiembro(miembroId: string) {
    return this.findAll({ miembroId } as QueryPlanDto, true);
  }

  async usarTiquetera(planId: string, adminId: string, dto: UsarTiqueteraDto) {
    const plan = await this.prisma.plan.findUnique({ where: { id: planId } });
    if (!plan) throw new NotFoundException('Plan no encontrado');

    if (plan.diasTotales == null) {
      throw new BadRequestException('Este plan no es una tiquetera');
    }
    if (plan.diasUtilizados >= plan.diasTotales) {
      throw new BadRequestException('Esta tiquetera ya está agotada');
    }
    if (new Date() > plan.fechaVencimiento) {
      throw new BadRequestException('Esta tiquetera ya venció');
    }

    const diasUtilizados = plan.diasUtilizados + 1;
    const nuevoEstado =
      diasUtilizados >= plan.diasTotales ? 'AGOTADO' : plan.estado;

    await this.prisma.$transaction([
      this.prisma.usoTiquetera.create({
        data: {
          planId,
          registradoPorId: adminId,
          observacion: dto.observacion,
        },
      }),
      this.prisma.plan.update({
        where: { id: planId },
        data: { diasUtilizados, estado: nuevoEstado as any },
      }),
    ]);

    return this.findOne(planId);
  }

  /**
   * Vigencia de cada tipo de plan a partir de hoy. El factor de las
   * tiqueteras (días x factor) es configurable por el administrador.
   */
  private calcularVigencia(
    tipoPlan: TipoPlanDto,
    fechaInicio: Date,
    factorTiquetera: number,
  ): { fechaVencimiento: Date; diasTotales: number | null } {
    const desde = fechaInicio.getTime();
    const en = (dias: number) => new Date(desde + dias * DIA_MS);

    switch (tipoPlan) {
      case TipoPlanDto.GIMNASIO_SESION:
        return { fechaVencimiento: en(1), diasTotales: null };
      case TipoPlanDto.GIMNASIO_QUINCENA:
        return { fechaVencimiento: en(15), diasTotales: null };
      case TipoPlanDto.GIMNASIO_MES:
      case TipoPlanDto.BOXEO:
      case TipoPlanDto.KARATE:
      case TipoPlanDto.MMA:
        return { fechaVencimiento: en(30), diasTotales: null };
      default: {
        // TIQUETERA_10 / 15 / 20 / 30
        const dias = Number(String(tipoPlan).split('_')[1]);
        return {
          fechaVencimiento: en(Math.round(dias * factorTiquetera)),
          diasTotales: dias,
        };
      }
    }
  }

  private tipoIngresoDesde(tipoPlan: TipoPlanDto): string {
    if (tipoPlan.startsWith('TIQUETERA')) return 'TIQUETERA';
    return tipoPlan;
  }

  private etiquetaPlan(tipoPlan: TipoPlanDto): string {
    const etiquetas: Record<TipoPlanDto, string> = {
      [TipoPlanDto.GIMNASIO_SESION]: 'Gimnasio - Sesión',
      [TipoPlanDto.GIMNASIO_QUINCENA]: 'Gimnasio - Quincena',
      [TipoPlanDto.GIMNASIO_MES]: 'Gimnasio - Mes',
      [TipoPlanDto.TIQUETERA_10]: 'Tiquetera 10 días',
      [TipoPlanDto.TIQUETERA_15]: 'Tiquetera 15 días',
      [TipoPlanDto.TIQUETERA_20]: 'Tiquetera 20 días',
      [TipoPlanDto.TIQUETERA_30]: 'Tiquetera 30 días',
      [TipoPlanDto.BOXEO]: 'Boxeo',
      [TipoPlanDto.KARATE]: 'Karate',
      [TipoPlanDto.MMA]: 'MMA',
    };
    return etiquetas[tipoPlan];
  }

  /** Recalcula y persiste el estado si cambió (ver ARQUITECTURA.md 7.2). */
  private async conEstadoActualizado<
    T extends {
      id: string;
      estado: string;
      fechaVencimiento: Date;
      diasTotales: number | null;
      diasUtilizados: number;
    },
  >(plan: T): Promise<T> {
    const calculado = calcularEstadoPlan(plan);
    if (calculado !== plan.estado) {
      await this.prisma.plan.update({
        where: { id: plan.id },
        data: { estado: calculado as any },
      });
      return { ...plan, estado: calculado };
    }
    return plan;
  }
}
