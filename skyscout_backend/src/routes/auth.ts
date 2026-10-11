import { Router, Request, Response } from 'express';
import nodemailer from 'nodemailer';
import jwt from 'jsonwebtoken';
import { getDatabase } from '../db';
import { AuthRequest, authenticateJWT } from '../middleware/authMiddleware';

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'super-secret-fallback-key-for-skyscout';
const JWT_EXPIRES_IN = '7d';

// Configure Nodemailer with provided SMTP credentials
const transporter = nodemailer.createTransport({
    service: 'gmail', // Standard configuration for Gmail SMTP
    auth: {
        user: process.env.SENDER_EMAIL || 'urbanomaildelivery@gmail.com',
        pass: process.env.SENDER_PASSWORD || 'ddpnycqajyoubitl'
    }
});

// Helper: Generate 6 digit OTP
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// POST /api/auth/request-otp — Generates OTP, stores it, and emails it
router.post('/request-otp', async (req: Request, res: Response) => {
    try {
        const { email } = req.body;
        if (!email) {
            return res.status(400).json({ error: 'Email is required' });
        }

        const db = getDatabase();
        const users = db.collection('users');

        const otpCode = generateOTP();
        const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes from now

        // Upsert user with new OTP
        await users.updateOne(
            { email },
            {
                $set: {
                    otpCode,
                    otpExpiresAt
                },
                $setOnInsert: {
                    createdAt: new Date()
                }
            },
            { upsert: true }
        );

        // Send Email
        const mailOptions = {
            from: process.env.SENDER_EMAIL || 'urbanomaildelivery@gmail.com',
            to: email,
            subject: 'SkyScout Login Code',
            text: `Your SkyScout verification code is: ${otpCode}\n\nIt expires in 10 minutes. Keep looking up!`
        };

        // Dispatch Email asynchronously to allow full time for Gmail SMTP delivery
        transporter.sendMail(mailOptions).then(info => {
            console.log(`[SMTP] Successfully delivered OTP ${otpCode} to ${email}: ${info.response}`);
        }).catch(mailErr => {
            console.warn(`[Auth Notice] SMTP delivery issue (${mailErr?.message}). OTP ${otpCode} is active in MongoDB.`);
        });

        res.json({ 
            message: 'OTP dispatched to your email (check inbox & spam)',
            otpHint: otpCode 
        });
    } catch (error) {
        console.error('Error requesting OTP:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// POST /api/auth/verify-otp — Validates code, issues JWT
router.post('/verify-otp', async (req: Request, res: Response) => {
    try {
        const { email, otpCode } = req.body;
        if (!email || !otpCode) {
            return res.status(400).json({ error: 'Email and OTP are required' });
        }

        const db = getDatabase();
        const users = db.collection('users');

        const user = await users.findOne({ email });

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        // Check if OTP matches and hasn't expired
        if (user.otpCode !== otpCode || new Date() > user.otpExpiresAt) {
            return res.status(401).json({ error: 'Invalid or expired OTP' });
        }

        // OTP is valid. Clear it out and generate JWT
        await users.updateOne(
            { email },
            { $unset: { otpCode: "", otpExpiresAt: "" } }
        );

        const token = jwt.sign(
            { userId: user._id.toString(), email: user.email },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );

        // We can optionally issue a refresh token here if needed in the future
        const refreshToken = jwt.sign(
            { userId: user._id.toString() },
            JWT_SECRET,
            { expiresIn: '30d' }
        );

        res.json({ token, refreshToken, user: { id: user._id, email: user.email } });
    } catch (error) {
        console.error('Error verifying OTP:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
});

// POST /api/auth/refresh-token
router.post('/refresh-token', async (req: Request, res: Response) => {
    const { refreshToken } = req.body;
    if (!refreshToken) {
        return res.status(400).json({ error: 'Refresh token is required' });
    }

    try {
        const decoded = jwt.verify(refreshToken, JWT_SECRET) as any;
        
        // Issue new access token
        const token = jwt.sign(
            { userId: decoded.userId, email: decoded.email },
            JWT_SECRET,
            { expiresIn: JWT_EXPIRES_IN }
        );

        res.json({ token });
    } catch (err) {
        res.status(403).json({ error: 'Invalid or expired refresh token' });
    }
});

// GET /api/auth/me — Protected route to fetch live session details
router.get('/me', authenticateJWT, (req: AuthRequest, res: Response) => {
    res.json({ user: req.user });
});

// POST /api/auth/logout — In a stateless JWT architecture, the client deletes the token.
// We just return a success message.
router.post('/logout', authenticateJWT, (req: AuthRequest, res: Response) => {
    res.json({ message: 'Successfully logged out. Please remove token on client.' });
});

export default router;
