"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require('dotenv').config();
const app_1 = require("./app");
const PORT = 3000;
const app = (0, app_1.buildApp)();
app.listen(PORT, () => {
    console.log(`Server corriendo en el puerto ${PORT}`);
});
exports.default = app;
