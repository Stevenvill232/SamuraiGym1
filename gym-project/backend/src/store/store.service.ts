import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateProductoDto,
  UpdateProductoDto,
  CreateVentaDto,
} from './dto/store.dto';

@Injectable()
export class StoreService {
  constructor(private prisma: PrismaService) {}

  // ---------------------------------------------------------------- //
  // Productos
  // ---------------------------------------------------------------- //

  createProducto(dto: CreateProductoDto) {
    return this.prisma.producto.create({
      data: { ...dto, stockMinimo: dto.stockMinimo ?? 5 },
    });
  }

  findAllProductos() {
    return this.prisma.producto.findMany({
      where: { estado: true },
      orderBy: { nombre: 'asc' },
    });
  }

  async findOneProducto(id: string) {
    const producto = await this.prisma.producto.findUnique({ where: { id } });
    if (!producto) throw new NotFoundException('Producto no encontrado');
    return producto;
  }

  async updateProducto(id: string, dto: UpdateProductoDto) {
    await this.findOneProducto(id);
    return this.prisma.producto.update({ where: { id }, data: dto });
  }

  async removeProducto(id: string) {
    await this.findOneProducto(id);
    await this.prisma.producto.update({
      where: { id },
      data: { estado: false },
    });
    return { message: 'Producto desactivado correctamente' };
  }

  /** Productos cuyo stock ya llegó (o bajó) del mínimo configurado. */
  async productosStockBajo() {
    const productos = await this.prisma.producto.findMany({
      where: { estado: true },
      orderBy: { stock: 'asc' },
    });
    // Prisma no soporta comparar dos columnas entre sí en el `where`, así
    // que se filtra en memoria; la tabla de productos de un gimnasio es
    // pequeña, así que no hay problema de rendimiento.
    return productos.filter((p: any) => p.stock <= p.stockMinimo);
  }

  // ---------------------------------------------------------------- //
  // Ventas
  // ---------------------------------------------------------------- //

  /**
   * Transacción única: valida stock de TODOS los items, descuenta stock,
   * crea la venta con su detalle, y genera el ingreso contable
   * correspondiente. Si cualquier producto no tiene stock suficiente, se
   * revierte todo (nada de stock descontado a medias) — ver
   * ARQUITECTURA.md 7.4.
   */
  async crearVenta(dto: CreateVentaDto, adminId: string) {
    return this.prisma.$transaction(async (tx: any) => {
      let total = 0;
      const detalles: {
        productoId: string;
        cantidad: number;
        precioUnitario: number;
        subtotal: number;
      }[] = [];

      for (const item of dto.items) {
        const producto = await tx.producto.findUnique({
          where: { id: item.productoId },
        });
        if (!producto || !producto.estado) {
          throw new NotFoundException(
            `Producto ${item.productoId} no encontrado`,
          );
        }
        if (producto.stock < item.cantidad) {
          throw new BadRequestException(
            `Stock insuficiente de "${producto.nombre}" (disponible: ${producto.stock}, solicitado: ${item.cantidad})`,
          );
        }

        const precioUnitario = Number(producto.precioVenta);
        const subtotal = precioUnitario * item.cantidad;
        total += subtotal;
        detalles.push({
          productoId: item.productoId,
          cantidad: item.cantidad,
          precioUnitario,
          subtotal,
        });

        await tx.producto.update({
          where: { id: item.productoId },
          data: { stock: { decrement: item.cantidad } },
        });
      }

      const venta = await tx.venta.create({
        data: {
          total,
          metodoPago: dto.metodoPago as any,
          usuarioId: adminId,
          detalles: { create: detalles },
        },
        include: { detalles: { include: { producto: true } } },
      });

      await tx.ingreso.create({
        data: {
          concepto: `Venta de tienda #${venta.id.slice(0, 8)}`,
          tipo: 'PRODUCTO',
          ventaId: venta.id,
          valor: total,
          metodoPago: dto.metodoPago as any,
          usuarioAdminId: adminId,
        },
      });

      return venta;
    });
  }

  findAllVentas() {
    return this.prisma.venta.findMany({
      include: { detalles: { include: { producto: true } } },
      orderBy: { fecha: 'desc' },
    });
  }
}
