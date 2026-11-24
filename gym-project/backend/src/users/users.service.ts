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
import {
  ADMIN,
  MIEMBRO,
  ROLES_PERSONAL,
  esPersonal,
  rolesEfectivos,
} from '../common/utils/roles.util';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { QueryUserDto } from './dto/query-user.dto';

const SALT_ROUNDS = 10;
const INCLUDE_ROLES = { role: true, rolesAdicionales: true };

const esAdmin = (r: AuthenticatedUser) => (r.roles ?? [r.role]).includes(ADMIN);

/** Filtro: personas que tienen cierto rol, como principal o adicional. */
const conRol = (nombre: any) => ({
  OR: [
    { role: { nombre } },
    { rolesAdicionales: { some: { nombre } } },
  ],
});

/**
 * Una MISMA persona (misma cédula) puede ser miembro y personal a la vez:
 * tiene una sola cuenta con varios roles. Así, quien es recepcionista y
 * además paga clases de boxeo no necesita dos cuentas ni dos contraseñas.
 */
@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateUserDto, requester: AuthenticatedUser) {
    // Evita escalada de privilegios: solo un administrador da roles de personal.
    if (dto.role !== MIEMBRO && !esAdmin(requester)) {
      throw new ForbiddenException(
        'Solo un administrador puede crear personal del gimnasio',
      );
    }

    const existente: any = await this.prisma.user.findUnique({
      where: { cedula: dto.cedula },
      include: INCLUDE_ROLES,
    });
    if (existente) return this.agregarRolAPersonaExistente(existente, dto);

    const role = await this.getRolePorNombre(dto.role);
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
      include: INCLUDE_ROLES,
    });

    return { ...this.toResponse(user), yaExistia: false, reactivado: false };
  }

  async findAll(query: QueryUserDto, requester: AuthenticatedUser) {
    const condiciones: any[] = [{ estado: 'ACTIVO' }];

    if (!esAdmin(requester)) {
      // El personal que no es administrador solo ve miembros.
      condiciones.push(conRol(MIEMBRO));
    } else if (query.staff === 'true') {
      condiciones.push(conRol({ not: MIEMBRO }));
    } else if (query.role) {
      condiciones.push(conRol(query.role));
    }

    if (query.search) {
      condiciones.push({
        OR: [
          { cedula: { contains: query.search, mode: 'insensitive' } },
          { nombres: { contains: query.search, mode: 'insensitive' } },
          { apellidos: { contains: query.search, mode: 'insensitive' } },
          { celular: { contains: query.search, mode: 'insensitive' } },
        ],
      });
    }

    const users = await this.prisma.user.findMany({
      where: { AND: condiciones },
      include: INCLUDE_ROLES,
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

    const user = await this.prisma.user.update({
      where: { id },
      data: {
        ...dto,
        fechaNacimiento: dto.fechaNacimiento
          ? new Date(dto.fechaNacimiento)
          : undefined,
      },
      include: INCLUDE_ROLES,
    });
    return this.toResponse(user);
  }

  /** Define los roles de PERSONAL de una persona (conserva si es miembro). */
  async setStaffRoles(id: string, roles: string[], requester: AuthenticatedUser) {
    const target = await this.getRaw(id);
    const actuales = rolesEfectivos(target);
    const solicitados = Array.from(new Set(roles)).filter((r) =>
      ROLES_PERSONAL.includes(r),
    );
    if (solicitados.length === 0) {
      throw new BadRequestException('Debe tener al menos un rol de personal');
    }

    if (actuales.includes(ADMIN) && !solicitados.includes(ADMIN)) {
      if (id === requester.userId) {
        throw new BadRequestException(
          'No puedes quitarte tu propio rol de administrador',
        );
      }
      await this.assertQuedaOtroAdmin(
        id,
        'No puedes quitarle el rol al último administrador',
      );
    }

    const nuevos = [
      ...solicitados,
      ...(actuales.includes(MIEMBRO) ? [MIEMBRO] : []),
    ];
    return this.toResponse(await this.aplicarRoles(id, nuevos));
  }

  /**
   * Desactivación LÓGICA (se conserva el historial de pagos y planes).
   *  - como = 'miembro'  -> quita solo la condición de miembro
   *  - como = 'personal' -> quita solo el acceso de personal
   *  - sin `como`        -> desactiva la cuenta completa
   * Si la persona tiene OTRA condición, la cuenta sigue activa con esa.
   */
  async remove(id: string, requester: AuthenticatedUser, como?: string) {
    const target = await this.getRaw(id);
    const roles = rolesEfectivos(target);

    if (como === 'miembro') {
      if (!roles.includes(MIEMBRO)) {
        throw new BadRequestException('Esta persona no es miembro');
      }
      const restantes = roles.filter((r) => r !== MIEMBRO);
      if (restantes.length === 0) {
        return this.desactivarCuenta(target, requester);
      }
      await this.aplicarRoles(id, restantes);
      return {
        message:
          'Se quitó la condición de miembro. La persona sigue activa como personal.',
      };
    }

    this.assertPuedeGestionar(target, requester);

    if (como === 'personal') {
      const staff = roles.filter((r) => r !== MIEMBRO);
      if (staff.length === 0) {
        throw new BadRequestException('Esta persona no es del personal');
      }
      if (id === requester.userId) {
        throw new BadRequestException(
          'No puedes quitarte tu propio acceso de personal',
        );
      }
      if (staff.includes(ADMIN)) {
        await this.assertQuedaOtroAdmin(
          id,
          'No puedes quitar al último administrador',
        );
      }
      if (roles.includes(MIEMBRO)) {
        await this.aplicarRoles(id, [MIEMBRO]);
        return {
          message:
            'Se quitó el acceso de personal. La persona sigue activa como miembro.',
        };
      }
    }

    return this.desactivarCuenta(target, requester);
  }

  /** Restablecimiento por parte del personal (el usuario olvidó su clave). */
  async resetPassword(id: string, password: string, requester: AuthenticatedUser) {
    const target = await this.getRaw(id);
    this.assertPuedeGestionar(target, requester);

    await this.prisma.user.update({
      where: { id },
      data: { passwordHash: await bcrypt.hash(password, SALT_ROUNDS) },
    });
    return { message: 'Contraseña restablecida correctamente' };
  }

  // ------------------------------------------------------------------ //

  /**
   * La cédula ya existe: en vez de rechazar, se suma el rol a la MISMA
   * persona (o se reactiva si estaba desactivada).
   */
  private async agregarRolAPersonaExistente(existente: any, dto: CreateUserDto) {
    if (existente.estado === 'INACTIVO') {
      const role = await this.getRolePorNombre(dto.role);
      const user = await this.prisma.user.update({
        where: { id: existente.id },
        data: {
          estado: 'ACTIVO',
          nombres: dto.nombres,
          apellidos: dto.apellidos,
          fechaNacimiento: dto.fechaNacimiento
            ? new Date(dto.fechaNacimiento)
            : existente.fechaNacimiento,
          celular: dto.celular ?? existente.celular,
          correo: dto.correo ?? existente.correo,
          direccion: dto.direccion ?? existente.direccion,
          sexo: dto.sexo ?? existente.sexo,
          passwordHash: await bcrypt.hash(dto.password, SALT_ROUNDS),
          roleId: role.id,
          rolesAdicionales: { set: [] },
        },
        include: INCLUDE_ROLES,
      });
      return { ...this.toResponse(user), yaExistia: true, reactivado: true };
    }

    const actuales = rolesEfectivos(existente);
    if (actuales.includes(dto.role)) {
      throw new ConflictException(
        dto.role === MIEMBRO
          ? 'Esta persona ya está registrada como miembro'
          : `Esta persona ya tiene el rol ${dto.role}`,
      );
    }

    const user = await this.aplicarRoles(existente.id, [...actuales, dto.role]);
    return { ...this.toResponse(user), yaExistia: true, reactivado: false };
  }

  /**
   * Fija el conjunto de roles de una persona. Invariante: si tiene algún rol
   * de personal, el rol PRINCIPAL es de personal (así la app administrativa
   * la reconoce) y MIEMBRO queda como adicional.
   */
  private async aplicarRoles(userId: string, deseados: string[]) {
    const unicos = Array.from(new Set(deseados));
    const staff = unicos.filter((r) => r !== MIEMBRO);
    const principal = staff[0] ?? MIEMBRO;
    const adicionales = unicos.filter((r) => r !== principal);

    const roles: any[] = await this.prisma.role.findMany({
      where: { nombre: { in: unicos } },
    });
    const idDe = (nombre: string) => {
      const r = roles.find((x: any) => x.nombre === nombre);
      if (!r) throw new NotFoundException(`El rol "${nombre}" no existe`);
      return r.id as string;
    };

    return this.prisma.user.update({
      where: { id: userId },
      data: {
        roleId: idDe(principal),
        rolesAdicionales: { set: adicionales.map((n) => ({ id: idDe(n) })) },
      },
      include: INCLUDE_ROLES,
    });
  }

  private async desactivarCuenta(target: any, requester: AuthenticatedUser) {
    if (target.id === requester.userId) {
      throw new BadRequestException('No puedes desactivar tu propia cuenta');
    }
    if (rolesEfectivos(target).includes(ADMIN)) {
      await this.assertQuedaOtroAdmin(
        target.id,
        'No puedes desactivar al último administrador',
      );
    }
    await this.prisma.user.update({
      where: { id: target.id },
      data: { estado: 'INACTIVO' },
    });
    return { message: 'Usuario desactivado correctamente' };
  }

  private async getRolePorNombre(nombre: string) {
    const role = await this.prisma.role.findUnique({ where: { nombre } });
    if (!role) throw new NotFoundException(`El rol "${nombre}" no existe`);
    return role;
  }

  private async getRaw(id: string): Promise<any> {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: INCLUDE_ROLES,
    });
    if (!user) throw new NotFoundException('Usuario no encontrado');
    return user;
  }

  /** Solo un ADMINISTRADOR gestiona cuentas con algún rol de personal. */
  private assertPuedeGestionar(target: any, requester: AuthenticatedUser) {
    if (!esAdmin(requester) && esPersonal(rolesEfectivos(target))) {
      throw new ForbiddenException(
        'No tienes permiso para gestionar cuentas del personal',
      );
    }
  }

  private async assertQuedaOtroAdmin(targetId: string, mensaje: string) {
    const otros = await this.prisma.user.count({
      where: {
        AND: [{ id: { not: targetId } }, { estado: 'ACTIVO' }, conRol(ADMIN)],
      },
    });
    if (otros === 0) throw new BadRequestException(mensaje);
  }

  private toResponse(user: any) {
    const { passwordHash, roleId, rolesAdicionales, ...rest } = user;
    return {
      ...rest,
      role: user.role?.nombre,
      roles: rolesEfectivos(user),
      edad: calcularEdad(user.fechaNacimiento),
    };
  }
}
