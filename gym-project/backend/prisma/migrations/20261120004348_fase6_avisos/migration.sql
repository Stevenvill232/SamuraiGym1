/*
  Warnings:

  - A unique constraint covering the columns `[claveUnica]` on the table `historial_notificaciones` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "historial_notificaciones" ADD COLUMN     "claveUnica" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "historial_notificaciones_claveUnica_key" ON "historial_notificaciones"("claveUnica");
