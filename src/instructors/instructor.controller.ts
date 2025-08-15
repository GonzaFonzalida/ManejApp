import { Request, Response } from "express";
import  InstructorService from "./instructor.services";

export default class InstructorController {
  constructor(private instructorService: InstructorService) {}

  register = async (req: Request, res: Response) => {
    try {
      const instructor = await this.instructorService.registerInstructor(req.body);
      res.status(201).json(instructor);
    } catch (err) {
      res.status(400).json({ error: (err as Error).message });
    }
  };

  getProfile = async (req: Request, res: Response) => {
    const instructor = await this.instructorService.getInstructorProfile(Number(req.params.id));
    if (!instructor) {
      return res.status(404).json({ error: "Instructor not found" });
    }
    res.json(instructor);
  };

  list = async (_req: Request, res: Response) => {
    const instructors = await this.instructorService.listInstructors();
    res.json(instructors);
  };
}
