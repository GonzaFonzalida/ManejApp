import { Router } from 'express';
import UserService from './services';
import PrismaUserRepository from './repositories/PrismaUserRepository';

const repository = new PrismaUserRepository
const userService = new UserService(repository) ; 

const router = Router();

// Ruta para login de usuario
router.post('/login', async (req, res) => {
    try {
        const result = await userService.login(req.body);
        res.json(result);
    } catch (error) {
        res.status(400).json({ error: (error as Error).message });
    }
});

// Ruta para registro de usuario
router.post('/register', async (req, res) => {
    try {
        const result = await userService.register(req.body);
        res.json(result);
    } catch (error) {
        res.status(400).json({ error: (error as Error).message });
    }
});

export default router;