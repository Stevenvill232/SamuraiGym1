import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { DesactivarQueryDto, QueryUserDto } from './dto/query-user.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { StaffRolesDto } from './dto/staff-roles.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../common/decorators/current-user.decorator';

@ApiTags('users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('users')
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Roles('ADMINISTRADOR', 'RECEPCION')
  @Post()
  create(@Body() dto: CreateUserDto, @CurrentUser() user: AuthenticatedUser) {
    return this.usersService.create(dto, user);
  }

  @Roles('ADMINISTRADOR', 'RECEPCION', 'ENTRENADOR')
  @Get()
  findAll(@Query() query: QueryUserDto, @CurrentUser() user: AuthenticatedUser) {
    return this.usersService.findAll(query, user);
  }

  @Roles('ADMINISTRADOR', 'RECEPCION', 'ENTRENADOR')
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Roles('ADMINISTRADOR', 'RECEPCION')
  @Patch(':id')
  update(
    @Param('id') id: string,
    @Body() dto: UpdateUserDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.usersService.update(id, dto, user);
  }

  // Roles de personal de una persona (conserva su condición de miembro).
  @Roles('ADMINISTRADOR')
  @Put(':id/staff-roles')
  setStaffRoles(
    @Param('id') id: string,
    @Body() dto: StaffRolesDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.usersService.setStaffRoles(id, dto.roles, user);
  }

  @Roles('ADMINISTRADOR', 'RECEPCION')
  @Patch(':id/password')
  resetPassword(
    @Param('id') id: string,
    @Body() dto: ResetPasswordDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.usersService.resetPassword(id, dto.password, user);
  }

  // DELETE /users/:id?como=miembro|personal  (sin `como`: cuenta completa)
  @Roles('ADMINISTRADOR', 'RECEPCION')
  @Delete(':id')
  remove(
    @Param('id') id: string,
    @Query() query: DesactivarQueryDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.usersService.remove(id, user, query.como);
  }
}
