import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Prefijo global: todas las rutas quedan bajo /api/...
  app.setGlobalPrefix('api');

  // Valida y transforma automáticamente los DTOs de entrada.
  // whitelist=true descarta cualquier campo no declarado en el DTO: es una
  // capa de seguridad extra (regla de negocio: "no confiar en datos enviados
  // desde Flutter").
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Formato de error consistente en toda la API (nunca exponer stacktraces).
  app.useGlobalFilters(new HttpExceptionFilter());

  // CORS: la app admin (Flutter Desktop) y la app móvil consumen esta API
  // desde orígenes distintos.
  app.enableCors({ origin: true, credentials: true });

  // Documentación interactiva en /api/docs — muy útil mientras se construyen
  // los módulos uno por uno.
  const config = new DocumentBuilder()
    .setTitle('Gym Management API')
    .setDescription('API REST del sistema de gestión de gimnasio')
    .setVersion('0.1')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document);

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  // eslint-disable-next-line no-console
  console.log(`🚀 API corriendo en http://localhost:${port}/api`);
  // eslint-disable-next-line no-console
  console.log(`📚 Swagger docs en http://localhost:${port}/api/docs`);
}
bootstrap();
