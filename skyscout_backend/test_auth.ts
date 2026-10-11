import express from 'express';
import { MongoMemoryServer } from 'mongodb-memory-server';
import * as http from 'http';

// We must set this BEFORE importing db.ts so it picks up the memory URI
async function runAuthTest() {
    console.log("1. Starting In-Memory MongoDB Server...");
    const mongod = await MongoMemoryServer.create();
    process.env.MONGODB_URI = mongod.getUri();
    
    // Now we can import our modules safely
    const { connectToDatabase, client } = await import('./src/db');
    const authRoutes = (await import('./src/routes/auth')).default;

    const db = await connectToDatabase();
    console.log("-> Connected to in-memory DB.");

    // Setup Express App
    const app = express();
    app.use(express.json());
    app.use('/api/auth', authRoutes);

    // Start server on a random open port
    const server = http.createServer(app);
    await new Promise<void>((resolve) => server.listen(0, resolve));
    const port = (server.address() as any).port;
    console.log(`-> Test server running on port ${port}`);

    const testEmail = "urbanomaildelivery@gmail.com"; 

    // --- TEST 1: Request OTP ---
    console.log(`\n2. Requesting OTP for ${testEmail}...`);
    console.log(`-> Sending live email via Nodemailer SMTP...`);
    
    const req1 = await fetch(`http://localhost:${port}/api/auth/request-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: testEmail })
    });
    const res1 = await req1.json();
    console.log("-> Response:", res1);

    // --- Retrieve OTP from DB ---
    console.log("\n3. Peeking into MongoDB to get the generated OTP...");
    const user = await db.collection('users').findOne({ email: testEmail });
    const otpCode = user?.otpCode;
    console.log(`-> Found OTP in database: ${otpCode}`);

    if (!otpCode) {
        throw new Error("OTP was not saved to database!");
    }

    // --- TEST 2: Verify OTP ---
    console.log(`\n4. Verifying OTP (${otpCode})...`);
    const req2 = await fetch(`http://localhost:${port}/api/auth/verify-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: testEmail, otpCode })
    });
    const res2 = await req2.json();
    console.log("-> Response:", res2);

    if (res2.token) {
        console.log("\n✅ SUCCESS: JWT Token successfully generated!");
    } else {
        console.log("\n❌ FAILED: No JWT token returned.");
    }

    // Cleanup
    server.close();
    await client.close();
    await mongod.stop();
    process.exit(0);
}

runAuthTest().catch(console.error);
