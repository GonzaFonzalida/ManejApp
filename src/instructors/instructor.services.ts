import  {InstructorRepository} from "./repositories/InstructorRepository";

export default class InstructorService {
  constructor(private instructorRepo: InstructorRepository) {}

  async registerInstructor(data: {
    userId: number;
    licenseNumber: string;
    experienceYears: number;
    carId?: number;
  }) {
    return this.instructorRepo.createInstructor(data);
  }

  async getInstructorProfile(id: number) {
    return this.instructorRepo.getInstructorById(id);
  }

  async listInstructors(filter?: { available?: boolean; isValid?: boolean }) {
    return this.instructorRepo.listInstructors();
  }

  async assignCarToInstructor(instructorId: number, carId: number) {
    return this.instructorRepo.assignCar(instructorId, carId);
  }

  async removeCarFromInstructor(instructorId: number) {
    return this.instructorRepo.removeCar(instructorId);
  }

  async addPermission(instructorId: number, permissionId: number) {
    return this.instructorRepo.addPermission(instructorId, permissionId);
  }

  async validateIfHasAllPermissions(instructorId: number) {
    const hasAll = await this.instructorRepo.hasAllMandatoryPermissions(instructorId);
    if (hasAll) {
      return this.instructorRepo.validateInstructor(instructorId);
    }
    throw new Error("Instructor does not have all mandatory permissions.");
  }
}
