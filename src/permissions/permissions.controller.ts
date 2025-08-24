// src/permissions/controller/permission.controller.ts
import { Request, Response } from "express";
import { PermissionService } from "./permissions.services";
import CustomizedError from "@shared/classes/CustomizedError";
import { ExpressFunction } from "../shared/types/ExpressFunction";

export class PermissionController {
  constructor(private service: PermissionService) {}

  create : ExpressFunction = async (req, res, next) => {
    try {
      const { name, description, isMandatory } = req.body;
      if (!name || !description || typeof isMandatory !== "boolean") {
        return next( new CustomizedError("Invalid permission data", 400));
      }

      const permission = await this.service.createPermission({name, description, isMandatory });
      return res.status(201).json(permission);
    } catch (error: Error | CustomizedError | any) {
      if (error instanceof CustomizedError) {
        return res.status(error.statusCode).json({ error: error.message });
      } else {
        return res.status(500).json({ error: "Internal Server Error" });
      }
    }
  };

  update: ExpressFunction = async (req, res, next) => {
    try {
        const userId = Number(req.params.id);
        const userChanges = req.body;

        if (isNaN(userId)) throw new CustomizedError("El id es inválido", 400);
        if (!userChanges || Object.keys(userChanges).length === 0) 
            throw new CustomizedError("Ingrese cambio a realizar por el body", 400);

        const updatedUser = await this.service.updatePermission(userId, userChanges);

        if (!updatedUser) {
            return next( new CustomizedError("El Permiso no se pudo actualizar", 404));
        }

        return res.json(updatedUser);
    } catch (error) {
        next(error); // Pasamos el error al middleware de manejo de errores
    }
   };


  getAll : ExpressFunction = async (req, res) => {
    const permissions = await this.service.getAllPermissions();
    res.json(permissions);
  };

  getById : ExpressFunction= async (req, res) => {
    const id = Number(req.params.id);
    if (isNaN(id)) throw new CustomizedError("El id es invalido", 400);

    const permission = await this.service.getPermission(id);
    if (!permission) throw new CustomizedError("Permiso no encontrado", 404);

    res.json(permission);
  };
}
