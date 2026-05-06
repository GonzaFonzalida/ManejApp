import { prisma } from "@config/prismaClient";
import {
  instructorMeetsVerifiedAccountCriteria,
  type InstructorForPublishability,
} from "./instructorPublishable";

/**
 * Ajusta `isValid` según verificación documental + perfil mínimo.
 * - Con suspensión admin: solo baja a false si ya no cumple verificación (ej. doc rechazado).
 * - Sin suspensión: true si cumple todo, false si no.
 */
export async function syncInstructorAutoValidity(instructorId: number): Promise<void> {
  const row = await prisma.instructor.findUnique({
    where: { id: instructorId },
    include: {
      user: { select: { profileImage: true } },
      documentReviews: { select: { documentType: true, status: true } },
    },
  });
  if (!row) return;

  const asPub = row as unknown as InstructorForPublishability;
  const meets = instructorMeetsVerifiedAccountCriteria(asPub, row.user);

  if (row.validitySuspendedByAdmin) {
    if (!meets && row.isValid) {
      await prisma.instructor.update({
        where: { id: instructorId },
        data: { isValid: false },
      });
    }
    return;
  }

  if (row.isValid !== meets) {
    await prisma.instructor.update({
      where: { id: instructorId },
      data: { isValid: meets },
    });
  }
}
