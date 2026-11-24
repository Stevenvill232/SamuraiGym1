import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { rolesEfectivos } from '../common/utils/roles.util';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  /**
   * Verifica cédula + contraseña. Mensaje genérico para no revelar si falló
   * la cédula o la contraseña.
   */
  async validateUser(cedula: string, password: string) {
    const user = await this.prisma.user.findUnique({
      where: { cedula },
      include: { role: true, rolesAdicionales: true },
    });

    if (!user || user.estado === 'INACTIVO') {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    const passwordOk = await bcrypt.compare(password, user.passwordHash);
    if (!passwordOk) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    return user;
  }

  async login(cedula: string, password: string) {
    const user = await this.validateUser(cedula, password);
    const roles = rolesEfectivos(user);

    const payload = {
      sub: user.id,
      cedula: user.cedula,
      role: user.role.nombre, // rol principal
      roles, // todos los roles de la persona
    };

    return {
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        cedula: user.cedula,
        nombres: user.nombres,
        apellidos: user.apellidos,
        foto: user.foto,
        role: user.role.nombre,
        roles,
      },
    };
  }

  /**
   * Cambio de contraseña del propio usuario. Si la actual es incorrecta se
   * responde 400 (no 401) para que la app no lo confunda con una sesión
   * vencida.
   */
  async cambiarPassword(userId: string, actual: string, nueva: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException();

    const ok = await bcrypt.compare(actual, user.passwordHash);
    if (!ok) {
      throw new BadRequestException('La contraseña actual es incorrecta');
    }
    if (actual === nueva) {
      throw new BadRequestException(
        'La nueva contraseña debe ser distinta a la actual',
      );
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash: await bcrypt.hash(nueva, 10) },
    });
    return { message: 'Contraseña actualizada correctamente' };
  }
}
