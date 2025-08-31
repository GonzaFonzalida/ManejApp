"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PermissionService = void 0;
class PermissionService {
    repository;
    constructor(repository) {
        this.repository = repository;
    }
    async createPermission(data) {
        return this.repository.create(data);
    }
    async getPermission(id) {
        return this.repository.findById(id);
    }
    async getAllPermissions() {
        return this.repository.findAll();
    }
    async updatePermission(id, data) {
        return this.repository.update(id, data);
    }
    async deletePermission(id) {
        return this.repository.delete(id);
    }
}
exports.PermissionService = PermissionService;
