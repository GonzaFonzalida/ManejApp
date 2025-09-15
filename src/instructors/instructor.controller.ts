import { Request, Response } from "express";
import  InstructorService from "./instructor.services";
import { ExpressFunction } from "../shared/types/ExpressFunction";
import CustomizedError from "@shared/classes/CustomizedError";

export default class InstructorController {
  constructor(private instructorService: InstructorService) {}

  register: ExpressFunction = async (req, res, next)=> {
    try {
      const instructor = await this.instructorService.registerInstructor(req.body);
      res.status(201).json(instructor);
    } catch (err) {
      next(err);
    }
  };
  updateProfile: ExpressFunction = async (req, res, next) => {
    try {
      const instructorId = Number(req.params.id);
      
      const updatedInstructor = await this.instructorService.updateInstructor(
        instructorId,
        req.body
      );

      if (!updatedInstructor) {
        return next(new CustomizedError("Instructor no encontrado", 404));
      }

      return res.json(updatedInstructor);
    } catch (err) {
      next(err);
    }
  };

  getProfile: ExpressFunction = async (req, res, next) => {
    try {
      const instructor = await this.instructorService.getInstructorProfile(Number(req.params.id));
      if (!instructor) {
        return next(new CustomizedError("Instructor no encontrado, ingrese un perfil válido", 404));
      }
      res.json(instructor);
    } catch (err) {
      next(err);
    }
  };

  list: ExpressFunction = async (req, res, next) => {
    try {
      const instructors = await this.instructorService.listInstructors();
      res.json(instructors);
    } catch (err) {
      next(err);
    }
  };
}
