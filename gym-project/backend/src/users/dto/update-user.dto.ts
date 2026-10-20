import { ApiPropertyOptional, PartialType, OmitType } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';
import { CreateUserDto } from './create-user.dto';

// Al editar no se permite tocar la contraseña por este endpoint (hay uno
// dedicado para cambio de contraseña) ni el rol se cambia por accidente
// junto con datos personales.
export class UpdateUserDto extends PartialType(
  OmitType(CreateUserDto, ['password', 'role'] as const),
) {
  @ApiPropertyOptional({
    description: 'Solo ADMINISTRADOR puede reasignar el rol de un usuario',
  })
  @IsOptional()
  @IsString()
  role?: string;
}
