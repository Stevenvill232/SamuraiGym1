import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  IsUUID,
  Min,
  ValidateNested,
} from 'class-validator';

export enum MetodoPagoDto {
  EFECTIVO = 'EFECTIVO',
  TRANSFERENCIA = 'TRANSFERENCIA',
  NEQUI = 'NEQUI',
  DAVIPLATA = 'DAVIPLATA',
  TARJETA = 'TARJETA',
  OTRO = 'OTRO',
}

export class CreateProductoDto {
  @ApiProperty({ example: 'Proteína whey 1kg' })
  @IsString()
  nombre: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  descripcion?: string;

  @ApiPropertyOptional({ example: 'Suplementos' })
  @IsOptional()
  @IsString()
  categoria?: string;

  @ApiProperty({ example: 65000 })
  @IsNumber()
  @IsPositive()
  precioCompra: number;

  @ApiProperty({ example: 95000 })
  @IsNumber()
  @IsPositive()
  precioVenta: number;

  @ApiProperty({ example: 20 })
  @IsInt()
  @Min(0)
  stock: number;

  @ApiPropertyOptional({ example: 5 })
  @IsOptional()
  @IsInt()
  @Min(0)
  stockMinimo?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  foto?: string;
}

export class UpdateProductoDto extends PartialType(CreateProductoDto) {}

class ItemVentaDto {
  @ApiProperty()
  @IsUUID()
  productoId: string;

  @ApiProperty({ example: 2 })
  @IsInt()
  @IsPositive()
  cantidad: number;
}

export class CreateVentaDto {
  @ApiProperty({ type: [ItemVentaDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ItemVentaDto)
  items: ItemVentaDto[];

  @ApiProperty({ enum: MetodoPagoDto })
  @IsEnum(MetodoPagoDto)
  metodoPago: MetodoPagoDto;
}
