"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const app_1 = require("./app");
const config_1 = require("./config/config");
const ensureDemoAdmin_1 = require("./bootstrap/ensureDemoAdmin");
const ensureDemoCatalog_1 = require("./bootstrap/ensureDemoCatalog");
void (async () => {
    try {
        await (0, ensureDemoAdmin_1.ensureDemoAdmin)();
        await (0, ensureDemoCatalog_1.ensureDemoCatalog)();
    }
    catch (e) {
        console.error("[bootstrap demo] Error (el servidor igual arranca):", e);
    }
    const app = (0, app_1.buildApp)();
    app.listen(config_1.PORT, "0.0.0.0", () => {
        console.log(`Server corriendo en el puerto ${config_1.PORT}`);
    });
})();
