import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString } from 'class-validator';

export class QueryUserDto {
  @ApiPropertyOptional({ example: 'juan' })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({ example: 'MIEMBRO' })
  @IsOptional()
  @IsString()
  role?: string;

  @ApiPropertyOptional({
    description: 'true = solo personal (todos los roles excepto MIEMBRO). Solo ADMINISTRADOR.',
  })
  @IsOptional()
  @IsIn(['true', 'false'])
  staff?: string;
}

export class DesactivarQueryDto {
  @ApiPropertyOptional({
    description:
      'personal = quitar solo el acceso de personal; miembro = quitar solo la condición de miembro. Sin valor = desactivar la cuenta completa.',
  })
  @IsOptional()
  @IsIn(['personal', 'miembro'])
  como?: string;
}
