import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../common/decorators/current-user.decorator';
import { calcularEdad } from '../common/utils/edad.util';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { QueryUserDto } from './dto/query-user.dto';

const SALT_ROUNDS = 10;
const ADMIN = 'ADMINISTRADOR';
const MIEMBRO = 'MIEMBRO';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateUserDto, requester: AuthenticatedUser) {
    // Evita escalada de privilegios: Recepción no puede crear administradores.
    if (dto.role !== MIEMBRO && requester.role !== ADMIN) {
      throw new ForbiddenException(
        'Solo un administrador puede crear personal del gimnasio',
      );
    }

    const existente = await this.prisma.user.findUnique({
      where: { cedula: dto.cedula },
    });
    if (existente) {
      throw new ConflictException('Ya existe un usuario con esa cédula');
    }

    const role = await this.prisma.role.findUnique({
      where: { nombre: dto.role },
    });
    if (!role) throw new NotFoundException(`El rol "${dto.role}" no existe`);

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

  async findAll(query: QueryUserDto, requester: AuthenticatedUser) {
    const esAdmin = requester.role === ADMIN;

    // El personal que no es administrador solo ve miembros.
    let filtroRol: any;
    if (!esAdmin) filtroRol = { nombre: MIEMBRO };
    else if (query.staff === 'true') filtroRol = { nombre: { not: MIEMBRO } };
    else if (query.role) filtroRol = { nombre: query.role };

    const users = await this.prisma.user.findMany({
      where: {
        estado: 'ACTIVO',
        role: filtroRol,
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
    return this.toResponse(await this.getRaw(id));
  }

  async update(id: string, dto: UpdateUserDto, requester: AuthenticatedUser) {
    const target = await this.getRaw(id);
    this.assertPuedeGestionar(target, requester);

    let roleId: string | undefined;
    if (dto.role !== undefined && dto.role !== target.role.nombre) {
      if (requester.role !== ADMIN) {
        throw new ForbiddenException('Solo un administrador puede cambiar roles');
      }
      const role = await this.prisma.role.findUnique({
        where: { nombre: dto.role },
      });
      if (!role) throw new NotFoundException(`El rol "${dto.role}" no existe`);
      if (target.role.nombre === ADMIN) {
        await this.assertQuedaOtroAdmin(
          target.id,
          'No puedes quitarle el rol al último administrador',
        );
      }
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

  /** Eliminación LÓGICA: se conserva el historial de pagos y planes. */
  async remove(id: string, requester: AuthenticatedUser) {
    const target = await this.getRaw(id);
    this.assertPuedeGestionar(target, requester);

    if (id === requester.userId) {
      throw new BadRequestException('No puedes desactivar tu propia cuenta');
    }
    if (target.role.nombre === ADMIN) {
      await this.assertQuedaOtroAdmin(
        target.id,
        'No puedes desactivar al último administrador',
      );
    }

    await this.prisma.user.update({
      where: { id },
      data: { estado: 'INACTIVO' },
    });
    return { message: 'Usuario desactivado correctamente' };
  }

  /** Restablecimiento por parte del personal (el miembro olvidó su clave). */
  async resetPassword(
    id: string,
    password: string,
    requester: AuthenticatedUser,
  ) {
    const target = await this.getRaw(id);
    this.assertPuedeGestionar(target, requester);

    await this.prisma.user.update({
      where: { id },
      data: { passwordHash: await bcrypt.hash(password, SALT_ROUNDS) },
    });
    return { message: 'Contraseña restablecida correctamente' };
  }

  // ------------------------------------------------------------------ //

  private async getRaw(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: { role: true },
    });
    if (!user) throw new NotFoundException('Usuario no encontrado');
    return user;
  }

  /** Solo un ADMINISTRADOR gestiona cuentas de personal; los demás, miembros. */
  private assertPuedeGestionar(target: any, requester: AuthenticatedUser) {
    if (requester.role !== ADMIN && target.role.nombre !== MIEMBRO) {
      throw new ForbiddenException(
        'No tienes permiso para gestionar cuentas del personal',
      );
    }
  }

  private async assertQuedaOtroAdmin(targetId: string, mensaje: string) {
    const otros = await this.prisma.user.count({
      where: {
        id: { not: targetId },
        estado: 'ACTIVO',
        role: { nombre: ADMIN },
      },
    });
    if (otros === 0) throw new BadRequestException(mensaje);
  }

  private toResponse(user: any) {
    const { passwordHash, roleId, ...rest } = user;
    return {
      ...rest,
      role: user.role?.nombre,
      edad: calcularEdad(user.fechaNacimiento),
    };
  }
}
