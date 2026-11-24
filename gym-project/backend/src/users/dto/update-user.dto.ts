import { PartialType, OmitType } from '@nestjs/swagger';
import { CreateUserDto } from './create-user.dto';

// La cédula es inmutable, la contraseña tiene su propio endpoint y los roles
// se gestionan en PUT /users/:id/staff-roles (solo administrador).
export class UpdateUserDto extends PartialType(
  OmitType(CreateUserDto, ['cedula', 'password', 'role'] as const),
) {}
