import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class QueryUserDto {
  // Búsqueda libre por cédula, nombre/apellido o celular (regla del módulo
  // Miembros: "permitir buscar por cédula, nombre, celular").
  @ApiPropertyOptional({ example: 'juan' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ example: 'MIEMBRO' })
  @IsOptional()
  @IsString()
  role?: string;
}
