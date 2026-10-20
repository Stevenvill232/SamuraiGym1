import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateGastoDto, QueryMovimientosDto } from './dto/accounting.dto';

@Injectable()
export class AccountingService {
  constructor(private prisma: PrismaService) {}

  createGasto(dto: CreateGastoDto) {
    return this.prisma.gasto.create({
      data: {
        categoria: dto.categoria as any,
        descripcion: dto.descripcion,
        valor: dto.valor,
        metodoPago: dto.metodoPago as any,
        observacion: dto.observacion,
      },
    });
  }

  findIngresos(query: QueryMovimientosDto) {
    return this.prisma.ingreso.findMany({
      where: this.rangoFechas(query),
      include: {
        miembro: { select: { nombres: true, apellidos: true } },
        usuarioAdmin: { select: { nombres: true, apellidos: true } },
      },
      orderBy: { fecha: 'desc' },
    });
  }

  findGastos(query: QueryMovimientosDto) {
    return this.prisma.gasto.findMany({
      where: this.rangoFechas(query),
      orderBy: { fecha: 'desc' },
    });
  }

  /**
   * Resumen financiero del rango de fechas dado (por defecto, el mes en
   * curso). Sirve tanto para la pantalla de Contabilidad como, filtrando por
   * el día de hoy, para las cifras del Dashboard.
   */
  async resumen(query: QueryMovimientosDto) {
    const where = this.rangoFechas(query);

    const [ingresos, gastos] = await Promise.all([
      this.prisma.ingreso.findMany({ where, select: { valor: true, tipo: true } }),
      this.prisma.gasto.findMany({ where, select: { valor: true, categoria: true } }),
    ]);

    const totalIngresos = ingresos.reduce((sum: number, i: any) => sum + Number(i.valor), 0);
    const totalGastos = gastos.reduce((sum: number, g: any) => sum + Number(g.valor), 0);

    const ingresosPorTipo: Record<string, number> = {};
    for (const i of ingresos) {
      ingresosPorTipo[i.tipo] = (ingresosPorTipo[i.tipo] ?? 0) + Number(i.valor);
    }

    const gastosPorCategoria: Record<string, number> = {};
    for (const g of gastos) {
      gastosPorCategoria[g.categoria] =
        (gastosPorCategoria[g.categoria] ?? 0) + Number(g.valor);
    }

    return {
      totalIngresos,
      totalGastos,
      utilidad: totalIngresos - totalGastos,
      cantidadIngresos: ingresos.length,
      cantidadGastos: gastos.length,
      ingresosPorTipo,
      gastosPorCategoria,
    };
  }

  private rangoFechas(query: QueryMovimientosDto) {
    if (!query.desde && !query.hasta) return {};
    return {
      fecha: {
        gte: query.desde ? new Date(query.desde) : undefined,
        // +1 día para que "hasta" sea inclusivo de todo ese día calendario.
        lte: query.hasta
          ? new Date(new Date(query.hasta).getTime() + 24 * 60 * 60 * 1000 - 1)
          : undefined,
      },
    };
  }
}
