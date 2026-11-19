import {
  Injectable,
  Logger,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

const escapar = (t: string) =>
  t
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

// Quita espacios y comillas sobrantes que suelen quedar al editar el .env.
const limpiar = (v?: string) => (v ?? '').trim().replace(/^["']|["']$/g, '').trim();

/**
 * Envío de correos (hoy: código de recuperación de contraseña).
 *
 * Lee SMTP_HOST, SMTP_PORT, SMTP_SECURE, SMTP_USER, SMTP_PASS y MAIL_FROM
 * directamente del entorno (backend/.env). IMPORTANTE: el .env solo se lee al
 * ARRANCAR el servidor; si lo editas hay que detenerlo y volver a iniciarlo.
 */
@Injectable()
export class MailService implements OnModuleInit {
  private readonly logger = new Logger(MailService.name);
  private transporter: nodemailer.Transporter | null = null;
  private from: string;

  constructor(private config: ConfigService) {
    const host = limpiar(config.get<string>('SMTP_HOST'));
    const port = parseInt(limpiar(config.get<string>('SMTP_PORT')) || '587', 10);
    const secure =
      limpiar(config.get<string>('SMTP_SECURE')).toLowerCase() === 'true' ||
      port === 465;
    const user = limpiar(config.get<string>('SMTP_USER'));
    let pass = limpiar(config.get<string>('SMTP_PASS'));
    // Google muestra las contraseñas de aplicación en bloques con espacios;
    // los espacios NO son parte de la clave.
    if (host.includes('gmail')) pass = pass.replace(/\s+/g, '');

    this.from =
      limpiar(config.get<string>('MAIL_FROM')) ||
      (user ? `Gym Admin <${user}>` : 'Gym Admin <no-reply@localhost>');

    if (host) {
      this.transporter = nodemailer.createTransport({
        host,
        port,
        secure,
        auth: user ? { user, pass } : undefined,
      });
      this.logger.log(
        `Correo: SMTP configurado (${host}:${port}, usuario ${user || '—'}).`,
      );
    } else {
      this.logger.warn(
        'Correo: SMTP SIN CONFIGURAR. Los correos NO se enviarán: los códigos de ' +
          'recuperación solo se imprimirán en esta consola. Define SMTP_HOST, ' +
          'SMTP_USER y SMTP_PASS en backend/.env y reinicia el servidor.',
      );
    }
  }

  /** Al arrancar comprueba la conexión y las credenciales, para enterarte ya. */
  async onModuleInit() {
    if (!this.transporter) return;
    try {
      await this.transporter.verify();
      this.logger.log('Correo: conexión y credenciales SMTP verificadas ✔');
    } catch (e) {
      this.logger.error(
        `Correo: NO se pudo conectar o autenticar con el servidor SMTP → ${String(e)}. ` +
          'Revisa host, puerto y contraseña (con Gmail debe ser una "contraseña de aplicación").',
      );
    }
  }

  async enviarCodigoRecuperacion(to: string, nombre: string, codigo: string) {
    const asunto = 'Tu código para recuperar la contraseña';
    const texto =
      `Hola ${nombre},\n\n` +
      `Tu código para recuperar la contraseña es: ${codigo}\n\n` +
      `Vence en 15 minutos y solo sirve una vez. Si no lo pediste tú, ignora este mensaje: ` +
      `tu contraseña actual sigue siendo la misma.`;
    const html =
      `<div style="font-family:Arial,sans-serif;max-width:480px">` +
      `<p>Hola ${escapar(nombre)},</p>` +
      `<p>Tu código para recuperar la contraseña es:</p>` +
      `<p style="font-size:32px;letter-spacing:8px;font-weight:bold;margin:16px 0">${codigo}</p>` +
      `<p>Vence en <b>15 minutos</b> y solo sirve una vez.</p>` +
      `<p style="color:#666;font-size:13px">Si no lo pediste tú, ignora este mensaje: tu contraseña actual sigue siendo la misma.</p>` +
      `</div>`;

    if (!this.transporter) {
      if (limpiar(this.config.get<string>('NODE_ENV')) === 'production') {
        throw new ServiceUnavailableException(
          'El envío de correos no está configurado en el servidor.',
        );
      }
      // Desarrollo sin SMTP: no se envía nada; se imprime para poder probar.
      this.logger.warn(
        `⚠ NO SE ENVIÓ NINGÚN CORREO (SMTP sin configurar). Código para ${to}: ${codigo}`,
      );
      return;
    }

    try {
      const info = await this.transporter.sendMail({
        from: this.from,
        to,
        subject: asunto,
        text: texto,
        html,
      });
      if (info.rejected && info.rejected.length > 0) {
        this.logger.warn(
          `Correo RECHAZADO por el servidor para: ${info.rejected.join(', ')}`,
        );
      }
      this.logger.log(
        `Correo de recuperación enviado a ${to} (id ${info.messageId}). Si no llega, revisa Spam.`,
      );
    } catch (e) {
      this.logger.error(`No se pudo enviar el correo a ${to}: ${String(e)}`);
      throw new ServiceUnavailableException(
        'No se pudo enviar el correo. Intenta más tarde o contacta al administrador.',
      );
    }
  }
}
