// src/permissions/controller/permission.controller.ts
import { Request, Response } from "express";
import { PermissionService } from "./permissions.services";
import CustomizedError from "@shared/classes/CustomizedError";
import { ExpressFunction } from "@shared/types/ExpressFunction";

export class PermissionController {
  constructor(private service: PermissionService) {}

  /**
   * @swagger
   * /permissions:
   *   post:
   *     summary: Create a new permission
   *     tags: [Permissions]
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - name
   *               - description
   *               - isMandatory
   *             properties:
   *               name:
   *                 type: string
   *                 minLength: 1
   *               description:
   *                 type: string
   *                 minLength: 1
   *               isMandatory:
   *                 type: boolean
   *     responses:
   *       201:
   *         description: Permission created successfully
   *       400:
   *         description: Invalid permission data
   *       500:
   *         description: Internal server error
   */
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

  /**
   * @swagger
   * /permissions/{id}:
   *   put:
   *     summary: Update permission by ID
   *     tags: [Permissions]
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema:
   *           type: integer
   *         description: Permission ID
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             properties:
   *               name:
   *                 type: string
   *               description:
   *                 type: string
   *               isMandatory:
   *                 type: boolean
   *     responses:
   *       200:
   *         description: Permission updated successfully
   *       400:
   *         description: Invalid ID or no changes provided
   *       404:
   *         description: Permission not found
   *       500:
   *         description: Internal server error
   */
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


  /**
   * @swagger
   * /permissions:
   *   get:
   *     summary: Get all permissions
   *     tags: [Permissions]
   *     responses:
   *       200:
   *         description: Permissions retrieved successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: array
   *               items:
   *                 type: object
   *       500:
   *         description: Internal server error
   */
  getAll : ExpressFunction = async (req, res) => {
    const permissions = await this.service.getAllPermissions();
    res.json(permissions);
  };

  /**
   * @swagger
   * /permissions/{id}:
   *   get:
   *     summary: Get permission by ID
   *     tags: [Permissions]
   *     parameters:
   *       - in: path
   *         name: id
   *         required: true
   *         schema:
   *           type: integer
   *         description: Permission ID
   *     responses:
   *       200:
   *         description: Permission retrieved successfully
   *       400:
   *         description: Invalid ID
   *       404:
   *         description: Permission not found
   *       500:
   *         description: Internal server error
   */
  getById : ExpressFunction= async (req, res) => {
    const id = Number(req.params.id);
    if (isNaN(id)) throw new CustomizedError("El id es invalido", 400);

    const permission = await this.service.getPermission(id);
    if (!permission) throw new CustomizedError("Permiso no encontrado", 404);

    res.json(permission);
  };

  delete: ExpressFunction = async (req, res, next) => {
    try {
      const id = Number(req.params.id);
      if (isNaN(id)) throw new CustomizedError("El id es inválido", 400);

      const deleted = await this.service.deletePermission(id);
      if (!deleted) throw new CustomizedError("Permiso no encontrado o no se pudo eliminar", 404);

      res.status(204).send();
    } catch (error) {
      next(error);
    }
  };
}
