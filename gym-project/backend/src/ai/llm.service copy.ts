import {
  BadGatewayException,
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface MensajeLlm {
  role: 'user' | 'assistant';
  content: string;
}

const limpiar = (v?: string) => (v ?? '').trim().replace(/^["']|["']$/g, '').trim();

/**
 * Cliente mínimo de IA (sin SDK, solo HTTP). Soporta Anthropic (Claude) y
 * OpenAI. La clave vive SOLO en backend/.env: la app nunca la ve.
 *   AI_PROVIDER = anthropic | openai     AI_API_KEY     AI_MODEL
 *   AI_BASE_URL (opcional: proxy o pruebas)
 */
@Injectable()
export class LlmService implements OnModuleInit {
  private readonly logger = new Logger(LlmService.name);

  constructor(private config: ConfigService) {}

  onModuleInit() {
    if (this.disponible) {
      this.logger.log(`IA: configurada (${this.proveedor}, modelo ${this.modelo}).`);
    } else {
      this.logger.warn(
        'IA: SIN CONFIGURAR. El asistente responderá "no está configurado". Define AI_API_KEY en backend/.env y reinicia el servidor.',
      );
    }
  }

  private get proveedor() {
    return (limpiar(this.config.get<string>('AI_PROVIDER')) || 'anthropic').toLowerCase();
  }
  private get apiKey() {
    return limpiar(this.config.get<string>('AI_API_KEY'));
  }
  private get modelo() {
    return (
      limpiar(this.config.get<string>('AI_MODEL')) ||
      (this.proveedor === 'openai' ? 'gpt-4o-mini' : 'claude-sonnet-5-5')
    );
  }

  get disponible() {
    return this.apiKey.length > 0;
  }

  async completar(opts: {
    system: string;
    mensajes: MensajeLlm[];
    maxTokens?: number;
    json?: boolean;
  }): Promise<string> {
    if (!this.disponible) {
      throw new ServiceUnavailableException(
        'El asistente de IA no está configurado en el servidor.',
      );
    }
    const mensajes = this.normalizarMensajes(opts.mensajes);
    if (mensajes.length === 0) {
      throw new BadGatewayException('No hay mensaje para enviar a la IA.');
    }
    const maxTokens = opts.maxTokens ?? 1500;

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 60_000);
    try {
      return this.proveedor === 'openai'
        ? await this.llamarOpenAi(opts.system, mensajes, maxTokens, !!opts.json, controller.signal)
        : await this.llamarAnthropic(opts.system, mensajes, maxTokens, controller.signal);
    } catch (e) {
      if (e instanceof HttpException) throw e;
      this.logger.error(`Error llamando a la IA (${this.proveedor}): ${String(e)}`);
      throw new ServiceUnavailableException(
        'El asistente de IA no respondió a tiempo. Intenta de nuevo en un momento.',
      );
    } finally {
      clearTimeout(timer);
    }
  }

  /** Los modelos exigen alternar roles y empezar por "user". */
  private normalizarMensajes(mensajes: MensajeLlm[]): MensajeLlm[] {
    const salida: MensajeLlm[] = [];
    for (const m of mensajes) {
      const texto = m.content?.trim();
      if (!texto) continue;
      const ultimo = salida[salida.length - 1];
      if (ultimo && ultimo.role === m.role) ultimo.content += `\n${texto}`;
      else salida.push({ role: m.role, content: texto });
    }
    while (salida.length > 0 && salida[0].role !== 'user') salida.shift();
    return salida;
  }

  private async llamarAnthropic(
    system: string,
    mensajes: MensajeLlm[],
    maxTokens: number,
    signal: AbortSignal,
  ) {
    const base = limpiar(this.config.get<string>('AI_BASE_URL')) || 'https://api.anthropic.com';
    const res = await fetch(`${base}/v1/messages`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-api-key': this.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: this.modelo,
        max_tokens: maxTokens,
        system,
        messages: mensajes,
      }),
      signal,
    });
    const data: any = await res.json().catch(() => ({}));
    if (!res.ok) this.fallar(res.status, data);
    const texto = (data.content ?? [])
      .filter((b: any) => b.type === 'text')
      .map((b: any) => b.text)
      .join('');
    if (!texto.trim()) throw new BadGatewayException('La IA devolvió una respuesta vacía.');
    return texto;
  }

  private async llamarOpenAi(
    system: string,
    mensajes: MensajeLlm[],
    maxTokens: number,
    json: boolean,
    signal: AbortSignal,
  ) {
    const base = limpiar(this.config.get<string>('AI_BASE_URL')) || 'https://api.openai.com';
    const res = await fetch(`${base}/v1/chat/completions`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        model: this.modelo,
        max_completion_tokens: maxTokens,
        messages: [{ role: 'system', content: system }, ...mensajes],
        ...(json ? { response_format: { type: 'json_object' } } : {}),
      }),
      signal,
    });
    const data: any = await res.json().catch(() => ({}));
    if (!res.ok) this.fallar(res.status, data);
    const texto = data.choices?.[0]?.message?.content ?? '';
    if (!String(texto).trim()) throw new BadGatewayException('La IA devolvió una respuesta vacía.');
    return String(texto);
  }

  /** El detalle técnico va al log del servidor; al usuario, un mensaje claro. */
  private fallar(status: number, data: any): never {
    this.logger.error(`La IA respondió ${status}: ${JSON.stringify(data).slice(0, 400)}`);
    if (status === 401 || status === 403) {
      throw new ServiceUnavailableException(
        'El asistente de IA no está disponible (credenciales del servidor inválidas).',
      );
    }
    if (status === 429 || status === 529) {
      throw new HttpException(
        'El servicio de IA está saturado. Intenta de nuevo en unos minutos.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    throw new BadGatewayException('El asistente de IA no pudo responder. Intenta de nuevo.');
  }
}
