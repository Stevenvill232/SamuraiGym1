import { IsString, Matches, MaxLength, MinLength } from 'class-validator';

export class SolicitarResetDto {
  @IsString()
  @MinLength(3)
  @MaxLength(30)
  cedula: string;
}

export class ConfirmarResetDto {
  @IsString()
  @MinLength(3)
  @MaxLength(30)
  cedula: string;

  @Matches(/^\d{6}$/, { message: 'El código debe tener 6 dígitos' })
  codigo: string;

  @IsString()
  @MinLength(6)
  @MaxLength(72)
  nueva: string;
}
