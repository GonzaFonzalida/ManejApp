"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Permission = void 0;
class Permission {
    id;
    name;
    description;
    isMandatory;
    constructor(id, name, description, isMandatory) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.isMandatory = isMandatory;
        if (!name || !name.trim())
            throw new Error("Permission name is required");
        if (!description || !description.trim())
            throw new Error("Permission description is required");
        if (typeof isMandatory !== "boolean")
            throw new Error("isMandatory must be boolean");
    }
}
exports.Permission = Permission;
