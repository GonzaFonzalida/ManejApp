import { buildApp } from "./app";
import { PORT } from "@config/config";

const app = buildApp();

app.listen(PORT, () => {
    console.log(`Server corriendo en el puerto ${PORT}`);
});
export default app;