import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

/**
 * Envuelve PrismaClient como un provider de Nest para poder inyectarlo
 * (con @Injectable) en cualquier service, y para abrir/cerrar la conexión
 * junto con el ciclo de vida de la aplicación.
 */
@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
