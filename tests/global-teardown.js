"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fs_1 = __importDefault(require("fs"));
const path_1 = __importDefault(require("path"));
exports.default = async () => {
    console.log('Tearing down Test Environment...');
    const dbPath = path_1.default.join(__dirname, '../prisma/test.db');
    // Cleanup database file
    if (fs_1.default.existsSync(dbPath)) {
        fs_1.default.unlinkSync(dbPath);
    }
    // Cleanup URL file
    const urlFile = path_1.default.join(__dirname, 'test-db-url.txt');
    if (fs_1.default.existsSync(urlFile)) {
        fs_1.default.unlinkSync(urlFile);
    }
};
