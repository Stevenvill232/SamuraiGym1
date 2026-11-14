import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  SETTINGS_CLAVES,
  SETTINGS_DEFAULTS,
  TIPOS_PLAN,
} from './settings.defaults';

const esObjeto = (v: unknown): v is Record<string, any> =>
  typeof v === 'object' && v !== null && !Array.isArray(v);

/**
 * Ajustes del gimnasio guardados como clave -> JSON en la tabla
 * `configuracion`. Cambiar un ajuste NUNCA modifica registros históricos:
 * los planes y ventas guardan su propio precio/método en el momento de la
 * transacción.
 */
@Injectable()
export class SettingsService {
  constructor(private prisma: PrismaService) {}

  async getAll() {
    const filas = await this.prisma.configuracion.findMany();
    const guardados: Record<string, any> = {};
    for (const f of filas) guardados[f.clave] = f.valor;

    const resultado: Record<string, any> = {};
    for (const clave of SETTINGS_CLAVES) {
      resultado[clave] = this.fusionar(clave, guardados[clave]);
    }
    return resultado;
  }

  async get<T = any>(clave: string): Promise<T> {
    const fila = await this.prisma.configuracion.findUnique({
      where: { clave },
    });
    return this.fusionar(clave, fila?.valor) as T;
  }

  async set(clave: string, valor: unknown) {
    if (!SETTINGS_CLAVES.includes(clave)) {
      throw new NotFoundException(`La configuración "${clave}" no existe`);
    }
    const actual = await this.get(clave);
    const normalizado = this.validar(clave, valor, actual);

    await this.prisma.configuracion.upsert({
      where: { clave },
      update: { valor: normalizado as any },
      create: { clave, valor: normalizado as any },
    });
    return { clave, valor: normalizado };
  }

  /** Validación crítica en backend: el método debe existir en Configuración. */
  async assertMetodoPago(valor: string) {
    const lista = await this.get<string[]>('metodos_pago');
    if (!lista.includes(valor)) {
      throw new BadRequestException(
        `Método de pago no válido: "${valor}". Opciones: ${lista.join(', ')}`,
      );
    }
  }

  async assertCategoriaGasto(valor: string) {
    const lista = await this.get<string[]>('categorias_gasto');
    if (!lista.includes(valor)) {
      throw new BadRequestException(
        `Categoría de gasto no válida: "${valor}". Opciones: ${lista.join(', ')}`,
      );
    }
  }

  // ------------------------------------------------------------------ //

  private fusionar(clave: string, guardado: unknown) {
    const def = SETTINGS_DEFAULTS[clave];
    if (guardado === undefined || guardado === null) {
      return JSON.parse(JSON.stringify(def));
    }
    // Para objetos, los campos nuevos que aparezcan en el futuro toman su
    // valor por defecto sin romper lo ya guardado.
    if (esObjeto(def) && esObjeto(guardado)) return { ...def, ...guardado };
    return guardado;
  }

  private validar(clave: string, valor: unknown, actual: any): any {
    switch (clave) {
      case 'precios_planes':
        return this.validarPrecios(valor, actual);
      case 'tiquetera_factor_vigencia': {
        const n = Number(valor);
        if (!Number.isFinite(n) || n < 1 || n > 10) {
          throw new BadRequestException(
            'El factor de vigencia debe estar entre 1 y 10',
          );
        }
        return Math.round(n * 100) / 100;
      }
      case 'categorias_gasto':
        return this.validarLista(valor, 'categorías de gastos');
      case 'metodos_pago':
        return this.validarLista(valor, 'métodos de pago');
      case 'stock_minimo_default': {
        const n = Number(valor);
        if (!Number.isInteger(n) || n < 0 || n > 10000) {
          throw new BadRequestException(
            'El stock mínimo debe ser un número entero entre 0 y 10000',
          );
        }
        return n;
      }
      case 'info_gimnasio':
        return this.validarInfo(valor, actual);
      case 'notificaciones':
        return this.validarNotificaciones(valor, actual);
      default:
        throw new NotFoundException(`La configuración "${clave}" no existe`);
    }
  }

  private validarPrecios(valor: unknown, actual: Record<string, number>) {
    if (!esObjeto(valor)) {
      throw new BadRequestException('Los precios deben enviarse como objeto');
    }
    const resultado = { ...actual };
    for (const [tipo, precio] of Object.entries(valor)) {
      if (!TIPOS_PLAN.includes(tipo)) {
        throw new BadRequestException(`Tipo de plan desconocido: "${tipo}"`);
      }
      const n = Number(precio);
      if (!Number.isFinite(n) || n <= 0 || n > 100_000_000) {
        throw new BadRequestException(`Precio inválido para ${tipo}`);
      }
      resultado[tipo] = n;
    }
    return resultado;
  }

  private validarLista(valor: unknown, nombre: string): string[] {
    if (!Array.isArray(valor)) {
      throw new BadRequestException(`Las ${nombre} deben enviarse como lista`);
    }
    const vistos = new Set<string>();
    const limpia: string[] = [];
    for (const item of valor) {
      const t = String(item ?? '').trim();
      if (!t) continue;
      if (t.length > 40) {
        throw new BadRequestException(
          `Cada elemento de ${nombre} admite máximo 40 caracteres`,
        );
      }
      if (vistos.has(t.toLowerCase())) continue;
      vistos.add(t.toLowerCase());
      limpia.push(t);
    }
    if (limpia.length < 1) {
      throw new BadRequestException(`Debe existir al menos una de las ${nombre}`);
    }
    if (limpia.length > 30) {
      throw new BadRequestException(`Máximo 30 elementos en ${nombre}`);
    }
    return limpia;
  }

  private validarInfo(valor: unknown, actual: Record<string, string>) {
    if (!esObjeto(valor)) {
      throw new BadRequestException('La información debe enviarse como objeto');
    }
    const campo = (k: string, max: number) => {
      const v = valor[k] === undefined ? actual[k] : valor[k];
      const t = String(v ?? '').trim();
      if (t.length > max) {
        throw new BadRequestException(`"${k}" admite máximo ${max} caracteres`);
      }
      return t;
    };
    const nombre = campo('nombre', 100);
    if (!nombre) {
      throw new BadRequestException('El nombre del gimnasio es obligatorio');
    }
    return {
      nombre,
      telefono: campo('telefono', 30),
      direccion: campo('direccion', 200),
      horarioAtencion: campo('horarioAtencion', 200),
    };
  }

  private validarNotificaciones(valor: unknown, actual: Record<string, boolean>) {
    if (!esObjeto(valor)) {
      throw new BadRequestException('Formato de notificaciones inválido');
    }
    const resultado = { ...actual };
    for (const k of ['avisarDosDias', 'avisarUnDia', 'avisarVencido']) {
      if (valor[k] !== undefined) resultado[k] = Boolean(valor[k]);
    }
    return resultado;
  }
}
