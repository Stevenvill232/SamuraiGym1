import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { StoreService } from './store.service';
import {
  CreateProductoDto,
  UpdateProductoDto,
  CreateVentaDto,
} from './dto/store.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../common/decorators/current-user.decorator';

@ApiTags('store')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('store')
export class StoreController {
  constructor(private service: StoreService) {}

  @Roles('ADMINISTRADOR')
  @Post('productos')
  createProducto(@Body() dto: CreateProductoDto) {
    return this.service.createProducto(dto);
  }

  @Roles('ADMINISTRADOR', 'RECEPCION')
  @Get('productos')
  findAllProductos() {
    return this.service.findAllProductos();
  }

  @Roles('ADMINISTRADOR')
  @Get('productos/stock-bajo')
  productosStockBajo() {
    return this.service.productosStockBajo();
  }

  @Roles('ADMINISTRADOR', 'RECEPCION')
  @Get('productos/:id')
  findOneProducto(@Param('id') id: string) {
    return this.service.findOneProducto(id);
  }

  @Roles('ADMINISTRADOR')
  @Patch('productos/:id')
  updateProducto(@Param('id') id: string, @Body() dto: UpdateProductoDto) {
    return this.service.updateProducto(id, dto);
  }

  @Roles('ADMINISTRADOR')
  @Delete('productos/:id')
  removeProducto(@Param('id') id: string) {
    return this.service.removeProducto(id);
  }

  @Roles('ADMINISTRADOR', 'RECEPCION')
  @Post('ventas')
  crearVenta(
    @Body() dto: CreateVentaDto,
    @CurrentUser() user: AuthenticatedUser,
  ) {
    return this.service.crearVenta(dto, user.userId);
  }

  @Roles('ADMINISTRADOR', 'CONTADOR')
  @Get('ventas')
  findAllVentas() {
    return this.service.findAllVentas();
  }
}
