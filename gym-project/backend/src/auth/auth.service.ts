import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  /**
   * Verifica cédula + contraseña.
   * Se usa un mensaje de error genérico ("credenciales inválidas") para no
   * revelar si el problema fue la cédula o la contraseña (buena práctica de
   * seguridad: no dar pistas a quien intenta adivinar cédulas válidas).
   */
  async validateUser(cedula: string, password: string) {
    const user = await this.prisma.user.findUnique({
      where: { cedula },
      include: { role: true },
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

    const payload = {
      sub: user.id,
      cedula: user.cedula,
      role: user.role.nombre,
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
      },
    };
  }
}
