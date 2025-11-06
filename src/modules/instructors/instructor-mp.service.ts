import { prisma } from '@config/prismaClient';
import CustomizedError from '@shared/classes/CustomizedError';
import { AuditService, AuditAction } from '@shared/services/AuditService';

export interface InstructorMPData {
  mpCollectorId: string;
  mpAccessToken?: string;
}

export default class InstructorMPService {
  async linkMercadoPagoAccount(instructorId: number, mpData: InstructorMPData, userId?: number): Promise<void> {
    const instructor = await prisma.instructor.findUnique({
      where: { id: instructorId },
      include: { user: true }
    });

    if (!instructor) {
      throw new CustomizedError('Instructor no encontrado', 404);
    }

    // Update instructor with MP data
    await prisma.instructor.update({
      where: { id: instructorId },
      data: {
        mpCollectorId: mpData.mpCollectorId,
        mpAccessToken: mpData.mpAccessToken
      }
    });

    // Audit log
    AuditService.logUserAction(
      userId || instructor.userId,
      AuditAction.UPDATE,
      'instructor_mp_link',
      instructorId,
      { mpCollectorId: mpData.mpCollectorId }
    );
  }

  async unlinkMercadoPagoAccount(instructorId: number, userId?: number): Promise<void> {
    const instructor = await prisma.instructor.findUnique({
      where: { id: instructorId }
    });

    if (!instructor) {
      throw new CustomizedError('Instructor no encontrado', 404);
    }

    await prisma.instructor.update({
      where: { id: instructorId },
      data: {
        mpCollectorId: null,
        mpAccessToken: null
      }
    });

    // Audit log
    AuditService.logUserAction(
      userId || instructor.userId,
      AuditAction.UPDATE,
      'instructor_mp_unlink',
      instructorId,
      {}
    );
  }

  async getInstructorMPStatus(instructorId: number): Promise<{
    hasLinkedAccount: boolean;
    mpCollectorId?: string;
    canReceivePayments: boolean;
  }> {
    const instructor = await prisma.instructor.findUnique({
      where: { id: instructorId },
      select: {
        mpCollectorId: true,
        isValid: true
      }
    });

    if (!instructor) {
      throw new CustomizedError('Instructor no encontrado', 404);
    }

    return {
      hasLinkedAccount: !!instructor.mpCollectorId,
      mpCollectorId: instructor.mpCollectorId || undefined,
      canReceivePayments: !!instructor.mpCollectorId && instructor.isValid
    };
  }

  async getInstructorsWithoutMP(): Promise<Array<{
    id: number;
    name: string;
    surname: string;
    email: string;
  }>> {
    const instructors = await prisma.instructor.findMany({
      where: {
        mpCollectorId: null,
        isValid: true
      },
      include: {
        user: {
          select: {
            name: true,
            surname: true,
            email: true
          }
        }
      }
    });

    return instructors.map(instructor => ({
      id: instructor.id,
      name: instructor.user.name,
      surname: instructor.user.surname,
      email: instructor.user.email
    }));
  }
}