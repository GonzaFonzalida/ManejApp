import { buildApp } from "./app";
import { PORT } from "@config/config";
import { ensureDemoAdmin } from "./bootstrap/ensureDemoAdmin";
import { ensureDemoCatalog } from "./bootstrap/ensureDemoCatalog";

void (async () => {
  try {
    await ensureDemoAdmin();
    await ensureDemoCatalog();
  } catch (e) {
    console.error("[bootstrap demo] Error (el servidor igual arranca):", e);
  }

  const app = buildApp();
  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server corriendo en el puerto ${PORT}`);
  });
})();