"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const app_1 = require("./app");
const config_1 = require("./config/config");
const app = (0, app_1.buildApp)();
app.listen(config_1.PORT, "0.0.0.0", () => {
    console.log(`Server corriendo en el puerto ${config_1.PORT}`);
});
exports.default = app;
