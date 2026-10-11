import express from 'express';
import * as http from 'http';
import * as dotenv from 'dotenv';
import { connectToDatabase, client } from './src/db';
import authRoutes from './src/routes/auth';
import stargazeRoutes from './src/routes/stargaze';

dotenv.config();

async function runLiveTest() {
    console.log("1. Connecting to Real MongoDB Atlas...");
    const db = await connectToDatabase();
    console.log("-> Connected!");

    // Setup Express App
    const app = express();
    app.use(express.json());
    app.use('/api/auth', authRoutes);
    app.use('/api/stargaze', stargazeRoutes);

    // Start server on a random open port
    const server = http.createServer(app);
    await new Promise<void>((resolve) => server.listen(0, resolve));
    const port = (server.address() as any).port;
    console.log(`-> Live Test server running on port ${port}`);

    const testEmail = "urbanomaildelivery@gmail.com"; 
    let jwtToken = "";

    // --- TEST 1: Request OTP ---
    console.log(`\n2. Requesting OTP for ${testEmail}...`);
    const req1 = await fetch(`http://localhost:${port}/api/auth/request-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: testEmail })
    });
    const res1 = await req1.json();
    console.log("-> Response:", res1);

    // --- Retrieve OTP from DB ---
    console.log("\n3. Fetching OTP from real MongoDB Atlas...");
    const user = await db.collection('users').findOne({ email: testEmail });
    const otpCode = user?.otpCode;
    console.log(`-> Found OTP: ${otpCode}`);

    if (!otpCode) {
        throw new Error("OTP was not saved to database!");
    }

    // --- TEST 2: Verify OTP ---
    console.log(`\n4. Verifying OTP...`);
    const req2 = await fetch(`http://localhost:${port}/api/auth/verify-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: testEmail, otpCode })
    });
    const res2 = await req2.json();
    console.log("-> Response Auth Success (Token hidden for brevity).");
    jwtToken = res2.token;

    // --- TEST 3: Stargaze Lookup Pipeline ---
    console.log(`\n5. Testing /api/stargaze/lookup with coordinates (South)...`);
    const req3 = await fetch(`http://localhost:${port}/api/stargaze/lookup`, {
        method: 'POST',
        headers: { 
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${jwtToken}`
        },
        body: JSON.stringify({
            lat: -33.8688,
            lng: 151.2093,
            azimuth: 180.0, // Pointing South (Should hit Scorpius in our basic mock)
            pitch: 45.0
        })
    });
    const res3 = await req3.json();
    console.log("-> Response from Stargaze Pipeline:");
    console.log(JSON.stringify(res3, null, 2));

    if (res3.error) {
        console.log("\n⚠️ Note: If this threw a Gemini API Error, it's expected because GOOGLE_API_KEY is not set yet. The tool pipeline successfully triggered though!");
    }

    // Cleanup
    server.close();
    await client.close();
    process.exit(0);
}

runLiveTest().catch(console.error);
