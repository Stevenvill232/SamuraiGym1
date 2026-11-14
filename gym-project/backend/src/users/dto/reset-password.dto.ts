import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class ResetPasswordDto {
  @ApiProperty({ example: 'NuevaClave123' })
  @IsString()
  @MinLength(6)
  @MaxLength(72)
  password: string;
}
