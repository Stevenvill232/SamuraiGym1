import { ArrayMinSize, IsArray, IsIn } from 'class-validator';
import { ROLES_PERSONAL } from '../../common/utils/roles.util';

export class StaffRolesDto {
  @IsArray()
  @ArrayMinSize(1)
  @IsIn(ROLES_PERSONAL, { each: true })
  roles: string[];
}
