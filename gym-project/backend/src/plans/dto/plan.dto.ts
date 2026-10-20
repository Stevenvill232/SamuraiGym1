import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
} from 'class-validator';

// Enums propios (en vez de importar los de @prisma/client) para que este
// módulo compile aunque aún no se haya corrido `prisma generate` en el
// entorno donde se edita el código; los valores coinciden EXACTAMENTE con
// los del enum equivalente en schema.prisma, así que Prisma los acepta sin
// problema en tiempo de ejecución.
export enum TipoPlanDto {
  GIMNASIO_SESION = 'GIMNASIO_SESION',
  GIMNASIO_QUINCENA = 'GIMNASIO_QUINCENA',
  GIMNASIO_MES = 'GIMNASIO_MES',
  TIQUETERA_10 = 'TIQUETERA_10',
  TIQUETERA_15 = 'TIQUETERA_15',
  TIQUETERA_20 = 'TIQUETERA_20',
  TIQUETERA_30 = 'TIQUETERA_30',
  BOXEO = 'BOXEO',
  KARATE = 'KARATE',
  MMA = 'MMA',
}

export enum MetodoPagoDto {
  EFECTIVO = 'EFECTIVO',
  TRANSFERENCIA = 'TRANSFERENCIA',
  NEQUI = 'NEQUI',
  DAVIPLATA = 'DAVIPLATA',
  TARJETA = 'TARJETA',
  OTRO = 'OTRO',
}

export enum EstadoPlanDto {
  ACTIVO = 'ACTIVO',
  POR_VENCER = 'POR_VENCER',
  VENCIDO = 'VENCIDO',
  AGOTADO = 'AGOTADO',
}

export class CreatePlanDto {
  @ApiProperty({ description: 'ID del miembro que compra el plan' })
  @IsUUID()
  miembroId: string;

  @ApiProperty({ enum: TipoPlanDto })
  @IsEnum(TipoPlanDto)
  tipoPlan: TipoPlanDto;

  @ApiProperty({ example: 80000 })
  @IsNumber()
  @IsPositive()
  precio: number;

  @ApiProperty({ enum: MetodoPagoDto })
  @IsEnum(MetodoPagoDto)
  metodoPago: MetodoPagoDto;

  @ApiPropertyOptional({
    description: 'Requerido si tipoPlan es BOXEO, KARATE o MMA',
  })
  @IsOptional()
  @IsUUID()
  horarioId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  observaciones?: string;
}

export class QueryPlanDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  miembroId?: string;

  @ApiPropertyOptional({ enum: EstadoPlanDto })
  @IsOptional()
  @IsEnum(EstadoPlanDto)
  estado?: EstadoPlanDto;
}

export class UsarTiqueteraDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  observacion?: string;
}
