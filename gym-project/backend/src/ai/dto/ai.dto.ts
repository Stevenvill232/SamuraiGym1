import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

export class GenerarRutinaDto {
  @IsOptional() @IsString() @MaxLength(60)
  enfoque?: string;

  @IsOptional() @IsIn(['GIMNASIO', 'CASA'])
  lugar?: string;

  @IsOptional() @IsIn(['SUAVE', 'MEDIA', 'ALTA'])
  intensidad?: string;

  @IsOptional() @IsInt() @Min(15) @Max(180)
  minutos?: number;

  @IsOptional() @IsString() @MaxLength(300)
  notas?: string;
}

export const TIPOS_COMIDA = ['DESAYUNO', 'MEDIA_MANANA', 'ALMUERZO', 'MERIENDA', 'CENA'];

export class GenerarAlimentacionDto {
  @IsIn(TIPOS_COMIDA)
  tipoComida: string;

  @IsOptional() @IsString() @MaxLength(300)
  notas?: string;
}

export class TurnoChatDto {
  @IsIn(['usuario', 'asistente'])
  rol: string;

  @IsString() @MaxLength(2000)
  texto: string;
}

export class ChatDto {
  @IsString() @MinLength(1) @MaxLength(800)
  mensaje: string;

  @IsOptional() @IsArray() @ArrayMaxSize(10)
  @ValidateNested({ each: true })
  @Type(() => TurnoChatDto)
  historial?: TurnoChatDto[];
}
