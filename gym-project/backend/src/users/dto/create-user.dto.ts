import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString,
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  MinLength,
} from 'class-validator';

// Roles válidos al crear un usuario desde la app admin. MIEMBRO es el caso
// más común; el resto se habilita cuando se necesiten (regla de negocio: el
// sistema debe soportar Recepción/Entrenador/Contador sin reescribirse).
const ROLES_VALIDOS = [
  'ADMINISTRADOR',
  'MIEMBRO',
  'RECEPCION',
  'ENTRENADOR',
  'CONTADOR',
] as const;

export class CreateUserDto {
  @ApiProperty({ example: '1234567890' })
  @IsString()
  cedula: string;

  @ApiProperty({ example: 'Juan' })
  @IsString()
  nombres: string;

  @ApiProperty({ example: 'Pérez Gómez' })
  @IsString()
  apellidos: string;

  @ApiPropertyOptional({ example: '1998-05-14' })
  @IsOptional()
  @IsDateString()
  fechaNacimiento?: string;

  @ApiPropertyOptional({ example: '3001234567' })
  @IsOptional()
  @IsString()
  celular?: string;

  @ApiPropertyOptional({ example: 'juan@correo.com' })
  @IsOptional()
  @IsEmail()
  correo?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  direccion?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  foto?: string;

  @ApiPropertyOptional({ example: 'M' })
  @IsOptional()
  @IsString()
  sexo?: string;

  @ApiProperty({ example: 'PasswordSegura123' })
  @IsString()
  @MinLength(6)
  password: string;

  @ApiProperty({ example: 'MIEMBRO', enum: ROLES_VALIDOS })
  @IsIn(ROLES_VALIDOS)
  role: (typeof ROLES_VALIDOS)[number];
}
