// C:\Users\thiag\Desktop\Back\ManejApp\src\users\user.controller.ts

import UserService from "./user.services";
import { UserWithOutPassword, User, UserWithOutId, UserWithDates } from "./user.types";
import { ExpressFunction } from "@sharedTypes/ExpressFunction";
import CustomizedError from "@classes/CustomizedError";

export default class UserController {
    constructor(private userService: UserService) { }

    /**
     * @swagger
     * /users/register:
     *   post:
     *     summary: Register a new user
     *     tags: [Users]
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             required:
     *               - name
     *               - surname
     *               - email
     *               - dni
     *               - password
     *               - birthDate
     *             properties:
     *               name:
     *                 type: string
     *                 minLength: 1
     *               surname:
     *                 type: string
     *                 minLength: 1
     *               email:
     *                 type: string
     *                 format: email
     *               dni:
     *                 type: string
     *                 minLength: 1
     *               password:
     *                 type: string
     *                 minLength: 8
     *               birthDate:
     *                 type: string
     *                 minLength: 1
     *     responses:
     *       201:
     *         description: User registered successfully
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 token:
     *                   type: string
     *       409:
     *         description: User already exists
     *       500:
     *         description: Internal server error
     */
    public register: ExpressFunction = async (req, res, next) => {

            const user: UserWithDates = req.body;
            const newUser = await this.userService.register(user);
            // Si el registro es exitoso, devolvemos el token
            if (newUser.name == "PrismaClientKnownRequestError"){
                return next(new CustomizedError("El usuario que intenta registrar ya existe", 409))
            }

            res.status(201).json({
                token: newUser,
            });

    };

    /**
     * @swagger
     * /users:
     *   get:
     *     summary: Get all users
     *     tags: [Users]
     *     responses:
     *       200:
     *         description: Users retrieved successfully
     *         content:
     *           application/json:
     *             schema:
     *               type: array
     *               items:
     *                 type: object
     *       500:
     *         description: Internal server error
     */
    public getAll: ExpressFunction = async (req, res, next) => {
        try{
            const users = await this.userService.getAllUsers();
            return res.json(users);
        } catch (e){
            // Pasamos cualquier error al siguiente middleware de error
            next(e);
        }
    };

    /**
     * @swagger
     * /users/role/{role}:
     *   get:
     *     summary: Get users by role
     *     tags: [Users]
     *     parameters:
     *       - in: path
     *         name: role
     *         required: true
     *         schema:
     *           type: string
     *           enum: [STUDENT, INSTRUCTOR, ADMIN]
     *         description: User role
     *     responses:
     *       200:
     *         description: Users retrieved successfully
     *         content:
     *           application/json:
     *             schema:
     *               type: array
     *               items:
     *                 type: object
     *       500:
     *         description: Internal server error
     */
    public getByRol: ExpressFunction = async (req, res, next) => {
        try{
            const role = req.params.role

            const users = await this.userService.findByRole(role.toUpperCase());
            return res.json(users);
        } catch (e){

            next(e);
        }
    };

    /**
     * @swagger
     * /users/{value}:
     *   get:
     *     summary: Get user by ID or email
     *     tags: [Users]
     *     parameters:
     *       - in: path
     *         name: value
     *         required: true
     *         schema:
     *           type: string
     *         description: User ID or email
     *     responses:
     *       200:
     *         description: User retrieved successfully
     *       404:
     *         description: User not found
     *       500:
     *         description: Internal server error
     */
    public gerUserById : ExpressFunction = async (req, res, next) =>{
         try {
            const value = req.params.value;
            const user = await this.userService.getUserById(value);

            if (!user) {
                next( new CustomizedError("Usuario No Encontrado", 404));
            }

            return res.json(user);
        } catch (error) {
            next(error);
        }
    }

    /**
     * @swagger
     * /users/login:
     *   post:
     *     summary: User login
     *     tags: [Users]
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             required:
     *               - password
     *             properties:
     *               email:
     *                 type: string
     *                 format: email
     *               dni:
     *                 type: string
     *                 minLength: 1
     *               password:
     *                 type: string
     *                 minLength: 8
     *     responses:
     *       200:
     *         description: Login successful
     *       401:
     *         description: Invalid credentials
     *       500:
     *         description: Internal server error
     */
    public login: ExpressFunction = async (req, res, next) => {
        try {
            const userData: UserWithOutId = req.body;
            const user = await this.userService.login(userData);

            if (!user) {
                // Si el usuario no existe, devolvemos un status 401 (Unauthorized)
                return next(new CustomizedError("Credenciales inválidas", 401));
            }

            return res.json(user);
        } catch (error) {
            // Pasamos cualquier error al siguiente middleware de error
            next(error);
        }
    };
}
