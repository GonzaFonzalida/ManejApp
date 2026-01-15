// C:\Users\thiag\Desktop\Back\ManejApp\src\users\user.controller.ts

import UserService from "./user.services";
import { UserWithOutPassword, User, UserWithOutId, UserWithDates } from "./user.types";
import { ExpressFunction } from "@sharedTypes/ExpressFunction";
import CustomizedError from "@classes/CustomizedError";
import { uploadSingleImage, validateUploadedFile } from "@shared/middlewares/fileUpload";
import FileService from "@shared/services/FileService";
import path from "path";

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
     * /users/{id}:
     *   put:
     *     summary: Update user information
     *     tags: [Users]
     *     security:
     *       - bearerAuth: []
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema:
     *           type: integer
     *         description: User ID
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               name:
     *                 type: string
     *               surname:
     *                 type: string
     *               email:
     *                 type: string
     *                 format: email
     *               dni:
     *                 type: string
     *               birthDate:
     *                 type: string
     *     responses:
     *       200:
     *         description: User updated successfully
     *       401:
     *         description: Unauthorized
     *       403:
     *         description: Cannot update other user's information
     *       404:
     *         description: User not found
     *       500:
     *         description: Internal server error
     */
    public updateUser: ExpressFunction = async (req, res, next) => {
        try {
            const userId = parseInt(req.params.id);
            const currentUserId = (req as any).user.id;
            const updateData = req.body;

            // Verificar que el usuario solo pueda actualizar su propia información
            if (userId !== currentUserId) {
                return next(new CustomizedError('No puedes actualizar la información de otro usuario', 403));
            }

            const updatedUser = await this.userService.updateUser(userId, updateData);

            if (!updatedUser) {
                return next(new CustomizedError('Usuario no encontrado', 404));
            }

            res.json({
                success: true,
                message: 'Usuario actualizado exitosamente',
                data: updatedUser
            });
        } catch (error) {
            next(error);
        }
    };

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

    /**
     * @swagger
     * /users/verify-email:
     *   post:
     *     summary: Verify user email
     *     tags: [Users]
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             required:
     *               - token
     *             properties:
     *               token:
     *                 type: string
     *     responses:
     *       200:
     *         description: Email verified successfully
     *       400:
     *         description: Invalid token
     *       500:
     *         description: Internal server error
     */
    public verifyEmail: ExpressFunction = async (req, res, next) => {
        try {
            const { token } = req.body;
            const user = await this.userService.verifyEmail(token);

            if (!user) {
                return next(new CustomizedError("Token inválido", 400));
            }

            res.json({ message: "Email verificado exitosamente", user });
        } catch (error) {
            next(error);
        }
    };

    /**
     * @swagger
     * /users/verify-email/{token}:
     *   get:
     *     summary: Verify user email via GET (for mobile deep links)
     *     tags: [Users]
     *     parameters:
     *       - in: path
     *         name: token
     *         required: true
     *         schema:
     *           type: string
     *         description: Verification token
     *     responses:
     *       200:
     *         description: Email verified successfully
     *       400:
     *         description: Invalid token
     *       500:
     *         description: Internal server error
     */
    public verifyEmailGet: ExpressFunction = async (req, res, next) => {
        try {
            const { token } = req.params;
            const user = await this.userService.verifyEmail(token);

            if (!user) {
                return next(new CustomizedError("Token inválido", 400));
            }

            res.json({ message: "Email verificado exitosamente", user });
        } catch (error) {
            next(error);
        }
    };

    /**
     * @swagger
     * /users/resend-verification:
     *   post:
     *     summary: Resend verification email
     *     tags: [Users]
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             required:
     *               - email
     *             properties:
     *               email:
     *                 type: string
     *                 format: email
     *     responses:
     *       200:
     *         description: Verification email sent
     *       400:
     *         description: Email already verified or not found
     *       500:
     *         description: Internal server error
     */
    public resendVerification: ExpressFunction = async (req, res, next) => {
        try {
            const { email } = req.body;
            const user = await this.userService.resendVerificationEmail(email);

            if (!user) {
                return next(new CustomizedError("Email ya verificado o no encontrado", 400));
            }

            res.json({ message: "Email de verificación reenviado" });
        } catch (error) {
            next(error);
        }
    };

    /**
     * @swagger
     * /users/notification-preferences:
     *   get:
     *     summary: Get user notification preferences
     *     tags: [Users]
     *     security:
     *       - bearerAuth: []
     *     responses:
     *       200:
     *         description: Notification preferences retrieved
     *       401:
     *         description: Unauthorized
     *       500:
     *         description: Internal server error
     */
    public getNotificationPreferences: ExpressFunction = async (req, res, next) => {
        try {
            const userId = (req as any).user.id;
            const user = await this.userService.getUserById(userId.toString());

            if (!user) {
                return next(new CustomizedError("Usuario no encontrado", 404));
            }

            const preferences = {
                emailNotifications: (user as any).emailNotifications ?? true,
                pushNotifications: (user as any).pushNotifications ?? true,
            };

            res.json(preferences);
        } catch (error) {
            next(error);
        }
    };

    /**
     * @swagger
     * /users/notification-preferences:
     *   put:
     *     summary: Update user notification preferences
     *     tags: [Users]
     *     security:
     *       - bearerAuth: []
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               emailNotifications:
     *                 type: boolean
     *               pushNotifications:
     *                 type: boolean
     *     responses:
     *       200:
     *         description: Notification preferences updated
     *       401:
     *         description: Unauthorized
     *       500:
     *         description: Internal server error
     */
    public updateNotificationPreferences: ExpressFunction = async (req, res, next) => {
        try {
            const userId = (req as any).user.id;
            const { emailNotifications, pushNotifications } = req.body;

            // Aquí iría la lógica para actualizar las preferencias en la BD
            // Por ahora, solo devolvemos éxito
            const preferences = {
                emailNotifications: emailNotifications ?? true,
                pushNotifications: pushNotifications ?? true,
            };

            res.json({ message: "Preferencias actualizadas", preferences });
        } catch (error) {
            next(error);
        }
    };

    /**
     * @swagger
     * /users/{id}/upload-profile-image:
     *   post:
     *     summary: Upload profile image for specific user
     *     tags: [Users]
     *     security:
     *       - bearerAuth: []
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema:
     *           type: integer
     *         description: User ID
     *     requestBody:
     *       required: true
     *       content:
     *         multipart/form-data:
     *           schema:
     *             type: object
     *             properties:
     *               image:
     *                 type: string
     *                 format: binary
     *                 description: Profile image file (max 5MB, jpeg/png/gif)
     *     responses:
     *       200:
     *         description: Profile image uploaded successfully
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 success:
     *                   type: boolean
     *                   example: true
     *                 message:
     *                   type: string
     *                   example: "Imagen de perfil actualizada exitosamente"
     *                 data:
     *                   type: object
     *                   properties:
     *                     imageUrl:
     *                       type: string
     *                       example: "/api/v1/users/123/profile-image"
     *       400:
     *         description: Invalid file or upload error
     *       401:
     *         description: Unauthorized
     *       403:
     *         description: Cannot update other user's profile
     *       500:
     *         description: Internal server error
     */
    public uploadProfileImage: ExpressFunction = async (req: any, res: any, next: any) => {
        try {
            const userId = parseInt(req.params.id);
            const currentUserId = req.user.id;
            const file = req.file;

            // Verificar que el usuario solo pueda subir su propia imagen
            if (userId !== currentUserId) {
                return next(new CustomizedError('No puedes actualizar la imagen de otro usuario', 403));
            }

            if (!file) {
                return next(new CustomizedError('No se encontró ningún archivo', 400));
            }

            // Update user profile image
            const user = await this.userService.updateProfileImage(userId, file.path);

            if (!user) {
                return next(new CustomizedError('Usuario no encontrado', 404));
            }

            res.json({
                success: true,
                message: 'Imagen de perfil actualizada exitosamente',
                data: {
                    imageUrl: `/api/v1/users/${userId}/profile-image`
                }
            });
        } catch (error) {
            next(error);
        }
    };

    /**
     * @swagger
     * /users/{id}/profile-image:
     *   delete:
     *     summary: Delete profile image for specific user
     *     tags: [Users]
     *     security:
     *       - bearerAuth: []
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema:
     *           type: integer
     *         description: User ID
     *     responses:
     *       200:
     *         description: Profile image deleted successfully
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 success:
     *                   type: boolean
     *                   example: true
     *                 message:
     *                   type: string
     *                   example: "Imagen de perfil eliminada exitosamente"
     *       401:
     *         description: Unauthorized
     *       403:
     *         description: Cannot delete other user's profile image
     *       500:
     *         description: Internal server error
     */
    public deleteProfileImage: ExpressFunction = async (req, res, next) => {
        try {
            const userId = parseInt(req.params.id);
            const currentUserId = (req as any).user.id;

            // Verificar que el usuario solo pueda eliminar su propia imagen
            if (userId !== currentUserId) {
                return next(new CustomizedError('No puedes eliminar la imagen de otro usuario', 403));
            }

            const user = await this.userService.deleteProfileImage(userId);

            res.json({
                success: true,
                message: 'Imagen de perfil eliminada exitosamente'
            });
        } catch (error) {
            next(error);
        }
    };

    /**
     * @swagger
     * /users/{id}/profile-image:
     *   get:
     *     summary: Get profile image for specific user
     *     tags: [Users]
     *     parameters:
     *       - in: path
     *         name: id
     *         required: true
     *         schema:
     *           type: integer
     *         description: User ID
     *     responses:
     *       200:
     *         description: Profile image file
     *         content:
     *           image/*:
     *             schema:
     *               type: string
     *               format: binary
     *       404:
     *         description: Image not found
     *       500:
     *         description: Internal server error
     */
    public getProfileImage: ExpressFunction = async (req, res, next) => {
        try {
            const userId = parseInt(req.params.id);

            const imagePath = await this.userService.getProfileImagePath(userId);

            if (!imagePath) {
                return next(new CustomizedError('Imagen no encontrada', 404));
            }

            // Check if file exists
            if (!FileService.fileExists(imagePath)) {
                return next(new CustomizedError('Imagen no encontrada', 404));
            }

            const filePath = FileService.getFullFilePath(imagePath);
            const stats = await FileService.getFileStats(imagePath);
            
            if (!stats) {
                return next(new CustomizedError('Error al acceder al archivo', 500));
            }

            // Set appropriate headers
            const ext = path.extname(imagePath).toLowerCase();
            const contentType = {
                '.jpg': 'image/jpeg',
                '.jpeg': 'image/jpeg',
                '.png': 'image/png',
                '.gif': 'image/gif'
            }[ext] || 'application/octet-stream';

            res.setHeader('Content-Type', contentType);
            res.setHeader('Content-Length', stats.size);
            res.setHeader('Cache-Control', 'public, max-age=31536000');

            // Stream the file
            const fileStream = require('fs').createReadStream(filePath);
            fileStream.pipe(res);

        } catch (error) {
            next(error);
        }
    };

    /**
     * @swagger
     * /users/fcm-token:
     *   post:
     *     summary: Save FCM token for push notifications
     *     tags: [Users]
     *     security:
     *       - bearerAuth: []
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             required:
     *               - fcmToken
     *             properties:
     *               fcmToken:
     *                 type: string
     *                 description: Firebase Cloud Messaging token
     *     responses:
     *       200:
     *         description: FCM token saved successfully
     *         content:
     *           application/json:
     *             schema:
     *               type: object
     *               properties:
     *                 success:
     *                   type: boolean
     *                   example: true
     *                 message:
     *                   type: string
     *                   example: "Token FCM guardado exitosamente"
     *       400:
     *         description: Invalid token
     *       401:
     *         description: Unauthorized
     *       500:
     *         description: Internal server error
     */
    public saveFCMToken: ExpressFunction = async (req, res, next) => {
        try {
            const userId = (req as any).user.id;
            const { fcmToken } = req.body;

            if (!fcmToken) {
                return next(new CustomizedError('Token FCM es requerido', 400));
            }

            // Guardar o actualizar el token FCM
            await this.userService.saveFCMToken(userId, fcmToken);

            res.json({
                success: true,
                message: 'Token FCM guardado exitosamente'
            });
        } catch (error) {
            next(error);
        }
    };
}
