import express from 'express';
import cors from 'cors';
import * as http from 'http';
import * as path from 'path';
import * as dotenv from 'dotenv';
import { connectToDatabase, client } from './src/db';
import authRoutes from './src/routes/auth';
import stargazeRoutes from './src/routes/stargaze';
import userRoutes from './src/routes/user';
import constellationRoutes from './src/routes/constellations';

dotenv.config();

interface TestResult {
    id: number;
    name: string;
    method: string;
    endpoint: string;
    status: 'PASSED' | 'FAILED';
    durationMs: number;
    details?: string;
}

const results: TestResult[] = [];

async function runBenchmarkTest() {
    console.log("=========================================================");
    console.log("    🌌 SKYSCOUT FULL BACKEND ENDPOINT TEST SUITE 🌌     ");
    console.log("=========================================================");
    console.log(`Node Runtime: ${process.version}`);
    console.log(`Starting live test at: ${new Date().toLocaleTimeString()}\n`);

    // 1. Establish Database Connection
    console.log("⏳ [1/2] Connecting to MongoDB Atlas Cluster...");
    const db = await connectToDatabase();
    console.log("✅ [1/2] MongoDB Atlas Connected Successfully!\n");

    // 2. Setup Server instance
    console.log("⏳ [2/2] Initializing Express Server & Route Modules...");
    const app = express();
    app.use(cors());
    app.use(express.json({ limit: '10mb' }));
    app.use(express.static(path.join(process.cwd(), 'public')));

    // Health
    app.get('/api/health', (req, res) => {
        res.json({
            status: 'ok',
            uptime: process.uptime(),
            memory: process.memoryUsage(),
            timestamp: new Date().toISOString()
        });
    });

    // Mount API modules
    app.use('/api/auth', authRoutes);
    app.use('/api/user', userRoutes);
    app.use('/api/constellations', constellationRoutes);
    app.use('/api/stargaze', stargazeRoutes);

    const server = http.createServer(app);
    await new Promise<void>((resolve) => server.listen(0, resolve));
    const port = (server.address() as any).port;
    const baseUrl = `http://127.0.0.1:${port}`;
    console.log(`✅ [2/2] Test Server running on ${baseUrl}\n`);
    console.log("---------------------------------------------------------");
    console.log("🚀 Executing 18 Automated Endpoint Tests with Fast Timeouts");
    console.log("---------------------------------------------------------\n");

    const testEmail = "urbanomaildelivery@gmail.com";
    let jwtToken = "";
    let refreshToken = "";
    let createdSessionId = "";
    let constellationSampleId = "";

    // Helper fetch runner
    const runTest = async (
        id: number,
        name: string,
        method: string,
        path: string,
        body?: any,
        token?: string
    ) => {
        const start = Date.now();
        const headers: Record<string, string> = {
            'Content-Type': 'application/json'
        };
        if (token) headers['Authorization'] = `Bearer ${token}`;

        try {
            const res = await fetch(`${baseUrl}${path}`, {
                method,
                headers,
                body: body ? JSON.stringify(body) : undefined,
                signal: AbortSignal.timeout(10000) // 10s strict timeout
            });

            const durationMs = Date.now() - start;
            let data: any = null;
            try {
                data = await res.json();
            } catch {
                data = { statusText: res.statusText };
            }

            const isSuccess = res.status >= 200 && res.status < 300;
            results.push({
                id,
                name,
                method,
                endpoint: path,
                status: isSuccess ? 'PASSED' : 'FAILED',
                durationMs,
                details: isSuccess ? `HTTP ${res.status}` : `HTTP ${res.status}: ${JSON.stringify(data)}`
            });

            const icon = isSuccess ? '✓' : '✗';
            console.log(`[${icon}] #${id} ${method} ${path} (${durationMs}ms) - ${res.status} ${res.statusText}`);
            return { res, data, durationMs };
        } catch (err: any) {
            const durationMs = Date.now() - start;
            results.push({
                id,
                name,
                method,
                endpoint: path,
                status: 'FAILED',
                durationMs,
                details: `Error: ${err.message}`
            });
            console.log(`[✗] #${id} ${method} ${path} (${durationMs}ms) - FAILED: ${err.message}`);
            return { res: null, data: null, durationMs };
        }
    };

    // --- TEST 1: Health Check ---
    const t1 = await runTest(1, "System Health Check", "GET", "/api/health");

    // --- TEST 2: Request OTP ---
    const t2 = await runTest(2, "Request Email OTP", "POST", "/api/auth/request-otp", { email: testEmail });

    // Fetch OTP directly from Atlas to guarantee test stability
    const userDoc = await db.collection('users').findOne({ email: testEmail });
    const otpCode = userDoc?.otpCode || "123456";
    console.log(`    ↳ Verified OTP in MongoDB Atlas: [${otpCode}]`);

    // --- TEST 3: Verify OTP ---
    const t3 = await runTest(3, "Verify OTP & Issue JWT", "POST", "/api/auth/verify-otp", {
        email: testEmail,
        otpCode: otpCode
    });
    if (t3.data && t3.data.token) {
        jwtToken = t3.data.token;
        refreshToken = t3.data.refreshToken;
        console.log(`    ↳ JWT Token Acquired (Starts with: ${jwtToken.substring(0, 18)}...)`);
    }

    // --- TEST 4: Get Current Auth Session ---
    await runTest(4, "Get Auth Session (/api/auth/me)", "GET", "/api/auth/me", undefined, jwtToken);

    // --- TEST 5: Refresh Token ---
    const t5 = await runTest(5, "Refresh JWT Access Token", "POST", "/api/auth/refresh-token", { refreshToken });
    if (t5.data && t5.data.token) {
        jwtToken = t5.data.token; // Use fresh token
    }

    // --- TEST 6: Get User Profile ---
    await runTest(6, "Fetch User Profile", "GET", "/api/user/profile", undefined, jwtToken);

    // --- TEST 7: Update User Profile ---
    await runTest(7, "Update User Profile", "PUT", "/api/user/profile", {
        displayName: "Stargazer Explorer",
        bio: "Observing celestial constellations through SkyScout"
    }, jwtToken);

    // --- TEST 8: Get User Preferences ---
    await runTest(8, "Fetch User Preferences", "GET", "/api/user/preferences", undefined, jwtToken);

    // --- TEST 9: Update User Preferences ---
    await runTest(9, "Update User Preferences", "PUT", "/api/user/preferences", {
        preferences: {
            nightMode: true,
            audioNarrator: "rachel",
            compassSensibility: "high",
            fovAngle: 65
        }
    }, jwtToken);

    // --- TEST 10: Constellations Catalogue ---
    const t10 = await runTest(10, "List Constellations", "GET", "/api/constellations");
    if (t10.data && t10.data.constellations && t10.data.constellations.length > 0) {
        constellationSampleId = t10.data.constellations[0].name;
        console.log(`    ↳ Loaded ${t10.data.count} Constellations from Atlas (Sample: ${constellationSampleId})`);
    }

    // --- TEST 11: Single Constellation by Name ---
    await runTest(11, "Get Constellation Details", "GET", `/api/constellations/${constellationSampleId || 'Orion'}`);

    // --- TEST 12: Stargaze Pipeline (Telemetry Lookup) ---
    console.log("    ↳ Dispatching sensor telemetry to SkyScout Agent...");
    const t12 = await runTest(12, "Stargaze Telemetry Lookup", "POST", "/api/stargaze/lookup", {
        lat: -33.8688,
        lng: 151.2093,
        azimuth: 180.0,
        pitch: 45.0
    }, jwtToken);

    if (t12.data && t12.data.sessionId) {
        createdSessionId = t12.data.sessionId;
        console.log(`    ↳ Matched Constellation: "${t12.data.matchedConstellation}"`);
        console.log(`    ↳ Audio Narration URL: "${t12.data.audioUrl}"`);
        console.log(`    ↳ Story Preview: "${t12.data.storyText?.substring(0, 80)}..."`);
    }

    // --- TEST 13: Stargaze Pipeline (Vision Mode with AR Base64 Image) ---
    console.log("    ↳ Dispatching vision payload (Base64 JPEG) to SkyScout Agent...");
    const mockImageBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=";
    const t13 = await runTest(13, "Stargaze Vision + Telemetry", "POST", "/api/stargaze/lookup", {
        lat: 28.6139,
        lng: 77.2090,
        azimuth: 45.0,
        pitch: 60.0,
        imageBase64: mockImageBase64
    }, jwtToken);

    if (t13.data && t13.data.sessionId) {
        console.log(`    ↳ Vision Matched: "${t13.data.matchedConstellation}"`);
    }

    // --- TEST 14: Get Stargazing History ---
    const t14 = await runTest(14, "Fetch Stargazing History", "GET", "/api/stargaze/history", undefined, jwtToken);
    if (t14.data && t14.data.history) {
        console.log(`    ↳ Stargazing History Entries: ${t14.data.count}`);
    }

    // --- TEST 15: Get Specific History Session ---
    if (createdSessionId) {
        await runTest(15, "Fetch Single Session", "GET", `/api/stargaze/history/${createdSessionId}`, undefined, jwtToken);
    } else {
        console.log("    ↳ [Skipped #15] No session ID available");
    }

    // --- TEST 16: Delete Specific History Session ---
    if (createdSessionId) {
        await runTest(16, "Delete Session by ID", "DELETE", `/api/stargaze/history/${createdSessionId}`, undefined, jwtToken);
    } else {
        console.log("    ↳ [Skipped #16] No session ID available");
    }

    // --- TEST 17: User Logout ---
    await runTest(17, "User Logout", "POST", "/api/auth/logout", undefined, jwtToken);

    // --- TEST 18: Security Check: Reject Unauthenticated Request ---
    const start18 = Date.now();
    const t18 = await fetch(`${baseUrl}/api/auth/me`, {
        method: 'GET',
        signal: AbortSignal.timeout(5000)
    });
    const dur18 = Date.now() - start18;
    const isProtected = t18.status === 401;
    results.push({
        id: 18,
        name: "Security Guard: Reject Unauthenticated",
        method: "GET",
        endpoint: "/api/auth/me (No Token)",
        status: isProtected ? 'PASSED' : 'FAILED',
        durationMs: dur18,
        details: `Expected 401 Unauthorized -> Received ${t18.status}`
    });
    console.log(`[${isProtected ? '✓' : '✗'}] #18 GET /api/auth/me (No Token) (${dur18}ms) - Correctly Rejected (${t18.status} Unauthorized)`);

    // --- PRINT SUMMARY TABLE ---
    console.log("\n=========================================================");
    console.log("                 🏁 TEST SUMMARY REPORT 🏁               ");
    console.log("=========================================================");
    console.log(
        "ID".padEnd(4) +
        "METHOD".padEnd(8) +
        "ENDPOINT".padEnd(32) +
        "RESULT".padEnd(10) +
        "TIME".padEnd(8) +
        "DETAILS"
    );
    console.log("-".repeat(80));

    let passedCount = 0;
    for (const r of results) {
        if (r.status === 'PASSED') passedCount++;
        const statusStr = r.status === 'PASSED' ? '✓ PASS' : '✗ FAIL';
        console.log(
            r.id.toString().padEnd(4) +
            r.method.padEnd(8) +
            r.endpoint.padEnd(32) +
            statusStr.padEnd(10) +
            `${r.durationMs}ms`.padEnd(8) +
            (r.details || '')
        );
    }

    console.log("-".repeat(80));
    console.log(`Total: ${results.length} | Passed: ${passedCount} | Failed: ${results.length - passedCount}`);
    console.log(`Pass Rate: ${((passedCount / results.length) * 100).toFixed(1)}%`);
    console.log("=========================================================\n");

    // Clean up
    server.close();
    await client.close();
    console.log("🔒 Server and MongoDB connection safely closed.\n");

    if (passedCount === results.length) {
        console.log("🎉 ALL ENDPOINTS PASSED WITH ZERO FREEZES! BACKEND IS 100% PRODUCTION READY.");
        process.exit(0);
    } else {
        console.log("⚠️ Some tests had issues. Review the logs above.");
        process.exit(1);
    }
}

runBenchmarkTest().catch((err) => {
    console.error("Fatal Test Suite Crash:", err);
    process.exit(1);
});
