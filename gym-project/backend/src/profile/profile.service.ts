import {
  ForbiddenException,
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { calcularEdad } from '../common/utils/edad.util';
import {
  UpdateProfileDto,
  GuardarAlimentacionDto,
  GuardarEntrenamientoDto,
} from './dto/profile.dto';

const HORAS_36 = 36 * 60 * 60 * 1000;

@Injectable()
export class ProfileService {
  constructor(private prisma: PrismaService) {}

  async getProfile(userId: string) {
    const user: any = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        role: true,
        preferenciaAlimentacion: true,
        perfilEntrenamiento: true,
      },
    });
    if (!user || user.estado === 'INACTIVO') {
      throw new NotFoundException('Usuario no encontrado');
    }

    const ultimo: any = await this.prisma.historialFisico.findFirst({
      where: { miembroId: userId },
      orderBy: { fecha: 'desc' },
    });

    const {
      passwordHash,
      roleId,
      role,
      preferenciaAlimentacion,
      perfilEntrenamiento,
      ...rest
    } = user;

    return {
      ...rest,
      role: role?.nombre,
      edad: calcularEdad(user.fechaNacimiento),
      pesoActual: ultimo?.peso ?? null,
      estaturaActual: ultimo?.estatura ?? null,
      ultimoRegistroFisico: ultimo?.fecha ?? null,
      alimentacion: preferenciaAlimentacion
        ? {
            ...preferenciaAlimentacion,
            presupuesto:
              preferenciaAlimentacion.presupuesto == null
                ? null
                : Number(preferenciaAlimentacion.presupuesto),
          }
        : null,
      entrenamiento: perfilEntrenamiento ?? null,
    };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user: any = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) throw new NotFoundException('Usuario no encontrado');

    const data: Record<string, any> = {};

    // Nombres y apellidos son obligatorios: solo se actualizan si vienen.
    if (dto.nombres != null) data.nombres = dto.nombres.trim();
    if (dto.apellidos != null) data.apellidos = dto.apellidos.trim();

    // Opcionales: null o vacío los borra.
    for (const campo of ['celular', 'correo', 'direccion', 'sexo'] as const) {
      const v = dto[campo];
      if (v !== undefined) {
        data[campo] = v === null || String(v).trim() === '' ? null : String(v).trim();
      }
    }

    // "Fecha de nacimiento, según reglas administrativas": el miembro solo
    // puede registrarla UNA vez; para corregirla debe pedirlo al gimnasio.
    if (dto.fechaNacimiento) {
      const nueva = new Date(dto.fechaNacimiento);
      if (nueva.getTime() > Date.now() || nueva.getFullYear() < 1900) {
        throw new BadRequestException('La fecha de nacimiento no es válida');
      }
      if (user.fechaNacimiento) {
        const mismaFecha =
          Math.abs(nueva.getTime() - user.fechaNacimiento.getTime()) < HORAS_36;
        if (!mismaFecha) {
          throw new ForbiddenException(
            'Tu fecha de nacimiento ya está registrada. Para cambiarla comunícate con el gimnasio.',
          );
        }
      } else {
        data.fechaNacimiento = nueva;
      }
    }

    if (Object.keys(data).length > 0) {
      await this.prisma.user.update({ where: { id: userId }, data });
    }
    return this.getProfile(userId);
  }

  async guardarAlimentacion(userId: string, dto: GuardarAlimentacionDto) {
    const data = {
      objetivo: dto.objetivo ?? null,
      tipoDieta: dto.tipoDieta ?? null,
      alimentosNoConsumidos: this.limpiar(dto.alimentosNoConsumidos),
      alimentosNoGustan: this.limpiar(dto.alimentosNoGustan),
      alergias: this.limpiar(dto.alergias),
      restricciones: this.limpiar(dto.restricciones),
      preferencias: this.limpiar(dto.preferencias),
      numeroComidas: dto.numeroComidas ?? null,
      presupuesto: dto.presupuesto ?? null,
    };
    await this.prisma.preferenciaAlimentacion.upsert({
      where: { miembroId: userId },
      update: data,
      create: { miembroId: userId, ...data },
    });
    return this.getProfile(userId);
  }

  async guardarEntrenamiento(userId: string, dto: GuardarEntrenamientoDto) {
    const data = {
      objetivo: dto.objetivo ?? null,
      nivel: dto.nivel ?? null,
      lesiones: this.limpiar(dto.lesiones),
      equipamiento: this.limpiar(dto.equipamiento),
      preferencias: this.limpiar(dto.preferencias),
      diasDisponibles: Array.from(new Set(dto.diasDisponibles ?? [])),
      minutosPorSesion: dto.minutosPorSesion ?? null,
    };
    await this.prisma.perfilEntrenamiento.upsert({
      where: { miembroId: userId },
      update: data,
      create: { miembroId: userId, ...data },
    });
    return this.getProfile(userId);
  }

  private limpiar(lista?: string[]): string[] {
    const vistos = new Set<string>();
    const resultado: string[] = [];
    for (const item of lista ?? []) {
      const t = String(item).trim();
      if (!t || vistos.has(t.toLowerCase())) continue;
      vistos.add(t.toLowerCase());
      resultado.push(t);
    }
    return resultado;
  }
}
