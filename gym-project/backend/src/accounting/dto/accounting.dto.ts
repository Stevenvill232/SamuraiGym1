import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import {
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
} from 'class-validator';

export enum CategoriaGastoDto {
  LUZ = 'LUZ',
  AGUA = 'AGUA',
  NOMINA = 'NOMINA',
  ARRIENDO = 'ARRIENDO',
  INTERNET = 'INTERNET',
  MANTENIMIENTO = 'MANTENIMIENTO',
  IMPLEMENTOS = 'IMPLEMENTOS',
  OTRO = 'OTRO',
}

export enum MetodoPagoDto {
  EFECTIVO = 'EFECTIVO',
  TRANSFERENCIA = 'TRANSFERENCIA',
  NEQUI = 'NEQUI',
  DAVIPLATA = 'DAVIPLATA',
  TARJETA = 'TARJETA',
  OTRO = 'OTRO',
}

export class CreateGastoDto {
  @ApiProperty({ enum: CategoriaGastoDto })
  @IsEnum(CategoriaGastoDto)
  categoria: CategoriaGastoDto;

  @ApiProperty({ example: 'Factura de energía - septiembre' })
  @IsString()
  descripcion: string;

  @ApiProperty({ example: 150000 })
  @IsNumber()
  @IsPositive()
  valor: number;

  @ApiProperty({ enum: MetodoPagoDto })
  @IsEnum(MetodoPagoDto)
  metodoPago: MetodoPagoDto;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  observacion?: string;
}

export class QueryMovimientosDto {
  @ApiPropertyOptional({ example: '2026-09-01' })
  @IsOptional()
  @IsDateString()
  desde?: string;

  @ApiPropertyOptional({ example: '2026-09-30' })
  @IsOptional()
  @IsDateString()
  hasta?: string;
}
