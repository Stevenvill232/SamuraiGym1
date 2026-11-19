import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateHorarioDto,
  CreateHorariosBulkDto,
  UpdateHorarioDto,
  QueryHorarioDto,
} from './dto/horario.dto';

@Injectable()
export class SchedulesService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateHorarioDto) {
    this.assertRango(dto.horaInicio, dto.horaFin);
    await this.assertSinDuplicados(dto.deporte, [dto]);
    return this.prisma.horario.create({ data: dto as any });
  }

  /** Varios días/horas de un deporte en una sola operación (atómica). */
  async createBulk(dto: CreateHorariosBulkDto) {
    for (const f of dto.franjas) this.assertRango(f.horaInicio, f.horaFin);
    await this.assertSinDuplicados(dto.deporte, dto.franjas);

    return this.prisma.$transaction(
      dto.franjas.map((f) =>
        this.prisma.horario.create({
          data: {
            deporte: dto.deporte as any,
            dia: f.dia as any,
            horaInicio: f.horaInicio,
            horaFin: f.horaFin,
            cupo: dto.cupo,
          },
        }),
      ),
    );
  }

  findAll(query: QueryHorarioDto) {
    return this.prisma.horario.findMany({
      where: {
        estado: true,
        deporte: query.deporte,
        dia: query.dia as any,
      },
      orderBy: [{ deporte: 'asc' }, { dia: 'asc' }, { horaInicio: 'asc' }],
    });
  }

  async findOne(id: string) {
    const horario = await this.prisma.horario.findUnique({ where: { id } });
    if (!horario) throw new NotFoundException('Horario no encontrado');
    return horario;
  }

  async update(id: string, dto: UpdateHorarioDto) {
    const actual: any = await this.findOne(id);
    this.assertRango(
      dto.horaInicio ?? actual.horaInicio,
      dto.horaFin ?? actual.horaFin,
    );
    return this.prisma.horario.update({ where: { id }, data: dto as any });
  }

  /**
   * Desactivación lógica: un horario con planes asociados no se puede borrar
   * físicamente sin romper esos registros.
   */
  async remove(id: string) {
    await this.findOne(id);
    await this.prisma.horario.update({
      where: { id },
      data: { estado: false },
    });
    return { message: 'Horario desactivado correctamente' };
  }

  // "HH:mm" con cero a la izquierda se puede comparar como texto.
  private assertRango(inicio: string, fin: string) {
    if (fin <= inicio) {
      throw new BadRequestException(
        'La hora de fin debe ser posterior a la de inicio',
      );
    }
  }

  private async assertSinDuplicados(
    deporte: string,
    franjas: { dia: string; horaInicio: string; horaFin: string }[],
  ) {
    const claves = new Set<string>();
    for (const f of franjas) {
      const k = `${f.dia}|${f.horaInicio}|${f.horaFin}`;
      if (claves.has(k)) {
        throw new ConflictException(
          `El horario ${f.dia} ${f.horaInicio}-${f.horaFin} está repetido`,
        );
      }
      claves.add(k);
    }
    const existentes: any[] = await this.prisma.horario.findMany({
      where: { deporte: deporte as any, estado: true },
    });
    for (const e of existentes) {
      if (claves.has(`${e.dia}|${e.horaInicio}|${e.horaFin}`)) {
        throw new ConflictException(
          `Ya existe un horario de ${deporte} el ${e.dia} de ${e.horaInicio} a ${e.horaFin}`,
        );
      }
    }
  }
}
