import { ApiProperty } from '@nestjs/swagger';
import { IsDefined } from 'class-validator';

export class UpdateSettingDto {
  @ApiProperty({ description: 'Nuevo valor de la configuración (JSON)' })
  @IsDefined()
  valor: any;
}
