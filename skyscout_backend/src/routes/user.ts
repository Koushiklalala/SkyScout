import { Router, Response } from 'express';
import { AuthRequest, authenticateJWT } from '../middleware/authMiddleware';
import { getDatabase } from '../db';
import { ObjectId } from 'mongodb';

const router = Router();

// GET /api/user/profile — Retrieve authenticated user profile
router.get('/profile', authenticateJWT, async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        const db = getDatabase();

        let user = null;
        if (userId && ObjectId.isValid(userId)) {
            user = await db.collection('users').findOne(
                { _id: new ObjectId(userId) },
                { projection: { otpCode: 0, otpExpiresAt: 0 } }
            );
        } else if (req.user?.email) {
            user = await db.collection('users').findOne(
                { email: req.user.email },
                { projection: { otpCode: 0, otpExpiresAt: 0 } }
            );
        }

        if (!user) {
            return res.status(404).json({ error: 'User not found' });
        }

        res.json({ profile: user });
    } catch (error) {
        console.error('Error fetching user profile:', error);
        res.status(500).json({ error: 'Failed to fetch user profile' });
    }
});

// PUT /api/user/profile — Update user profile details
router.put('/profile', authenticateJWT, async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        const { displayName, bio, avatarUrl } = req.body;
        const db = getDatabase();

        const updateDoc: any = {};
        if (displayName !== undefined) updateDoc.displayName = displayName;
        if (bio !== undefined) updateDoc.bio = bio;
        if (avatarUrl !== undefined) updateDoc.avatarUrl = avatarUrl;
        updateDoc.updatedAt = new Date();

        const query = (userId && ObjectId.isValid(userId)) ? { _id: new ObjectId(userId) } : { email: req.user?.email };

        await db.collection('users').updateOne(query, { $set: updateDoc });

        res.json({ message: 'Profile updated successfully', updated: updateDoc });
    } catch (error) {
        console.error('Error updating user profile:', error);
        res.status(500).json({ error: 'Failed to update user profile' });
    }
});

// GET /api/user/preferences — Retrieve user preferences
router.get('/preferences', authenticateJWT, async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        const db = getDatabase();

        const query = (userId && ObjectId.isValid(userId)) ? { _id: new ObjectId(userId) } : { email: req.user?.email };
        const user = await db.collection('users').findOne(query);

        res.json({ preferences: user?.preferences || { nightMode: true, audioNarrator: 'rachel', compassSensibility: 'high' } });
    } catch (error) {
        console.error('Error fetching preferences:', error);
        res.status(500).json({ error: 'Failed to fetch preferences' });
    }
});

// PUT /api/user/preferences — Update user preferences
router.put('/preferences', authenticateJWT, async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        const { preferences } = req.body;
        const db = getDatabase();

        const query = (userId && ObjectId.isValid(userId)) ? { _id: new ObjectId(userId) } : { email: req.user?.email };

        await db.collection('users').updateOne(
            query,
            { $set: { preferences: preferences || {}, updatedAt: new Date() } }
        );

        res.json({ message: 'Preferences updated successfully', preferences });
    } catch (error) {
        console.error('Error updating preferences:', error);
        res.status(500).json({ error: 'Failed to update preferences' });
    }
});

export default router;
