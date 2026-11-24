import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { randomInt } from 'crypto';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { MailService } from '../mail/mail.service';
import { esPersonal, rolesEfectivos } from '../common/utils/roles.util';

const VIGENCIA_MIN = 15;
const MAX_INTENTOS = 5;
const ESPERA_ENTRE_ENVIOS_MS = 60 * 1000;
const MAX_ENVIOS_POR_HORA = 5;

/**
 * Recuperación de contraseña del PERSONAL (app administrativa) por correo.
 *
 * Seguridad:
 *  - La respuesta de "solicitar" es siempre la misma exista o no la cuenta,
 *    para que nadie pueda averiguar qué cédulas están registradas.
 *  - El código (6 dígitos) se guarda solo como hash, vence en 15 minutos,
 *    sirve una vez y se bloquea tras 5 intentos fallidos.
 *  - Máximo 1 envío por minuto y 5 por hora por cuenta.
 */
@Injectable()
export class PasswordResetService {
  private readonly logger = new Logger(PasswordResetService.name);

  constructor(
    private prisma: PrismaService,
    private mail: MailService,
  ) {}

  async solicitar(cedula: string) {
    const respuesta = {
      message:
        'Si la cédula corresponde a una cuenta del personal con correo registrado, te enviamos un código de 6 dígitos. Vence en 15 minutos.',
    };

    const user: any = await this.prisma.user.findUnique({
      where: { cedula },
      include: { role: true, rolesAdicionales: true },
    });
    if (
      !user ||
      user.estado === 'INACTIVO' ||
      !esPersonal(rolesEfectivos(user)) ||
      !user.correo
    ) {
      this.logger.warn(
        `Recuperación solicitada para ${cedula}: no se envía (sin cuenta de personal activa con correo).`,
      );
      return respuesta;
    }

    const haceUnaHora = new Date(Date.now() - 60 * 60 * 1000);
    const recientes: any[] = await this.prisma.passwordResetToken.findMany({
      where: { userId: user.id, createdAt: { gte: haceUnaHora } },
      orderBy: { createdAt: 'desc' },
    });
    const muyReciente =
      recientes[0] &&
      Date.now() - recientes[0].createdAt.getTime() < ESPERA_ENTRE_ENVIOS_MS;
    if (muyReciente || recientes.length >= MAX_ENVIOS_POR_HORA) {
      this.logger.warn(`Recuperación de ${cedula} limitada por frecuencia.`);
      return respuesta;
    }

    const codigo = String(randomInt(0, 1_000_000)).padStart(6, '0');
    const codeHash = await bcrypt.hash(codigo, 8);

    // Un solo código vigente por cuenta: los anteriores quedan anulados.
    await this.prisma.passwordResetToken.updateMany({
      where: { userId: user.id, usedAt: null },
      data: { usedAt: new Date() },
    });
    await this.prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        codeHash,
        expiresAt: new Date(Date.now() + VIGENCIA_MIN * 60 * 1000),
      },
    });

    await this.mail.enviarCodigoRecuperacion(user.correo, user.nombres, codigo);
    return respuesta;
  }

  async confirmar(cedula: string, codigo: string, nueva: string) {
    const invalido = () =>
      new BadRequestException('Código inválido o vencido. Solicita uno nuevo.');

    const user: any = await this.prisma.user.findUnique({
      where: { cedula },
      include: { role: true, rolesAdicionales: true },
    });
    if (!user || user.estado === 'INACTIVO' || !esPersonal(rolesEfectivos(user))) {
      throw invalido();
    }

    const token: any = await this.prisma.passwordResetToken.findFirst({
      where: { userId: user.id, usedAt: null, expiresAt: { gt: new Date() } },
      orderBy: { createdAt: 'desc' },
    });
    if (!token || token.attempts >= MAX_INTENTOS) throw invalido();

    const ok = await bcrypt.compare(codigo, token.codeHash);
    if (!ok) {
      await this.prisma.passwordResetToken.update({
        where: { id: token.id },
        data: { attempts: { increment: 1 } },
      });
      throw invalido();
    }

    const passwordHash = await bcrypt.hash(nueva, 10);
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: user.id },
        data: { passwordHash },
      }),
      this.prisma.passwordResetToken.updateMany({
        where: { userId: user.id, usedAt: null },
        data: { usedAt: new Date() },
      }),
    ]);
    return { message: 'Contraseña actualizada. Ya puedes iniciar sesión.' };
  }
}
