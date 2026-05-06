"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
const dotenv_1 = __importDefault(require("dotenv"));
// Load env vars first (to ensure other config is present)
dotenv_1.default.config({ path: '.env.test' });
const urlFile = path_1.default.join(__dirname, 'test-db-url.txt');
if (fs_1.default.existsSync(urlFile)) {
    const url = fs_1.default.readFileSync(urlFile, 'utf-8').trim();
    process.env.DATABASE_URL = url;
}
