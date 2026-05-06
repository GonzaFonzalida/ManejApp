import UserController from "./user.controller";
import GenericRouter from "@shared/classes/GenericRouter";
import { registerSchema, loginSchema, getUserByRoleSchema, forgotPasswordSchema, resetPasswordSchema, studentProfilePatchSchema, deleteAccountSchema } from "./user.schema";
import { validate } from "./user.middleware";
import { validateParams } from "@shared/middlewares/zod/validateParams";
import { authenticate, requireRole } from "@auth/auth.middlewares";
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

        router.get("/", authenticate, this.userController.getAll);
        router.get("/verification-status/:userId", authenticate, this.userController.getVerificationStatus);
        router.patch(
            "/student-profile",
            authenticate,
            requireRole("STUDENT"),
            validate(studentProfilePatchSchema),
            this.userController.patchStudentProfile,
        );
        router.post(
            "/me/delete-account",
            authenticate,
            validate(deleteAccountSchema),
            this.userController.deleteMyAccount,
        );
        router.get("/:value", authenticate, this.userController.gerUserById)
        router.put("/:id", authenticate, this.userController.updateUser);
        router.get("/role/:role", authenticate, validateParams(getUserByRoleSchema), this.userController.getByRol)

        router.post("/register", validate(registerSchema), this.userController.register);
        router.post("/login", validate(loginSchema), this.userController.login);
        router.post("/verify-email", this.userController.verifyEmail);
        router.get("/verify-email/:token", this.userController.verifyEmailGet);
        router.post("/resend-verification", this.userController.resendVerification);
        router.post("/forgot-password", validate(forgotPasswordSchema), this.userController.forgotPassword);
        router.post("/reset-password", validate(resetPasswordSchema), this.userController.resetPassword);

        // Notification preferences
        router.get("/notification-preferences", authenticate, this.userController.getNotificationPreferences);
        router.put("/notification-preferences", authenticate, this.userController.updateNotificationPreferences);

        // Profile image management (require authentication)
        router.post("/:id/upload-profile-image-base64", authenticate, this.userController.uploadProfileImageBase64);

        router.post("/:id/upload-profile-image",
            authenticate,
            upload.single('image'),
            this.userController.uploadProfileImage
        );
        router.delete("/:id/profile-image", authenticate, this.userController.deleteProfileImage);
        router.get("/:id/profile-image", this.userController.getProfileImage);

        // FCM Token (registro y cierre de sesión)
        router.post("/fcm-token", authenticate, this.userController.saveFCMToken);
        router.delete("/fcm-token", authenticate, this.userController.deleteFCMToken);
    }
}