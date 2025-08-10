import { buildApp } from "./app";

const PORT = 3000;

const app = buildApp();

app.listen(PORT, () => {
    console.log(`Server corriendo en el puerto ${PORT}`);
});
export default app;