import { IsDateString, IsNumber, IsOptional, Max, Min } from 'class-validator';

export class CreateRegistroFisicoDto {
  @IsNumber()
  @Min(20)
  @Max(400)
  peso: number; // kg

  @IsNumber()
  @Min(0.5)
  @Max(2.5)
  estatura: number; // metros (ej. 1.70)

  @IsOptional()
  @IsDateString()
  fecha?: string;
}
