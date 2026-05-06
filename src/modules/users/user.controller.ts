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

        console.log('[DEBUG] Received registration request body:', JSON.stringify(req.body, null, 2));
        const user: UserWithDates = req.body;
        const result = await this.userService.register(user);
        if (result instanceof Error || (result as any).name === "PrismaClientKnownRequestError") {
            return next(new CustomizedError("El usuario que intenta registrar ya existe", 409));
        }

        const { user: newUser, accessToken } = result as { user: any; accessToken?: string };
        const response: Record<string, any> = { token: newUser };
        if (accessToken) {
            response.accessToken = accessToken;
        } else {
            response.requiresEmailVerification = true;
            response.message =
                "Registro exitoso. Revisá tu correo (y spam) para verificar la cuenta antes de iniciar sesión.";
        }

        res.status(201).json(response);

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
        try {
            const users = await this.userService.getAllUsers();
            return res.json(users);
        } catch (e) {
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
        try {
            const role = req.params.role

            const users = await this.userService.findByRole(role.toUpperCase());
            return res.json(users);
        } catch (e) {

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
    public getVerificationStatus: ExpressFunction = async (req, res, next) => {
        try {
            const { userId } = req.params;
            const user = await this.userService.getUserById(userId);
            if (!user) {
                return next(new CustomizedError("Usuario no encontrado", 404));
            }
            const verified = !!(user as any).emailVerifiedAt;
            return res.json({ verified });
        } catch (error) {
            next(error);
        }
    };

    public gerUserById: ExpressFunction = async (req, res, next) => {
        try {
            const value = req.params.value;
            const user = await this.userService.getUserById(value);

            if (!user) {
                next(new CustomizedError("Usuario No Encontrado", 404));
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
    public patchStudentProfile: ExpressFunction = async (req, res, next) => {
        try {
            const currentUserId = (req as any).user.id as number;
            const { experienceLevel } = req.body as { experienceLevel: number };

            const updated = await this.userService.updateStudentExperienceLevel(currentUserId, experienceLevel);
            if (!updated) {
                return next(new CustomizedError('Perfil de estudiante no encontrado', 404));
            }

            res.json({
                success: true,
                message: 'Perfil actualizado',
                data: { experienceLevel: updated.experienceLevel },
            });
        } catch (error) {
            next(error);
        }
    };

    public deleteMyAccount: ExpressFunction = async (req, res, next) => {
        try {
            const currentUserId = (req as any).user.id as number;
            const result = await this.userService.deleteMyAccount(currentUserId, req.body as {
                confirmPhrase: string;
                password?: string;
            });
            if (result instanceof CustomizedError) {
                return next(result);
            }
            res.status(200).json({ ok: true });
        } catch (error) {
            next(error);
        }
    };

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

    public forgotPassword: ExpressFunction = async (req, res, next) => {
        try {
            const { email } = req.body;
            const result = await this.userService.forgotPassword(email);
            res.json(result);
        } catch (error) {
            next(error);
        }
    };

    public resetPassword: ExpressFunction = async (req, res, next) => {
        try {
            const { token, newPassword } = req.body;
            const result = await this.userService.resetPassword(token, newPassword);
            if (!result.ok) {
                return res.status(400).json(result);
            }
            res.json(result);
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
            const preferences = await this.userService.getNotificationPreferences(userId);

            if (!preferences) {
                return next(new CustomizedError("Usuario no encontrado", 404));
            }

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
            const { emailNotifications, pushNotifications } = req.body as {
                emailNotifications?: boolean;
                pushNotifications?: boolean;
            };

            const patch: { emailNotifications?: boolean; pushNotifications?: boolean } = {};
            if (typeof emailNotifications === "boolean") patch.emailNotifications = emailNotifications;
            if (typeof pushNotifications === "boolean") patch.pushNotifications = pushNotifications;

            if (Object.keys(patch).length === 0) {
                return next(new CustomizedError("Enviá al menos emailNotifications o pushNotifications (boolean)", 400));
            }

            await this.userService.updateNotificationPreferences(userId, patch);
            const preferences = await this.userService.getNotificationPreferences(userId);

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
            // We save only the filename, not the full path, because FileService constructs the path relative to uploadDir
            const user = await this.userService.updateProfileImage(userId, file.filename);

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
     * /users/{id}/upload-profile-image-base64:
     *   post:
     *     summary: Upload profile image via Base64 JSON
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
     *               image:
     *                 type: string
     *                 description: Base64 encoded image string
     *               mimeType:
     *                 type: string
     *                 description: Mime type (image/jpeg, image/png)
     *     responses:
     *       200:
     *         description: Profile image uploaded successfully
     */
    public uploadProfileImageBase64: ExpressFunction = async (req: any, res: any, next: any) => {
        try {
            const userId = parseInt(req.params.id);
            const currentUserId = req.user.id;
            const { image, mimeType } = req.body;

            if (userId !== currentUserId) {
                return next(new CustomizedError('No puedes actualizar la imagen de otro usuario', 403));
            }

            if (!image) {
                return next(new CustomizedError('No se encontró imagen en base64', 400));
            }

            // Convertir base64 a buffer
            const matches = image.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
            let buffer: Buffer;

            if (matches && matches.length === 3) {
                buffer = Buffer.from(matches[2], 'base64');
            } else {
                buffer = Buffer.from(image, 'base64');
            }

            // Definir extension
            let ext = '.jpg';
            if (mimeType) {
                if (mimeType.includes('png')) ext = '.png';
                else if (mimeType.includes('webp')) ext = '.webp';
                else if (mimeType.includes('gif')) ext = '.gif';
            }

            const uploadDir = path.join(process.cwd(), 'uploads', 'profiles');
            if (!require('fs').existsSync(uploadDir)) {
                require('fs').mkdirSync(uploadDir, { recursive: true });
            }

            const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
            const filename = `profile-${userId}-${uniqueSuffix}${ext}`;
            const filepath = path.join(uploadDir, filename);

            require('fs').writeFileSync(filepath, buffer);

            // Save ONLY the filename to the database, not the absolute path
            // FileService will reconstruct the full path using its internal uploadDir
            const user = await this.userService.updateProfileImage(userId, filename);

            res.json({
                success: true,
                message: 'Imagen de perfil actualizada exitosamente (Base64)',
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

    public deleteFCMToken: ExpressFunction = async (req, res, next) => {
        try {
            const userId = (req as any).user.id;
            await this.userService.deleteFCMToken(userId);
            res.json({ success: true, message: 'Token de notificaciones eliminado' });
        } catch (error) {
            next(error);
        }
    };
}
