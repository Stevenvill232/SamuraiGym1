import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateHorarioDto,
  UpdateHorarioDto,
  QueryHorarioDto,
} from './dto/horario.dto';

@Injectable()
export class SchedulesService {
  constructor(private prisma: PrismaService) {}

  create(dto: CreateHorarioDto) {
    return this.prisma.horario.create({ data: dto as any });
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
    await this.findOne(id);
    return this.prisma.horario.update({ where: { id }, data: dto as any });
  }

  /**
   * Desactivación lógica: un horario con planes históricos asociados no se
   * puede borrar físicamente sin romper esos registros.
   */
  async remove(id: string) {
    await this.findOne(id);
    await this.prisma.horario.update({
      where: { id },
      data: { estado: false },
    });
    return { message: 'Horario desactivado correctamente' };
  }
}
