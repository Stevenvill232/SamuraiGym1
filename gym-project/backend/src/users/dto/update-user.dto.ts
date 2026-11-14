import { ApiPropertyOptional, PartialType, OmitType } from '@nestjs/swagger';
import { IsIn, IsOptional } from 'class-validator';
import { CreateUserDto, ROLES_VALIDOS } from './create-user.dto';

// La cédula es inmutable y la contraseña tiene su propio endpoint.
export class UpdateUserDto extends PartialType(
  OmitType(CreateUserDto, ['cedula', 'password', 'role'] as const),
) {
  @ApiPropertyOptional({
    description: 'Solo un ADMINISTRADOR puede reasignar el rol de un usuario',
  })
  @IsOptional()
  @IsIn(ROLES_VALIDOS)
  role?: string;
}
