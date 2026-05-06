import { PrismaClient } from '@prisma/client';
import { MercadoPagoConfig, Preference } from 'mercadopago';

const prisma = new PrismaClient();

const API_URL = 'http://127.0.0.1:3000/api/v1';

async function fetchJson(url: string, options: any = {}) {
    const res = await fetch(url, {
        ...options,
        headers: {
            'Content-Type': 'application/json',
            ...options.headers,
        }
    });

    if (res.status === 204) return null;

    const text = await res.text();
    try {
        const data = JSON.parse(text);
        if (!res.ok) {
            throw { status: res.status, data };
        }
        return data;
    } catch (e) {
        if (!res.ok) throw { status: res.status, data: text };
        return text;
    }
}

async function runTest() {
    console.log("🚀 Starting End-to-End User Journey Test (Fetch Mode)...");

    try {
        // 1. Register Student
        console.log("\n1️⃣  Registering Student...");
        const studentEmail = `student_${Date.now()}@test.com`;
        try {
            await fetchJson(`${API_URL}/users/register`, {
                method: 'POST',
                body: JSON.stringify({
                    email: studentEmail,
                    password: "password123",
                    name: "Juan",
                    surname: "Perez",
                    dni: `DNI_${Date.now()}`,
                    role: "STUDENT",
                    birthDate: "1990-01-01T00:00:00Z"
                })
            });
            console.log("✅ Student registered.");
        } catch (e: any) {
            console.log("⚠️  Registration check:", e.data?.message || e);
        }

        // 2. Login Student
        console.log("\n2️⃣  Logging in Student...");
        const loginRes = await fetchJson(`${API_URL}/auth/login`, {
            method: 'POST',
            body: JSON.stringify({
                email: studentEmail,
                password: "password123"
            })
        });
        const STUDENT_TOKEN = loginRes.accessToken;
        const STUDENT_ID = loginRes.user.id;
        console.log("✅ Student Logged In. ID:", STUDENT_ID);

        // 3. Register Instructor
        console.log("\n3️⃣  Registering Instructor User...");
        const instructorEmail = `instructor_${Date.now()}@test.com`;
        let INSTRUCTOR_USER_ID = 0;

        // 3.1 Create User part
        try {
            await fetchJson(`${API_URL}/users/register`, {
                method: 'POST',
                body: JSON.stringify({
                    email: instructorEmail,
                    password: "password123",
                    name: "Profe",
                    surname: "Master",
                    dni: `DNI_I_${Date.now()}`,
                    role: "STUDENT",
                    birthDate: "1980-01-01T00:00:00Z"
                })
            });
            console.log("✅ Instructor User registered.");

            // 3.2 Login to get ID
            const loginTemp = await fetchJson(`${API_URL}/auth/login`, {
                method: 'POST',
                body: JSON.stringify({
                    email: instructorEmail,
                    password: "password123"
                })
            });
            INSTRUCTOR_USER_ID = loginTemp.user.id;

            // 3.3 Register as Instructor Profile
            console.log(`\nPromoting User ${INSTRUCTOR_USER_ID} to Instructor...`);
            await fetchJson(`${API_URL}/instructors/register`, {
                method: 'POST',
                body: JSON.stringify({
                    userId: INSTRUCTOR_USER_ID,
                    licenseNumber: `LIC_${Date.now()}`,
                    experienceYears: 5,
                    hourlyRate: 5000
                })
            });
            console.log("✅ Instructor Profile Created.");

        } catch (e: any) {
            console.log("⚠️  Instructor Reg check:", e.data?.message || e);
        }

        // 4. Login Instructor
        const loginInstRes = await fetchJson(`${API_URL}/auth/login`, {
            method: 'POST',
            body: JSON.stringify({
                email: instructorEmail,
                password: "password123"
            })
        });
        const INSTRUCTOR_TOKEN = loginInstRes.accessToken;
        let INSTRUCTOR_ID = loginInstRes.user.id;
        console.log("✅ Instructor Logged In. User ID:", INSTRUCTOR_ID);

        // Get real Instructor ID
        try {
            const meFull = await fetchJson(`${API_URL}/instructors/me`, {
                headers: { Authorization: `Bearer ${INSTRUCTOR_TOKEN}` }
            });
            if (meFull.id) {
                INSTRUCTOR_ID = meFull.id;
            }
            console.log("✅ Real Instructor Table ID:", INSTRUCTOR_ID);
        } catch (e) {
            console.log("⚠️  Could not fetch Instructor Private Profile, using user ID guess.");
        }

        // 5. Create Slot and Reserve (Correct Flow)
        console.log("\n4️⃣  Creating Slot and Reserving...");

        // Create Slot as Instructor
        const slotDate = new Date(Date.now() + 86400000); // Tomorrow
        slotDate.setHours(10, 0, 0, 0);
        const slotEndTime = new Date(slotDate);
        slotEndTime.setHours(11, 0, 0, 0);

        const slotRes = await fetchJson(`${API_URL}/schedule/slots`, {
            method: 'POST',
            headers: { Authorization: `Bearer ${INSTRUCTOR_TOKEN}` },
            body: JSON.stringify({
                startTime: slotDate.toISOString(),
                endTime: slotEndTime.toISOString()
            })
        });
        const SLOT_ID = slotRes.id;
        console.log("✅ Slot Created. ID:", SLOT_ID);

        // Reserve Slot as Student
        const reserveRes = await fetchJson(`${API_URL}/schedule/reserve/${SLOT_ID}`, {
            method: 'POST',
            headers: { Authorization: `Bearer ${STUDENT_TOKEN}` },
            body: JSON.stringify({})
        });

        let CLASS_ID = reserveRes.drivingClass?.id || reserveRes.id || reserveRes.bookingId || reserveRes.drivingClassId;
        // Fallback if structure is different
        if (!CLASS_ID && reserveRes.drivingClass) CLASS_ID = reserveRes.drivingClass.id;

        console.log("✅ Slot Reserved. Class ID:", CLASS_ID);


        // 6. Generate Payment Preference
        console.log("\n5️⃣  Generating MercadoPago Preference...");
        const prefRes = await fetchJson(`${API_URL}/payments/mercadopago/preference`, {
            method: 'POST',
            headers: { Authorization: `Bearer ${STUDENT_TOKEN}` },
            body: JSON.stringify({
                drivingClassId: CLASS_ID,
                amount: 15000,
                description: "Clase Manejo Test"
                // Removed payerEmail to pass strict schema
            })
        });

        const preferenceId = prefRes.data?.preferenceId || prefRes.preferenceId || prefRes.id;
        const initPoint = prefRes.data?.initPoint || prefRes.initPoint || prefRes.sandbox_init_point || prefRes.init_point;

        console.log("✅ Preference Created!");
        console.log("🆔 Preference ID:", preferenceId);
        console.log("🔗 Init Point:", initPoint);

        if (preferenceId) {
            console.log("\n🎉 TEST SUCCESSFUL! The backend is ready for the Mobile App.");
        } else {
            console.log("\n⚠️  Preference created but key fields missing?");
            console.log("Full Response:", JSON.stringify(prefRes, null, 2));
        }

    } catch (error: any) {
        console.error("❌ TEST FAILED");
        if (error.status) {
            console.error("Status:", error.status);
            console.error("Data:", JSON.stringify(error.data, null, 2));
        }
    }
}

runTest();
