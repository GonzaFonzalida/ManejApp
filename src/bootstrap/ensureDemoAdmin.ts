import bcrypt from "bcryptjs";
import { prisma } from "@config/prismaClient";
import { NODE_ENV } from "@config/config";

/** Misma convención que `scripts/reset-admin-password.js`. */
const ADMIN_EMAIL = "admin@manejapp.com";
const DEMO_PASSWORD = "1qazxsw2";
const DEMO_ADMIN_DNI = "99999001";

/**
 * En desarrollo/test, garantiza que exista el admin de demo para login en manejapp-admin / API.
 * En producción no hace nada. Deshabilitar: `ENSURE_DEMO_ADMIN=0`.
 */
export async function ensureDemoAdmin(): Promise<void> {
  if (NODE_ENV === "production") return;
  if (process.env.ENSURE_DEMO_ADMIN === "0") return;

  const hashedPassword = await bcrypt.hash(DEMO_PASSWORD, 10);

  let user = await prisma.user.findUnique({
    where: { email: ADMIN_EMAIL },
    include: { admin: true },
  });

  if (!user) {
    const existingDni = await prisma.user.findUnique({
      where: { dni: DEMO_ADMIN_DNI },
    });
    if (existingDni) {
      console.warn(
        "[ensureDemoAdmin] Ya existe un usuario con DNI demo; no se crea admin@manejapp.com. Ejecutá manualmente: pnpm run reset:admin",
      );
      return;
    }

    user = await prisma.user.create({
      data: {
        name: "Admin",
        surname: "ManejApp",
        email: ADMIN_EMAIL,
        password: hashedPassword,
        dni: DEMO_ADMIN_DNI,
        birthDate: new Date("1990-01-01"),
        role: "ADMIN",
        isActive: true,
      },
      include: { admin: true },
    });

    await prisma.admin.create({
      data: { id: user.id, companyName: "ManejApp" },
    });

    console.log("[ensureDemoAdmin] Usuario administrador de demo creado:", ADMIN_EMAIL);
    return;
  }

  await prisma.user.update({
    where: { id: user.id },
    data: { password: hashedPassword, isActive: true },
  });

  if (!user.admin) {
    await prisma.admin.create({
      data: { id: user.id, companyName: "ManejApp" },
    });
  }
}
