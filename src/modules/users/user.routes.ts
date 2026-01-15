import UserController from "./user.controller";
import GenericRouter from "@shared/classes/GenericRouter";
import {registerSchema, loginSchema, getUserByRoleSchema} from "./user.schema" ;
import { validate } from "./user.middleware";
import { validateParams } from "@shared/middlewares/zod/validateParams";
import { authenticate } from "@auth/auth.middlewares";
import multer from "multer";
import path from "path";

// Configuración de multer para upload de imágenes
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/profile-images/');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'profile-' + uniqueSuffix + path.extname(file.originalname));
    }
});

const upload = multer({ 
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
    fileFilter: (req, file, cb) => {
        const allowedTypes = /jpeg|jpg|png|gif/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mimetype = allowedTypes.test(file.mimetype);
        
        if (mimetype && extname) {
            return cb(null, true);
        } else {
            cb(new Error('Solo se permiten imágenes (jpeg, jpg, png, gif)'));
        }
    }
});

export default class UserRouter extends GenericRouter {
    constructor(private readonly userController: UserController) {

        super();
        const router = this.init();

        router.get("/", this.userController.getAll);
        router.get("/:value", this.userController.gerUserById)
        router.put("/:id", authenticate, this.userController.updateUser);
        router.get("/role/:role", validateParams(getUserByRoleSchema), this.userController.getByRol)

        router.post("/register", validate(registerSchema), this.userController.register);
        router.post("/login", validate(loginSchema), this.userController.login);
        router.post("/verify-email", this.userController.verifyEmail);
        router.get("/verify-email/:token", this.userController.verifyEmailGet);
        router.post("/resend-verification", this.userController.resendVerification);

        // Notification preferences (require authentication)
        router.get("/notification-preferences", this.userController.getNotificationPreferences);
        router.put("/notification-preferences", this.userController.updateNotificationPreferences);

        // Profile image management (require authentication)
        router.post("/:id/upload-profile-image",
            authenticate,
            upload.single('image'),
            this.userController.uploadProfileImage
        );
        router.delete("/:id/profile-image", authenticate, this.userController.deleteProfileImage);
        router.get("/:id/profile-image", this.userController.getProfileImage);
        
        // FCM Token endpoint
        router.post("/fcm-token", authenticate, this.userController.saveFCMToken);
    }
}