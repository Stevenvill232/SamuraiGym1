import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreatePlanDto,
  QueryPlanDto,
  UsarTiqueteraDto,
  TipoPlanDto,
  EstadoPlanDto,
} from './dto/plan.dto';

const DIA_MS = 24 * 60 * 60 * 1000;
const DEPORTES: TipoPlanDto[] = [
  TipoPlanDto.BOXEO,
  TipoPlanDto.KARATE,
  TipoPlanDto.MMA,
];

@Injectable()
export class PlansService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreatePlanDto, adminId: string) {
    const miembro = await this.prisma.user.findUnique({
      where: { id: dto.miembroId },
    });
    if (!miembro || miembro.estado === 'INACTIVO') {
      throw new NotFoundException('Miembro no encontrado');
    }

    const esDeporte = DEPORTES.includes(dto.tipoPlan);
    if (esDeporte && !dto.horarioId) {
      throw new BadRequestException(
        'Selecciona un horario para Boxeo, Karate o MMA',
      );
    }
    if (dto.horarioId) {
      const horario = await this.prisma.horario.findUnique({
        where: { id: dto.horarioId },
      });
      if (!horario || !horario.estado) {
        throw new NotFoundException('Horario no encontrado o inactivo');
      }
    }

    const fechaInicio = new Date();
    const { fechaVencimiento, diasTotales } = this.calcularVigencia(
      dto.tipoPlan,
      fechaInicio,
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
          metodoPago: dto.metodoPago as any,
          horarioId: dto.horarioId,
          observaciones: dto.observaciones,
        },
      });

      // Todo plan pagado genera su ingreso en la misma transacción: si algo
      // falla, ninguno de los dos queda a medias (ver ARQUITECTURA.md 7.3).
      await tx.ingreso.create({
        data: {
          miembroId: dto.miembroId,
          concepto: `Pago de plan: ${this.etiquetaPlan(dto.tipoPlan)}`,
          tipo: this.tipoIngresoDesde(dto.tipoPlan) as any,
          planId: nuevoPlan.id,
          valor: dto.precio,
          metodoPago: dto.metodoPago as any,
          usuarioAdminId: adminId,
        },
      });

      return nuevoPlan;
    });

    return this.findOne(plan.id);
  }

  async findAll(query: QueryPlanDto) {
    const planes = await this.prisma.plan.findMany({
      where: {
        miembroId: query.miembroId,
        estado: query.estado as any,
      },
      include: {
        miembro: {
          select: {
            id: true,
            nombres: true,
            apellidos: true,
            cedula: true,
            foto: true,
          },
        },
        horario: true,
      },
      orderBy: { fechaCompra: 'desc' },
    });

    return Promise.all(planes.map((p: any) => this.conEstadoActualizado(p)));
  }

  async findOne(id: string) {
    const plan = await this.prisma.plan.findUnique({
      where: { id },
      include: {
        miembro: {
          select: {
            id: true,
            nombres: true,
            apellidos: true,
            cedula: true,
            foto: true,
          },
        },
        horario: true,
        usosTiquetera: { orderBy: { fechaUso: 'desc' } },
      },
    });
    if (!plan) throw new NotFoundException('Plan no encontrado');
    return this.conEstadoActualizado(plan);
  }

  findByMiembro(miembroId: string) {
    return this.findAll({ miembroId } as QueryPlanDto);
  }

  /**
   * Registra el uso de un día de tiquetera. Válido solo si aún quedan
   * días disponibles y la vigencia no ha vencido.
   */
  async usarTiquetera(
    planId: string,
    adminId: string,
    dto: UsarTiqueteraDto,
  ) {
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
      diasUtilizados >= plan.diasTotales
        ? EstadoPlanDto.AGOTADO
        : (plan.estado as EstadoPlanDto);

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
   * Define cuánto dura cada tipo de plan a partir de hoy.
   *
   * Decisión de negocio (documentada también en ARQUITECTURA.md): la
   * vigencia máxima de una tiquetera es el DOBLE de sus días (ej. una
   * tiquetera de 10 días debe usarse dentro de 20 días calendario). Es un
   * valor razonable por defecto; en la Fase de Configuración se hará
   * ajustable sin tocar código.
   */
  private calcularVigencia(tipoPlan: TipoPlanDto, fechaInicio: Date) {
    const desde = fechaInicio.getTime();
    switch (tipoPlan) {
      case TipoPlanDto.GIMNASIO_SESION:
        return { fechaVencimiento: new Date(desde + 1 * DIA_MS), diasTotales: null };
      case TipoPlanDto.GIMNASIO_QUINCENA:
        return { fechaVencimiento: new Date(desde + 15 * DIA_MS), diasTotales: null };
      case TipoPlanDto.GIMNASIO_MES:
        return { fechaVencimiento: new Date(desde + 30 * DIA_MS), diasTotales: null };
      case TipoPlanDto.TIQUETERA_10:
        return { fechaVencimiento: new Date(desde + 20 * DIA_MS), diasTotales: 10 };
      case TipoPlanDto.TIQUETERA_15:
        return { fechaVencimiento: new Date(desde + 30 * DIA_MS), diasTotales: 15 };
      case TipoPlanDto.TIQUETERA_20:
        return { fechaVencimiento: new Date(desde + 40 * DIA_MS), diasTotales: 20 };
      case TipoPlanDto.TIQUETERA_30:
        return { fechaVencimiento: new Date(desde + 60 * DIA_MS), diasTotales: 30 };
      case TipoPlanDto.BOXEO:
      case TipoPlanDto.KARATE:
      case TipoPlanDto.MMA:
        return { fechaVencimiento: new Date(desde + 30 * DIA_MS), diasTotales: null };
    }
  }

  private tipoIngresoDesde(tipoPlan: TipoPlanDto): string {
    if (tipoPlan.startsWith('TIQUETERA')) return 'TIQUETERA';
    return tipoPlan; // GIMNASIO_* / BOXEO / KARATE / MMA coinciden 1:1 con TipoIngreso
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

  /**
   * Recalcula el estado (activo/por vencer/vencido/agotado) a partir de la
   * fecha de vencimiento y los días usados, y lo persiste si cambió. Esto
   * mantiene los datos correctos AUN ANTES de que exista el job diario de
   * la Fase 6 (ver ARQUITECTURA.md 1.5).
   */
  private async conEstadoActualizado<T extends {
    id: string;
    estado: string;
    fechaVencimiento: Date;
    diasTotales: number | null;
    diasUtilizados: number;
  }>(plan: T): Promise<T> {
    const calculado = this.calcularEstado(plan);
    if (calculado !== plan.estado) {
      await this.prisma.plan.update({
        where: { id: plan.id },
        data: { estado: calculado as any },
      });
      return { ...plan, estado: calculado };
    }
    return plan;
  }

  private calcularEstado(plan: {
    fechaVencimiento: Date;
    diasTotales: number | null;
    diasUtilizados: number;
  }): EstadoPlanDto {
    if (plan.diasTotales != null && plan.diasUtilizados >= plan.diasTotales) {
      return EstadoPlanDto.AGOTADO;
    }
    const diasParaVencer = Math.ceil(
      (plan.fechaVencimiento.getTime() - Date.now()) / DIA_MS,
    );
    if (diasParaVencer < 0) return EstadoPlanDto.VENCIDO;
    if (diasParaVencer <= 2) return EstadoPlanDto.POR_VENCER;
    return EstadoPlanDto.ACTIVO;
  }
}
