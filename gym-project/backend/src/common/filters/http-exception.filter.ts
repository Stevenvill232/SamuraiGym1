import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

/**
 * Uniforma TODAS las respuestas de error de la API en un mismo shape:
 *   { statusCode, message, error, path, timestamp }
 *
 * Objetivo (regla de UX del proyecto: "nunca mostrar errores técnicos
 * innecesarios al usuario final"): Flutter siempre puede confiar en este
 * formato para mostrar el mensaje correcto sin parsear stacktraces.
 */
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const isHttpException = exception instanceof HttpException;
    const status = isHttpException
      ? exception.getStatus()
      : HttpStatus.INTERNAL_SERVER_ERROR;

    const exceptionResponse = isHttpException
      ? exception.getResponse()
      : null;

    const message =
      (typeof exceptionResponse === 'object' &&
        exceptionResponse !== null &&
        (exceptionResponse as any).message) ||
      (isHttpException ? exception.message : 'Error interno del servidor');

    if (!isHttpException) {
      // Solo se loguea el detalle técnico en servidor; nunca se envía al cliente.
      this.logger.error(exception);
    }

    response.status(status).json({
      statusCode: status,
      message,
      path: request.url,
      timestamp: new Date().toISOString(),
    });
  }
}
