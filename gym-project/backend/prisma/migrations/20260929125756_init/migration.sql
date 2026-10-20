-- CreateEnum
CREATE TYPE "EstadoUsuario" AS ENUM ('ACTIVO', 'INACTIVO');

-- CreateEnum
CREATE TYPE "TipoPlan" AS ENUM ('GIMNASIO_SESION', 'GIMNASIO_QUINCENA', 'GIMNASIO_MES', 'TIQUETERA_10', 'TIQUETERA_15', 'TIQUETERA_20', 'TIQUETERA_30', 'BOXEO', 'KARATE', 'MMA');

-- CreateEnum
CREATE TYPE "EstadoPlan" AS ENUM ('ACTIVO', 'POR_VENCER', 'VENCIDO', 'AGOTADO');

-- CreateEnum
CREATE TYPE "MetodoPago" AS ENUM ('EFECTIVO', 'TRANSFERENCIA', 'NEQUI', 'DAVIPLATA', 'TARJETA', 'OTRO');

-- CreateEnum
CREATE TYPE "Deporte" AS ENUM ('BOXEO', 'KARATE', 'MMA');

-- CreateEnum
CREATE TYPE "DiaSemana" AS ENUM ('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO');

-- CreateEnum
CREATE TYPE "TipoIngreso" AS ENUM ('GIMNASIO_SESION', 'GIMNASIO_QUINCENA', 'GIMNASIO_MES', 'TIQUETERA', 'BOXEO', 'KARATE', 'MMA', 'PRODUCTO');

-- CreateEnum
CREATE TYPE "CategoriaGasto" AS ENUM ('LUZ', 'AGUA', 'NOMINA', 'ARRIENDO', 'INTERNET', 'MANTENIMIENTO', 'IMPLEMENTOS', 'OTRO');

-- CreateEnum
CREATE TYPE "TipoComida" AS ENUM ('DESAYUNO', 'MEDIA_MANANA', 'ALMUERZO', 'MERIENDA', 'CENA');

-- CreateTable
CREATE TABLE "roles" (
    "id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "permisos" (
    "id" TEXT NOT NULL,
    "modulo" TEXT NOT NULL,
    "accion" TEXT NOT NULL,

    CONSTRAINT "permisos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "usuarios" (
    "id" TEXT NOT NULL,
    "cedula" TEXT NOT NULL,
    "nombres" TEXT NOT NULL,
    "apellidos" TEXT NOT NULL,
    "fechaNacimiento" TIMESTAMP(3),
    "celular" TEXT,
    "correo" TEXT,
    "direccion" TEXT,
    "foto" TEXT,
    "sexo" TEXT,
    "passwordHash" TEXT NOT NULL,
    "fechaRegistro" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "estado" "EstadoUsuario" NOT NULL DEFAULT 'ACTIVO',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "roleId" TEXT NOT NULL,

    CONSTRAINT "usuarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "planes" (
    "id" TEXT NOT NULL,
    "miembroId" TEXT NOT NULL,
    "tipoPlan" "TipoPlan" NOT NULL,
    "precio" DECIMAL(10,2) NOT NULL,
    "fechaCompra" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "fechaInicio" TIMESTAMP(3) NOT NULL,
    "fechaVencimiento" TIMESTAMP(3) NOT NULL,
    "diasTotales" INTEGER,
    "diasUtilizados" INTEGER NOT NULL DEFAULT 0,
    "estado" "EstadoPlan" NOT NULL DEFAULT 'ACTIVO',
    "metodoPago" "MetodoPago" NOT NULL,
    "horarioId" TEXT,
    "observaciones" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "planes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "usos_tiquetera" (
    "id" TEXT NOT NULL,
    "planId" TEXT NOT NULL,
    "fechaUso" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "observacion" TEXT,
    "registradoPorId" TEXT NOT NULL,

    CONSTRAINT "usos_tiquetera_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "horarios" (
    "id" TEXT NOT NULL,
    "deporte" "Deporte" NOT NULL,
    "dia" "DiaSemana" NOT NULL,
    "horaInicio" TEXT NOT NULL,
    "horaFin" TEXT NOT NULL,
    "cupo" INTEGER,
    "estado" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "horarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ingresos" (
    "id" TEXT NOT NULL,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "miembroId" TEXT,
    "concepto" TEXT NOT NULL,
    "tipo" "TipoIngreso" NOT NULL,
    "planId" TEXT,
    "ventaId" TEXT,
    "valor" DECIMAL(10,2) NOT NULL,
    "metodoPago" "MetodoPago" NOT NULL,
    "usuarioAdminId" TEXT NOT NULL,
    "observacion" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ingresos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "gastos" (
    "id" TEXT NOT NULL,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "categoria" "CategoriaGasto" NOT NULL,
    "descripcion" TEXT NOT NULL,
    "valor" DECIMAL(10,2) NOT NULL,
    "metodoPago" "MetodoPago" NOT NULL,
    "observacion" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "gastos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "productos" (
    "id" TEXT NOT NULL,
    "nombre" TEXT NOT NULL,
    "descripcion" TEXT,
    "categoria" TEXT,
    "precioCompra" DECIMAL(10,2) NOT NULL,
    "precioVenta" DECIMAL(10,2) NOT NULL,
    "stock" INTEGER NOT NULL DEFAULT 0,
    "stockMinimo" INTEGER NOT NULL DEFAULT 5,
    "foto" TEXT,
    "estado" BOOLEAN NOT NULL DEFAULT true,
    "fechaRegistro" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "productos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ventas" (
    "id" TEXT NOT NULL,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "total" DECIMAL(10,2) NOT NULL,
    "metodoPago" "MetodoPago" NOT NULL,
    "usuarioId" TEXT NOT NULL,

    CONSTRAINT "ventas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "detalle_ventas" (
    "id" TEXT NOT NULL,
    "ventaId" TEXT NOT NULL,
    "productoId" TEXT NOT NULL,
    "cantidad" INTEGER NOT NULL,
    "precioUnitario" DECIMAL(10,2) NOT NULL,
    "subtotal" DECIMAL(10,2) NOT NULL,

    CONSTRAINT "detalle_ventas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "historial_fisico" (
    "id" TEXT NOT NULL,
    "miembroId" TEXT NOT NULL,
    "peso" DOUBLE PRECISION NOT NULL,
    "estatura" DOUBLE PRECISION NOT NULL,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "historial_fisico_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "preferencias_alimentacion" (
    "miembroId" TEXT NOT NULL,
    "objetivo" TEXT,
    "tipoDieta" TEXT,
    "alimentosNoConsumidos" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "alergias" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "preferencias" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "presupuesto" DECIMAL(10,2),
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "preferencias_alimentacion_pkey" PRIMARY KEY ("miembroId")
);

-- CreateTable
CREATE TABLE "rutinas_generadas" (
    "id" TEXT NOT NULL,
    "miembroId" TEXT NOT NULL,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "objetivo" TEXT,
    "nivel" TEXT,
    "intensidad" TEXT,
    "contenidoGenerado" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rutinas_generadas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "recomendaciones_alimentarias" (
    "id" TEXT NOT NULL,
    "miembroId" TEXT NOT NULL,
    "fecha" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "tipoComida" "TipoComida" NOT NULL,
    "contenidoGenerado" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recomendaciones_alimentarias_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "historial_notificaciones" (
    "id" TEXT NOT NULL,
    "miembroId" TEXT NOT NULL,
    "titulo" TEXT NOT NULL,
    "mensaje" TEXT NOT NULL,
    "tipo" TEXT NOT NULL,
    "leida" BOOLEAN NOT NULL DEFAULT false,
    "fechaEnvio" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "historial_notificaciones_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "configuracion" (
    "clave" TEXT NOT NULL,
    "valor" JSONB NOT NULL,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "configuracion_pkey" PRIMARY KEY ("clave")
);

-- CreateTable
CREATE TABLE "_RolePermisos" (
    "A" TEXT NOT NULL,
    "B" TEXT NOT NULL
);

-- CreateIndex
CREATE UNIQUE INDEX "roles_nombre_key" ON "roles"("nombre");

-- CreateIndex
CREATE UNIQUE INDEX "permisos_modulo_accion_key" ON "permisos"("modulo", "accion");

-- CreateIndex
CREATE UNIQUE INDEX "usuarios_cedula_key" ON "usuarios"("cedula");

-- CreateIndex
CREATE INDEX "usuarios_estado_idx" ON "usuarios"("estado");

-- CreateIndex
CREATE INDEX "planes_miembroId_idx" ON "planes"("miembroId");

-- CreateIndex
CREATE INDEX "planes_estado_idx" ON "planes"("estado");

-- CreateIndex
CREATE INDEX "planes_fechaVencimiento_idx" ON "planes"("fechaVencimiento");

-- CreateIndex
CREATE INDEX "usos_tiquetera_planId_idx" ON "usos_tiquetera"("planId");

-- CreateIndex
CREATE INDEX "horarios_deporte_idx" ON "horarios"("deporte");

-- CreateIndex
CREATE UNIQUE INDEX "ingresos_ventaId_key" ON "ingresos"("ventaId");

-- CreateIndex
CREATE INDEX "ingresos_fecha_idx" ON "ingresos"("fecha");

-- CreateIndex
CREATE INDEX "ingresos_tipo_idx" ON "ingresos"("tipo");

-- CreateIndex
CREATE INDEX "gastos_fecha_idx" ON "gastos"("fecha");

-- CreateIndex
CREATE INDEX "gastos_categoria_idx" ON "gastos"("categoria");

-- CreateIndex
CREATE INDEX "productos_estado_idx" ON "productos"("estado");

-- CreateIndex
CREATE INDEX "ventas_fecha_idx" ON "ventas"("fecha");

-- CreateIndex
CREATE INDEX "historial_fisico_miembroId_idx" ON "historial_fisico"("miembroId");

-- CreateIndex
CREATE INDEX "rutinas_generadas_miembroId_idx" ON "rutinas_generadas"("miembroId");

-- CreateIndex
CREATE INDEX "recomendaciones_alimentarias_miembroId_idx" ON "recomendaciones_alimentarias"("miembroId");

-- CreateIndex
CREATE INDEX "historial_notificaciones_miembroId_idx" ON "historial_notificaciones"("miembroId");

-- CreateIndex
CREATE UNIQUE INDEX "_RolePermisos_AB_unique" ON "_RolePermisos"("A", "B");

-- CreateIndex
CREATE INDEX "_RolePermisos_B_index" ON "_RolePermisos"("B");

-- AddForeignKey
ALTER TABLE "usuarios" ADD CONSTRAINT "usuarios_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES "roles"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "planes" ADD CONSTRAINT "planes_miembroId_fkey" FOREIGN KEY ("miembroId") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "planes" ADD CONSTRAINT "planes_horarioId_fkey" FOREIGN KEY ("horarioId") REFERENCES "horarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "usos_tiquetera" ADD CONSTRAINT "usos_tiquetera_planId_fkey" FOREIGN KEY ("planId") REFERENCES "planes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "usos_tiquetera" ADD CONSTRAINT "usos_tiquetera_registradoPorId_fkey" FOREIGN KEY ("registradoPorId") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ingresos" ADD CONSTRAINT "ingresos_miembroId_fkey" FOREIGN KEY ("miembroId") REFERENCES "usuarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ingresos" ADD CONSTRAINT "ingresos_planId_fkey" FOREIGN KEY ("planId") REFERENCES "planes"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ingresos" ADD CONSTRAINT "ingresos_ventaId_fkey" FOREIGN KEY ("ventaId") REFERENCES "ventas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ingresos" ADD CONSTRAINT "ingresos_usuarioAdminId_fkey" FOREIGN KEY ("usuarioAdminId") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ventas" ADD CONSTRAINT "ventas_usuarioId_fkey" FOREIGN KEY ("usuarioId") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "detalle_ventas" ADD CONSTRAINT "detalle_ventas_ventaId_fkey" FOREIGN KEY ("ventaId") REFERENCES "ventas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "detalle_ventas" ADD CONSTRAINT "detalle_ventas_productoId_fkey" FOREIGN KEY ("productoId") REFERENCES "productos"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "historial_fisico" ADD CONSTRAINT "historial_fisico_miembroId_fkey" FOREIGN KEY ("miembroId") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "preferencias_alimentacion" ADD CONSTRAINT "preferencias_alimentacion_miembroId_fkey" FOREIGN KEY ("miembroId") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rutinas_generadas" ADD CONSTRAINT "rutinas_generadas_miembroId_fkey" FOREIGN KEY ("miembroId") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recomendaciones_alimentarias" ADD CONSTRAINT "recomendaciones_alimentarias_miembroId_fkey" FOREIGN KEY ("miembroId") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "historial_notificaciones" ADD CONSTRAINT "historial_notificaciones_miembroId_fkey" FOREIGN KEY ("miembroId") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_RolePermisos" ADD CONSTRAINT "_RolePermisos_A_fkey" FOREIGN KEY ("A") REFERENCES "permisos"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "_RolePermisos" ADD CONSTRAINT "_RolePermisos_B_fkey" FOREIGN KEY ("B") REFERENCES "roles"("id") ON DELETE CASCADE ON UPDATE CASCADE;
