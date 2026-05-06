"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
const API_URL = 'http://127.0.0.1:3000/api/v1';
async function fetchJson(url, options = {}) {
    const res = await fetch(url, {
        ...options,
        headers: {
            'Content-Type': 'application/json',
            ...options.headers,
        }
    });
    if (res.status === 204)
        return null;
    const text = await res.text();
    try {
        const data = JSON.parse(text);
        if (!res.ok) {
            throw { status: res.status, data };
        }
        return data;
    }
    catch (e) {
        if (!res.ok)
            throw { status: res.status, data: text };
        return text;
    }
}
async function testStudentFlow() {
    console.log("🎓 === PRUEBA COMPLETA DEL FLUJO DE ALUMNO ===\n");
    try {
        // 1. REGISTRO
        console.log("1️⃣  REGISTRO DE ALUMNO");
        const studentEmail = `alumno_test_${Date.now()}@test.com`;
        const studentPassword = "password123";
        await fetchJson(`${API_URL}/users/register`, {
            method: 'POST',
            body: JSON.stringify({
                email: studentEmail,
                password: studentPassword,
                name: "Test",
                surname: "Alumno",
                dni: `DNI_${Date.now()}`,
                role: "STUDENT",
                birthDate: "1995-01-01T00:00:00Z"
            })
        });
        console.log("✅ Alumno registrado exitosamente");
        console.log(`   Email: ${studentEmail}\n`);
        // 2. LOGIN
        console.log("2️⃣  LOGIN");
        const loginRes = await fetchJson(`${API_URL}/auth/login`, {
            method: 'POST',
            body: JSON.stringify({
                email: studentEmail,
                password: studentPassword
            })
        });
        const STUDENT_TOKEN = loginRes.accessToken;
        const STUDENT_ID = loginRes.user.id;
        console.log("✅ Login exitoso");
        console.log(`   User ID: ${STUDENT_ID}`);
        console.log(`   Token: ${STUDENT_TOKEN.substring(0, 20)}...\n`);
        // 3. BUSCAR INSTRUCTORES
        console.log("3️⃣  BUSCAR INSTRUCTORES DISPONIBLES");
        const instructors = await fetchJson(`${API_URL}/instructors?limit=10`, {
            headers: { Authorization: `Bearer ${STUDENT_TOKEN}` }
        });
        console.log(`✅ Encontrados ${instructors.length} instructores`);
        if (instructors.length === 0) {
            throw new Error("No hay instructores disponibles");
        }
        const selectedInstructor = instructors[0];
        console.log(`   Instructor seleccionado: ${selectedInstructor.user?.name} ${selectedInstructor.user?.surname}`);
        console.log(`   ID: ${selectedInstructor.id}`);
        console.log(`   Tarifa: $${selectedInstructor.hourlyRate}/hora\n`);
        // 4. VER HORARIOS DISPONIBLES
        console.log("4️⃣  CONSULTAR HORARIOS DISPONIBLES");
        const slots = await fetchJson(`${API_URL}/schedule/instructor/${selectedInstructor.id}`, {
            headers: { Authorization: `Bearer ${STUDENT_TOKEN}` }
        });
        const availableSlots = slots.filter((s) => s.status === 'AVAILABLE');
        console.log(`✅ Horarios disponibles: ${availableSlots.length}`);
        if (availableSlots.length === 0) {
            throw new Error("El instructor no tiene horarios disponibles");
        }
        const selectedSlot = availableSlots[0];
        console.log(`   Slot seleccionado: ${selectedSlot.id}`);
        console.log(`   Fecha: ${new Date(selectedSlot.startTime).toLocaleString()}`);
        console.log(`   Duración: ${selectedSlot.startTime} - ${selectedSlot.endTime}\n`);
        // 5. RESERVAR SLOT
        console.log("5️⃣  RESERVAR HORARIO");
        const reservation = await fetchJson(`${API_URL}/schedule/reserve/${selectedSlot.id}`, {
            method: 'POST',
            headers: { Authorization: `Bearer ${STUDENT_TOKEN}` },
            body: '{}'
        });
        const classId = reservation.drivingClass?.id || reservation.id || reservation.bookingId;
        console.log("✅ Reserva creada exitosamente");
        console.log(`   Clase ID: ${classId}`);
        console.log(`   Booking ID: ${reservation.bookingId}`);
        console.log(`   Retenido hasta: ${reservation.heldUntil}\n`);
        // 6. CREAR PREFERENCIA DE PAGO
        console.log("6️⃣  GENERAR PREFERENCIA DE MERCADOPAGO");
        // Calculate amount based on duration
        const startTime = new Date(selectedSlot.startTime);
        const endTime = new Date(selectedSlot.endTime);
        const durationMinutes = Math.floor((endTime.getTime() - startTime.getTime()) / (1000 * 60));
        const hourlyRate = selectedInstructor.hourlyRate || 45000;
        const amount = Math.round((hourlyRate / 60) * durationMinutes);
        const preference = await fetchJson(`${API_URL}/payments/mercadopago/preference`, {
            method: 'POST',
            headers: { Authorization: `Bearer ${STUDENT_TOKEN}` },
            body: JSON.stringify({
                drivingClassId: classId,
                amount: amount,
                description: `Clase con ${selectedInstructor.user?.name} ${selectedInstructor.user?.surname}`
            })
        });
        console.log("✅ Preferencia de pago creada");
        console.log(`   Preference ID: ${preference.data?.preferenceId || preference.preferenceId || preference.id}`);
        console.log(`   Monto: $${amount}`);
        console.log(`   🔗 Checkout URL: ${preference.data?.initPoint || preference.initPoint || preference.sandbox_init_point || preference.init_point}\n`);
        // 7. VERIFICAR ESTADO DE LA CLASE
        console.log("7️⃣  VERIFICAR ESTADO DE LA CLASE");
        // @ts-ignore - Prisma include types
        const classDetails = await prisma.drivingClass.findUnique({
            where: { id: classId },
            include: {
                student: { include: { user: true } },
                instructor: { include: { user: true } },
                payments: true
            }
        });
        console.log("✅ Estado de la clase:");
        console.log(`   ID: ${classDetails?.id}`);
        console.log(`   Estado: ${classDetails?.status}`);
        // @ts-ignore
        console.log(`   Alumno: ${classDetails?.student?.user?.name} ${classDetails?.student?.user?.surname}`);
        // @ts-ignore
        console.log(`   Instructor: ${classDetails?.instructor?.user?.name} ${classDetails?.instructor?.user?.surname}`);
        console.log(`   Fecha: ${classDetails?.date}`);
        console.log(`   Duración: ${classDetails?.duration} minutos`);
        console.log(`   Monto: $${classDetails?.amount}`);
        // @ts-ignore
        console.log(`   Pago: ${classDetails?.payments?.[0]?.status || 'Sin pago'}\n`);
        // RESUMEN FINAL
        console.log("═══════════════════════════════════════════════");
        console.log("🎉 ¡PRUEBA COMPLETADA EXITOSAMENTE!");
        console.log("═══════════════════════════════════════════════");
        console.log("\n📋 RESUMEN:");
        console.log(`✓ Alumno registrado: ${studentEmail}`);
        console.log(`✓ Instructor seleccionado: ${selectedInstructor.user?.name} ${selectedInstructor.user?.surname}`);
        console.log(`✓ Clase reservada: ID ${classId}`);
        console.log(`✓ Preferencia de pago: ${preference.data?.preferenceId || preference.preferenceId || preference.id || 'N/A'}`);
        console.log(`✓ Estado: ${classDetails?.status}`);
        console.log("\n🔗 PRÓXIMO PASO:");
        console.log("El alumno debe abrir el siguiente link para completar el pago:");
        console.log(preference.data?.initPoint || preference.initPoint || preference.sandbox_init_point || preference.init_point || 'No disponible - usar panel de MercadoPago');
        console.log("\n💡 NOTA: Este es el link de SANDBOX (dinero ficticio)");
        console.log("═══════════════════════════════════════════════\n");
    }
    catch (error) {
        console.error("\n❌ ERROR EN LA PRUEBA");
        console.error("═══════════════════════════════════════════════");
        if (error.status) {
            console.error(`Status HTTP: ${error.status}`);
            console.error(`Detalle:`, JSON.stringify(error.data, null, 2));
        }
        else {
            console.error(error);
        }
        console.error("═══════════════════════════════════════════════\n");
        process.exit(1);
    }
    finally {
        await prisma.$disconnect();
    }
}
testStudentFlow();
