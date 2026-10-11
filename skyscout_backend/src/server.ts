import express from 'express';
import cors from 'cors';
import { connectToDatabase } from './db';
import * as dotenv from 'dotenv';
import authRoutes from './routes/auth';
import stargazeRoutes from './routes/stargaze';
import userRoutes from './routes/user';
import constellationRoutes from './routes/constellations';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
// Increase JSON payload limit to accept base64 image strings from the client
app.use(express.json({ limit: '10mb' }));

// Serve generated audio files directly to the client
import path from 'path';
app.use(express.static(path.join(process.cwd(), 'public')));

// --- System Health Route ---
app.get('/api/health', (req, res) => {
    res.json({
        status: 'ok',
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        timestamp: new Date().toISOString()
    });
});

// --- API Route Modules ---
app.use('/api/auth', authRoutes);
app.use('/api/user', userRoutes);
app.use('/api/constellations', constellationRoutes);
app.use('/api/stargaze', stargazeRoutes);

async function startServer() {
    try {
        await connectToDatabase();
        app.listen(Number(PORT), '0.0.0.0', () => {
            console.log(`SkyScout Backend running on http://0.0.0.0:${PORT} (Local Wi-Fi IP: http://192.168.1.17:${PORT})`);
        });
    } catch (error) {
        console.error('Failed to start server:', error);
        process.exit(1);
    }
}

startServer();
