import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { IsEnum, IsInt, IsOptional, IsString, Matches, Min } from 'class-validator';

export enum DeporteDto {
  BOXEO = 'BOXEO',
  KARATE = 'KARATE',
  MMA = 'MMA',
}

export enum DiaSemanaDto {
  LUNES = 'LUNES',
  MARTES = 'MARTES',
  MIERCOLES = 'MIERCOLES',
  JUEVES = 'JUEVES',
  VIERNES = 'VIERNES',
  SABADO = 'SABADO',
  DOMINGO = 'DOMINGO',
}

const HORA_REGEX = /^([01]\d|2[0-3]):([0-5]\d)$/;

export class CreateHorarioDto {
  @ApiProperty({ enum: DeporteDto })
  @IsEnum(DeporteDto)
  deporte: DeporteDto;

  @ApiProperty({ enum: DiaSemanaDto })
  @IsEnum(DiaSemanaDto)
  dia: DiaSemanaDto;

  @ApiProperty({ example: '18:00', description: 'Formato HH:mm (24h)' })
  @Matches(HORA_REGEX, { message: 'horaInicio debe tener formato HH:mm' })
  horaInicio: string;

  @ApiProperty({ example: '19:00', description: 'Formato HH:mm (24h)' })
  @Matches(HORA_REGEX, { message: 'horaFin debe tener formato HH:mm' })
  horaFin: string;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @IsInt()
  @Min(1)
  cupo?: number;
}

export class UpdateHorarioDto extends PartialType(CreateHorarioDto) {}

export class QueryHorarioDto {
  @ApiPropertyOptional({ enum: DeporteDto })
  @IsOptional()
  @IsEnum(DeporteDto)
  deporte?: DeporteDto;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  dia?: string;
}
