import { applyDecorators } from '@nestjs/common';
import {
  ArrayMaxSize,
  IsArray,
  IsDateString,
  IsEmail,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

/** Lista de textos cortos opcional (alergias, lesiones, etc.). */
function ListaTextos(max = 30) {
  return applyDecorators(
    IsOptional(),
    IsArray(),
    ArrayMaxSize(max),
    IsString({ each: true }),
    MaxLength(60, { each: true }),
  );
}

const DIAS = ['LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO'];

/**
 * Datos que el miembro SÍ puede editar de su propio perfil. La cédula, los
 * planes, pagos y datos contables no están aquí a propósito (regla 10 y
 * sección 14 del proyecto). Enviar `null` borra el campo opcional.
 */
export class UpdateProfileDto {
  @IsOptional() @IsString() @MinLength(1) @MaxLength(80)
  nombres?: string;

  @IsOptional() @IsString() @MinLength(1) @MaxLength(80)
  apellidos?: string;

  @IsOptional() @IsString() @MaxLength(30)
  celular?: string | null;

  @IsOptional() @IsEmail() @MaxLength(120)
  correo?: string | null;

  @IsOptional() @IsString() @MaxLength(200)
  direccion?: string | null;

  @IsOptional() @IsIn(['M', 'F'])
  sexo?: string | null;

  /** Solo se acepta si el miembro aún no tiene fecha registrada. */
  @IsOptional() @IsDateString()
  fechaNacimiento?: string;
}

export class GuardarAlimentacionDto {
  @IsOptional() @IsString() @MaxLength(80)
  objetivo?: string | null;

  @IsOptional() @IsString() @MaxLength(80)
  tipoDieta?: string | null;

  @ListaTextos() alimentosNoConsumidos?: string[];
  @ListaTextos() alimentosNoGustan?: string[];
  @ListaTextos() alergias?: string[];
  @ListaTextos() restricciones?: string[];
  @ListaTextos() preferencias?: string[];

  @IsOptional() @IsInt() @Min(1) @Max(10)
  numeroComidas?: number | null;

  @IsOptional() @IsNumber() @Min(0) @Max(100000000)
  presupuesto?: number | null;
}

export class GuardarEntrenamientoDto {
  @IsOptional() @IsString() @MaxLength(80)
  objetivo?: string | null;

  @IsOptional() @IsIn(['PRINCIPIANTE', 'INTERMEDIO', 'AVANZADO'])
  nivel?: string | null;

  @ListaTextos() lesiones?: string[];
  @ListaTextos() equipamiento?: string[];
  @ListaTextos() preferencias?: string[];

  @IsOptional() @IsArray() @IsIn(DIAS, { each: true })
  diasDisponibles?: string[];

  @IsOptional() @IsInt() @Min(10) @Max(300)
  minutosPorSesion?: number | null;
}
