import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { QueryUserDto } from './dto/query-user.dto';

const SALT_ROUNDS = 10;

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateUserDto) {
    const existente = await this.prisma.user.findUnique({
      where: { cedula: dto.cedula },
    });
    if (existente) {
      // Regla de negocio: cédula duplicada es un error de negocio (409), no
      // un error de servidor.
      throw new ConflictException('Ya existe un usuario con esa cédula');
    }

    const role = await this.prisma.role.findUnique({
      where: { nombre: dto.role },
    });
    if (!role) {
      throw new NotFoundException(`El rol "${dto.role}" no existe`);
    }

    const passwordHash = await bcrypt.hash(dto.password, SALT_ROUNDS);

    const user = await this.prisma.user.create({
      data: {
        cedula: dto.cedula,
        nombres: dto.nombres,
        apellidos: dto.apellidos,
        fechaNacimiento: dto.fechaNacimiento
          ? new Date(dto.fechaNacimiento)
          : null,
        celular: dto.celular,
        correo: dto.correo,
        direccion: dto.direccion,
        foto: dto.foto,
        sexo: dto.sexo,
        passwordHash,
        roleId: role.id,
      },
      include: { role: true },
    });

    return this.toResponse(user);
  }

  async findAll(query: QueryUserDto) {
    const users = await this.prisma.user.findMany({
      where: {
        estado: 'ACTIVO',
        role: query.role ? { nombre: query.role } : undefined,
        OR: query.search
          ? [
              { cedula: { contains: query.search, mode: 'insensitive' } },
              { nombres: { contains: query.search, mode: 'insensitive' } },
              { apellidos: { contains: query.search, mode: 'insensitive' } },
              { celular: { contains: query.search, mode: 'insensitive' } },
            ]
          : undefined,
      },
      include: { role: true },
      orderBy: { fechaRegistro: 'desc' },
    });

    return users.map((u: any) => this.toResponse(u));
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { role: true },
    });
    if (!user) throw new NotFoundException('Usuario no encontrado');
    return this.toResponse(user);
  }

  async update(id: string, dto: UpdateUserDto) {
    await this.findOne(id); // valida existencia (lanza 404 si no existe)

    let roleId: string | undefined;
    if (dto.role) {
      const role = await this.prisma.role.findUnique({
        where: { nombre: dto.role },
      });
      if (!role) throw new NotFoundException(`El rol "${dto.role}" no existe`);
      roleId = role.id;
    }

    const { role: _role, ...rest } = dto;

    const user = await this.prisma.user.update({
      where: { id },
      data: {
        ...rest,
        fechaNacimiento: dto.fechaNacimiento
          ? new Date(dto.fechaNacimiento)
          : undefined,
        roleId,
      },
      include: { role: true },
    });

    return this.toResponse(user);
  }

  /**
   * Eliminación LÓGICA (estado = INACTIVO), nunca DELETE físico.
   * Motivo (regla de negocio explícita del proyecto): no perder el
   * histórico de pagos/contabilidad asociado al miembro.
   */
  async remove(id: string) {
    await this.findOne(id);
    await this.prisma.user.update({
      where: { id },
      data: { estado: 'INACTIVO' },
    });
    return { message: 'Miembro desactivado correctamente' };
  }

  /**
   * Calcula la edad a partir de fechaNacimiento en el momento de la
   * respuesta — nunca se almacena en la base de datos (regla explícita del
   * proyecto: "la edad no debe almacenarse manualmente si puede calcularse").
   */
  private calcularEdad(fechaNacimiento: Date | null): number | null {
    if (!fechaNacimiento) return null;
    const hoy = new Date();
    let edad = hoy.getFullYear() - fechaNacimiento.getFullYear();
    const mesDiff = hoy.getMonth() - fechaNacimiento.getMonth();
    if (
      mesDiff < 0 ||
      (mesDiff === 0 && hoy.getDate() < fechaNacimiento.getDate())
    ) {
      edad--;
    }
    return edad;
  }

  private toResponse(user: any) {
    const { passwordHash, roleId, ...rest } = user;
    return {
      ...rest,
      role: user.role?.nombre,
      edad: this.calcularEdad(user.fechaNacimiento),
    };
  }
}
