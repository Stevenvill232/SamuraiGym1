import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const ROLES = ['ADMINISTRADOR', 'MIEMBRO', 'RECEPCION', 'ENTRENADOR', 'CONTADOR'];

async function main() {
  console.log('Creando roles base...');
  for (const nombre of ROLES) {
    await prisma.role.upsert({
      where: { nombre },
      update: {},
      create: { nombre },
    });
  }

  const adminRole = await prisma.role.findUniqueOrThrow({
    where: { nombre: 'ADMINISTRADOR' },
  });

  const cedulaAdmin = '0000000000';
  const existente = await prisma.user.findUnique({
    where: { cedula: cedulaAdmin },
  });

  if (!existente) {
    console.log('Creando usuario administrador inicial...');
    const passwordHash = await bcrypt.hash('Admin123!', 10);
    await prisma.user.create({
      data: {
        cedula: cedulaAdmin,
        nombres: 'Administrador',
        apellidos: 'Sistema',
        passwordHash,
        roleId: adminRole.id,
      },
    });
    console.log('✔ Admin creado -> cédula: 0000000000 / password: Admin123!');
    console.log('  ⚠ Cambia esta contraseña apenas inicies sesión.');
  } else {
    console.log('El usuario administrador ya existía, no se modifica.');
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
