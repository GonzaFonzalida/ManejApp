"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
class GenericRouter {
    router;
    constructor() {
        this.router = (0, express_1.Router)();
    }
    init() {
        return this.router;
    }
}
exports.default = GenericRouter;
