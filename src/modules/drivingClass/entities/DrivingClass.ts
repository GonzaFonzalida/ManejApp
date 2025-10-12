export interface DrivingClass {
  id: number;
  instructorId: number;
  studentId: number;
  date: Date;
  notes: string | null;
  duration: number; // en minutos
  status: "scheduled" | "completed" | "cancelled" | string;
}
