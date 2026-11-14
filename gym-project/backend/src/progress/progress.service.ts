import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateRegistroFisicoDto } from './dto/progress.dto';

const DIA_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class ProgressService {
  constructor(private prisma: PrismaService) {}

  list(userId: string) {
    return this.prisma.historialFisico.findMany({
      where: { miembroId: userId },
      orderBy: { fecha: 'desc' },
    });
  }

  async add(userId: string, dto: CreateRegistroFisicoDto) {
    const fecha = dto.fecha ? new Date(dto.fecha) : new Date();
    if (fecha.getTime() > Date.now() + DIA_MS) {
      throw new BadRequestException('La fecha del registro no puede ser futura');
    }
    return this.prisma.historialFisico.create({
      data: {
        miembroId: userId,
        peso: dto.peso,
        estatura: dto.estatura,
        fecha,
      },
    });
  }

  /** Solo se puede borrar un registro propio (corregir un error de digitación). */
  async remove(userId: string, id: string) {
    const registro = await this.prisma.historialFisico.findUnique({
      where: { id },
    });
    if (!registro || registro.miembroId !== userId) {
      throw new NotFoundException('Registro no encontrado');
    }
    await this.prisma.historialFisico.delete({ where: { id } });
    return { message: 'Registro eliminado' };
  }
}
