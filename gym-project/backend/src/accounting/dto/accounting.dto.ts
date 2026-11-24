import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import {
  IsDateString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
} from 'class-validator';

export class CreateGastoDto {
  @ApiProperty({ example: 'LUZ', description: 'Debe existir en Configuración > Categorías de gastos' })
  @IsString()
  @IsNotEmpty()
  categoria: string;

  @ApiProperty({ example: 'Factura de energía - septiembre' })
  @IsString()
  @IsNotEmpty()
  descripcion: string;

  @ApiProperty({ example: 150000 })
  @IsNumber()
  @IsPositive()
  valor: number;

  @ApiProperty({ example: 'EFECTIVO', description: 'Debe existir en Configuración > Métodos de pago' })
  @IsString()
  @IsNotEmpty()
  metodoPago: string;

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
