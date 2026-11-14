/*
  Warnings:

  - Changed the type of `categoria` on the `gastos` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `metodoPago` on the `gastos` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `metodoPago` on the `ingresos` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `metodoPago` on the `planes` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `metodoPago` on the `ventas` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- AlterTable
ALTER TABLE "gastos" DROP COLUMN "categoria",
ADD COLUMN     "categoria" TEXT NOT NULL,
DROP COLUMN "metodoPago",
ADD COLUMN     "metodoPago" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "ingresos" DROP COLUMN "metodoPago",
ADD COLUMN     "metodoPago" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "planes" DROP COLUMN "metodoPago",
ADD COLUMN     "metodoPago" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "preferencias_alimentacion" ADD COLUMN     "alimentosNoGustan" TEXT[] DEFAULT ARRAY[]::TEXT[],
ADD COLUMN     "numeroComidas" INTEGER,
ADD COLUMN     "restricciones" TEXT[] DEFAULT ARRAY[]::TEXT[];

-- AlterTable
ALTER TABLE "ventas" DROP COLUMN "metodoPago",
ADD COLUMN     "metodoPago" TEXT NOT NULL;

-- DropEnum
DROP TYPE "CategoriaGasto";

-- DropEnum
DROP TYPE "MetodoPago";

-- CreateTable
CREATE TABLE "perfil_entrenamiento" (
    "miembroId" TEXT NOT NULL,
    "objetivo" TEXT,
    "nivel" TEXT,
    "lesiones" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "equipamiento" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "diasDisponibles" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "minutosPorSesion" INTEGER,
    "preferencias" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "perfil_entrenamiento_pkey" PRIMARY KEY ("miembroId")
);

-- CreateIndex
CREATE INDEX "gastos_categoria_idx" ON "gastos"("categoria");

-- AddForeignKey
ALTER TABLE "perfil_entrenamiento" ADD CONSTRAINT "perfil_entrenamiento_miembroId_fkey" FOREIGN KEY ("miembroId") REFERENCES "usuarios"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
