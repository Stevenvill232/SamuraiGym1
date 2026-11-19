import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Min,
  ValidateNested,
} from 'class-validator';

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

/** Un día y una franja horaria. */
export class FranjaDto {
  @ApiProperty({ enum: DiaSemanaDto })
  @IsEnum(DiaSemanaDto)
  dia: DiaSemanaDto;

  @ApiProperty({ example: '17:00' })
  @Matches(HORA_REGEX, { message: 'horaInicio debe tener formato HH:mm' })
  horaInicio: string;

  @ApiProperty({ example: '18:00' })
  @Matches(HORA_REGEX, { message: 'horaFin debe tener formato HH:mm' })
  horaFin: string;
}

/**
 * Crea varios horarios de un mismo deporte en un solo paso, cada uno con su
 * propio día y hora (ej. Lunes 17-18, Miércoles 17-18, Viernes 18-19).
 */
export class CreateHorariosBulkDto {
  @ApiProperty({ enum: DeporteDto })
  @IsEnum(DeporteDto)
  deporte: DeporteDto;

  @ApiProperty({ type: [FranjaDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(14)
  @ValidateNested({ each: true })
  @Type(() => FranjaDto)
  franjas: FranjaDto[];

  @ApiPropertyOptional({ example: 20, description: 'Cupo aplicado a todos' })
  @IsOptional()
  @IsInt()
  @Min(1)
  cupo?: number;
}
