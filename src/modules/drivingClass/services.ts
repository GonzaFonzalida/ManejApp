// src/modules/drivingClass/services/DrivingClassService.ts
import { DrivingClassRepository } from "./repositories/DrivingClassRepository";
import { DrivingClass } from "./entities/DrivingClass";
import { UserRepository } from "@users/repositories/userRepository";
import { prisma } from "@config/prismaClient";
import PrismaInstructorRepository from "../instructors/repositories/PrismaInstructorRepository";
import CustomizedError from "@shared/classes/CustomizedError";
import { BookingStatus, Role, SlotStatus } from "@prisma/client";
import { normalizeBookingStatus } from "@shared/utils/bookingStatus";
import { NotificationService } from "@notifications/service";

const ALLOWED_STATUS_TRANSITIONS: Record<BookingStatus, BookingStatus[]> = {
  [BookingStatus.PENDING_PAYMENT]: [BookingStatus.CONFIRMED, BookingStatus.CANCELLED],
  [BookingStatus.CONFIRMED]: [BookingStatus.CANCELLED, BookingStatus.COMPLETED],
  [BookingStatus.CANCELLED]: [],
  [BookingStatus.COMPLETED]: [],
};

function canTransitionBookingStatus(from: BookingStatus, to: BookingStatus): boolean {
  if (from === to) return true;
  return ALLOWED_STATUS_TRANSITIONS[from].includes(to);
}

const CANCEL_WINDOW_HOURS = 6;
const RESCHEDULE_WINDOW_HOURS = 12;

type ReservationScope = "all" | "upcoming" | "history";
type ViewerType = "STUDENT" | "INSTRUCTOR";

export interface PremiumReservationView {
  id: number;
  status: BookingStatus;
  paymentStatus: string;
  slotStatus: SlotStatus | "UNASSIGNED";
  canCancel: boolean;
  canReschedule: boolean;
  cancelDeadline: string | null;
  rescheduleDeadline: string | null;
  nextRecommendedAction: string;
  policySummary: {
    cancelWindowHours: number;
    rescheduleWindowHours: number;
    text: string;
  };
  priceSummary: {
    amount: number | null;
    currency: string | null;
    hourlyRate: number | null;
    estimatedTotalLabel: string;
  };
  durationMinutes: number;
  startsAt: string;
  endsAt: string;
  instructorSnapshot: {
    id: number;
    name: string | null;
    surname: string | null;
    hourlyRate: number | null;
    bio: string | null;
    addressText: string | null;
    lat: number | null;
    lng: number | null;
  };
  studentSnapshot: {
    id: number;
    name: string | null;
    surname: string | null;
    experienceLevel: number | null;
  };
  location: {
    addressText: string | null;
    lat: number | null;
    lng: number | null;
    zoneLabel: string | null;
  };
  legacy: {
    instructorId: number;
    studentId: number;
    date: string;
    duration: number;
    amount: number | null;
    currency: string | null;
  };
}

function formatClassWhen(d: Date): string {
  return d.toLocaleString("es-AR", {
    weekday: "short",
    day: "numeric",
    month: "short",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export class DrivingClassService {
  constructor(
    private readonly userRepo: UserRepository,
    private readonly instructorRepo: PrismaInstructorRepository,
    private readonly drivingClassRepo: DrivingClassRepository,
    private readonly notificationService: NotificationService
  ) {}

async create(data: Omit<DrivingClass, "id" | "createdAt" | "updatedAt">): Promise<DrivingClass> {
  try {
    // Validar que el estudiante exista en Student
    const studentExists = await prisma.student.findUnique({
      where: { id: data.studentId }
    });
    if (!studentExists) throw new CustomizedError("El estudiante no existe", 404);

    // Validar que el instructor exista
    const instructorExists = await prisma.instructor.findUnique({
      where: { id: data.instructorId }
    });
    if (!instructorExists) throw new CustomizedError("El instructor no existe", 404);

    const normalizedStatus = normalizeBookingStatus(String(data.status));
    if (!normalizedStatus) {
      throw new CustomizedError("Estado de reserva inválido", 400);
    }

    // Crear la clase
    return this.drivingClassRepo.create({
      studentId: data.studentId,
      instructorId: data.instructorId,
      date: new Date(data.date),
      duration: data.duration,
      status: normalizedStatus,
      notes: data.notes ?? null,
      amount: data.amount ?? undefined,
      currency: data.currency ?? undefined,
    });

  } catch (e: any) {
    if (e.code === "P2003") {
      throw new CustomizedError("Violación de clave foránea: estudiante o instructor no existe", 400);
    }
    throw e;
  }
}

  /**
   * Resuelve studentId / instructorId para filtros y autorización.
   * Para STUDENT: si el usuario tiene rol alumno pero aún no existe fila `Student`
   * (registros viejos, migraciones o paths que no la crearon), la creamos con upsert
   * y devolvemos lista vacía de reservas en lugar de 404 — mismo contrato que “alumno sin reservas”.
   */
  private async resolveActorIds(userId: number, role: Role): Promise<{ studentId?: number; instructorId?: number }> {
    if (role === "STUDENT") {
      const student = await prisma.student.upsert({
        where: { userId },
        create: { userId },
        update: {},
        select: { id: true },
      });
      return { studentId: student.id };
    }

    if (role === "INSTRUCTOR") {
      const instructor = await prisma.instructor.findUnique({
        where: { userId },
        select: { id: true },
      });
      if (!instructor) throw new CustomizedError("Perfil de instructor no encontrado", 404);
      return { instructorId: instructor.id };
    }

    return {};
  }

  private buildWhereForScope(
    actorIds: { studentId?: number; instructorId?: number },
    scope: ReservationScope
  ): Record<string, unknown> {
    const now = new Date();
    const where: Record<string, unknown> = {};
    if (actorIds.studentId) where.studentId = actorIds.studentId;
    if (actorIds.instructorId) where.instructorId = actorIds.instructorId;

    if (scope === "upcoming") {
      where.AND = [
        { date: { gte: now } },
        { status: { in: [BookingStatus.PENDING_PAYMENT, BookingStatus.CONFIRMED] } },
      ];
    } else if (scope === "history") {
      where.OR = [
        { date: { lt: now } },
        { status: { in: [BookingStatus.CANCELLED, BookingStatus.COMPLETED] } },
      ];
    }
    return where;
  }

  private nextActionFor(
    viewer: ViewerType,
    status: BookingStatus,
    paymentStatus: string,
    canCancel: boolean
  ): string {
    if (status === BookingStatus.PENDING_PAYMENT) {
      if (viewer === "STUDENT" && paymentStatus === "pending") return "COMPLETE_PAYMENT";
      return "WAIT_FOR_PAYMENT_CONFIRMATION";
    }
    if (status === BookingStatus.CONFIRMED) {
      if (canCancel) return "VIEW_CLASS_DETAILS";
      return "PREPARE_FOR_CLASS";
    }
    if (status === BookingStatus.CANCELLED) {
      return viewer === "STUDENT" ? "BOOK_ANOTHER_CLASS" : "OPEN_NEW_AVAILABILITY_SLOT";
    }
    if (status === BookingStatus.COMPLETED) {
      return viewer === "STUDENT" ? "LEAVE_FEEDBACK" : "REVIEW_CLASS_HISTORY";
    }
    return "NO_ACTION";
  }

  private toPremiumReservationView(
    row: {
      id: number;
      status: BookingStatus;
      studentId: number;
      instructorId: number;
      date: Date;
      duration: number;
      amount: number | null;
      currency: string | null;
      instructor: {
        id: number;
        hourlyRate: number | null;
        bio: string | null;
        addressText: string | null;
        lat: number | null;
        lng: number | null;
        user: {
          name: string | null;
          surname: string | null;
        };
      };
      student: {
        id: number;
        experienceLevel: number;
        user: {
          name: string | null;
          surname: string | null;
        };
      };
      scheduleSlot: {
        status: SlotStatus;
      } | null;
      payments: {
        status: string;
      }[];
    },
    viewer: ViewerType
  ): PremiumReservationView {
    const startsAt = row.date;
    const endsAt = new Date(startsAt.getTime() + row.duration * 60 * 1000);
    const cancelDeadline = new Date(startsAt.getTime() - CANCEL_WINDOW_HOURS * 60 * 60 * 1000);
    const rescheduleDeadline = new Date(startsAt.getTime() - RESCHEDULE_WINDOW_HOURS * 60 * 60 * 1000);
    const now = new Date();

    const paymentStatus = row.payments[0]?.status ?? "unpaid";
    const slotStatus = row.scheduleSlot?.status ?? "UNASSIGNED";

    const canCancel =
      (row.status === BookingStatus.PENDING_PAYMENT || row.status === BookingStatus.CONFIRMED) &&
      now < startsAt &&
      now <= cancelDeadline;

    const canReschedule = false;
    const amount = row.amount ?? null;
    const currency = row.currency ?? "ARS";
    const hourlyRate = row.instructor.hourlyRate ?? null;
    const estimatedTotalLabel =
      amount == null ? "Monto pendiente de definición" : `${currency} ${Math.round(amount).toLocaleString("es-AR")}`;

    const nextRecommendedAction = this.nextActionFor(viewer, row.status, paymentStatus, canCancel);

    return {
      id: row.id,
      status: row.status,
      paymentStatus,
      slotStatus,
      canCancel,
      canReschedule,
      cancelDeadline: cancelDeadline.toISOString(),
      rescheduleDeadline: rescheduleDeadline.toISOString(),
      nextRecommendedAction,
      policySummary: {
        cancelWindowHours: CANCEL_WINDOW_HOURS,
        rescheduleWindowHours: RESCHEDULE_WINDOW_HOURS,
        text: `Cancelación permitida hasta ${CANCEL_WINDOW_HOURS}h antes. Reprogramación hasta ${RESCHEDULE_WINDOW_HOURS}h antes (próximamente).`,
      },
      priceSummary: {
        amount,
        currency,
        hourlyRate,
        estimatedTotalLabel,
      },
      durationMinutes: row.duration,
      startsAt: startsAt.toISOString(),
      endsAt: endsAt.toISOString(),
      instructorSnapshot: {
        id: row.instructor.id,
        name: row.instructor.user.name,
        surname: row.instructor.user.surname,
        hourlyRate: row.instructor.hourlyRate,
        bio: row.instructor.bio,
        addressText: row.instructor.addressText,
        lat: row.instructor.lat,
        lng: row.instructor.lng,
      },
      studentSnapshot: {
        id: row.student.id,
        name: row.student.user.name,
        surname: row.student.user.surname,
        experienceLevel: row.student.experienceLevel,
      },
      location: {
        addressText: row.instructor.addressText,
        lat: row.instructor.lat,
        lng: row.instructor.lng,
        zoneLabel: row.instructor.addressText,
      },
      legacy: {
        instructorId: row.instructorId,
        studentId: row.studentId,
        date: row.date.toISOString(),
        duration: row.duration,
        amount: row.amount ?? null,
        currency: row.currency ?? null,
      },
    };
  }

  private async listPremiumReservations(
    userId: number,
    role: Role,
    viewer: ViewerType,
    scope: ReservationScope
  ): Promise<PremiumReservationView[]> {
    const actorIds = await this.resolveActorIds(userId, role);
    const where = this.buildWhereForScope(actorIds, scope);

    const rows = await prisma.drivingClass.findMany({
      where,
      include: {
        instructor: {
          include: {
            user: {
              select: {
                name: true,
                surname: true,
              },
            },
          },
        },
        student: {
          include: {
            user: {
              select: {
                name: true,
                surname: true,
              },
            },
          },
        },
        scheduleSlot: {
          select: {
            status: true,
          },
        },
        payments: {
          select: {
            status: true,
            createdAt: true,
          },
          orderBy: {
            createdAt: "desc",
          },
        },
      },
      orderBy: { date: "desc" },
    });

    return rows.map((row) => this.toPremiumReservationView(row, viewer));
  }

  async listStudentReservationsPremium(
    userId: number,
    scope: ReservationScope
  ): Promise<PremiumReservationView[]> {
    return this.listPremiumReservations(userId, "STUDENT", "STUDENT", scope);
  }

  async listInstructorReservationsPremium(
    userId: number,
    scope: ReservationScope
  ): Promise<PremiumReservationView[]> {
    return this.listPremiumReservations(userId, "INSTRUCTOR", "INSTRUCTOR", scope);
  }

  private async getPremiumReservationDetailByRole(
    id: number,
    userId: number,
    role: Role,
    viewer: ViewerType
  ): Promise<PremiumReservationView | null> {
    const cls = await this.getClassByIdForUser(id, userId, role);
    if (!cls) return null;

    const row = await prisma.drivingClass.findUnique({
      where: { id },
      include: {
        instructor: {
          include: {
            user: {
              select: {
                name: true,
                surname: true,
              },
            },
          },
        },
        student: {
          include: {
            user: {
              select: {
                name: true,
                surname: true,
              },
            },
          },
        },
        scheduleSlot: {
          select: {
            status: true,
          },
        },
        payments: {
          select: {
            status: true,
            createdAt: true,
          },
          orderBy: {
            createdAt: "desc",
          },
        },
      },
    });
    if (!row) return null;
    return this.toPremiumReservationView(row, viewer);
  }

  async getStudentReservationDetailPremium(id: number, userId: number): Promise<PremiumReservationView | null> {
    return this.getPremiumReservationDetailByRole(id, userId, "STUDENT", "STUDENT");
  }

  async getInstructorReservationDetailPremium(id: number, userId: number): Promise<PremiumReservationView | null> {
    return this.getPremiumReservationDetailByRole(id, userId, "INSTRUCTOR", "INSTRUCTOR");
  }

  async listClassesByRole(
    userId: number,
    role: Role,
    scope: "all" | "upcoming" | "history" = "all"
  ): Promise<DrivingClass[]> {
    const actorIds = await this.resolveActorIds(userId, role);
    const where = this.buildWhereForScope(actorIds, scope);

    const rows = await prisma.drivingClass.findMany({
      where,
      include: {
        student: { include: { user: true } },
      },
      orderBy: { date: "desc" },
    });

    return rows.map((row) => {
      const { student: st, ...rest } = row;
      let studentPayload: Record<string, unknown> | undefined;
      if (st?.user) {
        studentPayload = {
          id: st.user.id,
          name: st.user.name,
          surname: st.user.surname,
          email: st.user.email,
          role: st.user.role,
          experienceLevel: st.experienceLevel,
        };
      }
      return {
        ...rest,
        student: studentPayload,
      } as unknown as DrivingClass;
    });
  }

  async listClasses(): Promise<DrivingClass[]> {
    return this.drivingClassRepo.findAll();
  }

  async getClassById(id: number): Promise<DrivingClass | null> {
    return this.drivingClassRepo.findById(id);
  }

  async getClassByIdForUser(id: number, userId: number, role: Role): Promise<DrivingClass | null> {
    const cls = await this.getClassById(id);
    if (!cls) return null;

    if (role === "ADMIN") return cls;

    const actorIds = await this.resolveActorIds(userId, role);
    if (actorIds.studentId && cls.studentId !== actorIds.studentId) {
      throw new CustomizedError("No autorizado para ver esta clase", 403);
    }
    if (actorIds.instructorId && cls.instructorId !== actorIds.instructorId) {
      throw new CustomizedError("No autorizado para ver esta clase", 403);
    }

    return cls;
  }

  async updateClass(id: number, data: Partial<DrivingClass>): Promise<DrivingClass> {
    const current = await this.drivingClassRepo.findById(id);
    if (!current) throw new CustomizedError("Clase no encontrada", 404);

    const payload: Partial<DrivingClass> = { ...data };
    if (data.status !== undefined) {
      const normalizedStatus = normalizeBookingStatus(String(data.status));
      if (!normalizedStatus) {
        throw new CustomizedError("Estado de reserva inválido", 400);
      }
      if (!canTransitionBookingStatus(current.status, normalizedStatus)) {
        throw new CustomizedError(
          `Transición inválida de estado: ${current.status} -> ${normalizedStatus}`,
          409
        );
      }
      payload.status = normalizedStatus;
    }

    return this.drivingClassRepo.update(id, payload);
  }

  async cancelClass(id: number): Promise<void> {
    await this.drivingClassRepo.update(id, { status: BookingStatus.CANCELLED });
  }

  async cancelClassForUser(id: number, userId: number, role: Role): Promise<{ alreadyCancelled: boolean }> {
    const actorIds = await this.resolveActorIds(userId, role);

    const result = await prisma.$transaction(async (tx) => {
      const booking = await tx.drivingClass.findUnique({
        where: { id },
        include: {
          scheduleSlot: true,
        },
      });
      if (!booking) throw new CustomizedError("Clase no encontrada", 404);

      if (role !== "ADMIN") {
        if (actorIds.studentId && booking.studentId !== actorIds.studentId) {
          throw new CustomizedError("No autorizado para cancelar esta clase", 403);
        }
        if (actorIds.instructorId && booking.instructorId !== actorIds.instructorId) {
          throw new CustomizedError("No autorizado para cancelar esta clase", 403);
        }
      }

      if (booking.status === BookingStatus.CANCELLED) {
        return { alreadyCancelled: true };
      }

      if (!canTransitionBookingStatus(booking.status, BookingStatus.CANCELLED)) {
        throw new CustomizedError(`No se puede cancelar una clase en estado ${booking.status}`, 409);
      }

      await tx.drivingClass.update({
        where: { id: booking.id },
        data: { status: BookingStatus.CANCELLED },
      });

      await tx.payment.updateMany({
        where: {
          drivingClassId: booking.id,
          status: {
            notIn: ["cancelled", "failed", "rejected", "refunded", "charged_back"],
          },
        },
        data: { status: "cancelled" },
      });

      if (booking.scheduleSlot && booking.scheduleSlot.status !== SlotStatus.BLOCKED) {
        await tx.scheduleSlot.update({
          where: { id: booking.scheduleSlot.id },
          data: {
            status: SlotStatus.AVAILABLE,
            heldUntil: null,
            drivingClassId: null,
          },
        });
      }

      return { alreadyCancelled: false, booking };
    });

    if (!result.alreadyCancelled && "booking" in result && result.booking) {
      const b = result.booking as {
        id: number;
        date: Date;
        studentId: number;
        instructorId: number;
      };
      const when = formatClassWhen(b.date);
      void (async () => {
        try {
          const stu = await prisma.student.findUnique({
            where: { id: b.studentId },
            include: { user: { select: { name: true, surname: true } } },
          });
          const instr = await prisma.instructor.findUnique({
            where: { id: b.instructorId },
            include: { user: { select: { name: true, surname: true } } },
          });
          if (role === "STUDENT" && instr) {
            await this.notificationService.sendPushToUser(
              instr.userId,
              "Clase cancelada",
              `Un alumno canceló la clase del ${when}. El horario quedó libre.`,
              { type: "instructor_booking", bookingId: String(b.id), role: "INSTRUCTOR" }
            );
          } else if (role === "INSTRUCTOR" && stu) {
            await this.notificationService.sendPushToUser(
              stu.userId,
              "Clase cancelada",
              `Tu instructor canceló la clase del ${when}. Si tenés dudas, contactalo desde la app.`,
              { type: "student_booking", bookingId: String(b.id), role: "STUDENT" }
            );
          } else if (role === "ADMIN") {
            if (stu) {
              await this.notificationService.sendPushToUser(
                stu.userId,
                "Clase cancelada",
                `Se canceló administrativamente tu clase del ${when}.`,
                { type: "student_booking", bookingId: String(b.id), role: "STUDENT" }
              );
            }
            if (instr) {
              await this.notificationService.sendPushToUser(
                instr.userId,
                "Clase cancelada",
                `Se canceló administrativamente una clase del ${when}.`,
                { type: "instructor_booking", bookingId: String(b.id), role: "INSTRUCTOR" }
              );
            }
          }
        } catch {
          /* no bloquear cancelación */
        }
      })();
    }

    return { alreadyCancelled: result.alreadyCancelled };
  }

  async deleteClass(id: number): Promise<void> {
    await this.drivingClassRepo.delete(id);
  }
}
