import { Router, Request, Response } from 'express';
import { getDatabase } from '../db';
import { ObjectId } from 'mongodb';

const router = Router();

// GET /api/constellations — Retrieve all constellations from MongoDB
router.get('/', async (req: Request, res: Response) => {
    try {
        const db = getDatabase();
        const constellations = await db.collection('constellations').find({}).toArray();
        res.json({ count: constellations.length, constellations });
    } catch (error) {
        console.error('Error fetching constellations:', error);
        res.status(500).json({ error: 'Failed to fetch constellations' });
    }
});

// GET /api/constellations/:id — Retrieve single constellation by ID or name
router.get('/:id', async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const db = getDatabase();

        let query: any = { name: new RegExp(`^${id}$`, 'i') };
        if (ObjectId.isValid(id)) {
            query = { $or: [{ _id: new ObjectId(id) }, { name: new RegExp(`^${id}$`, 'i') }] };
        }

        const constellation = await db.collection('constellations').findOne(query);
        if (!constellation) {
            return res.status(404).json({ error: 'Constellation not found' });
        }

        res.json({ constellation });
    } catch (error) {
        console.error('Error fetching constellation:', error);
        res.status(500).json({ error: 'Failed to fetch constellation' });
    }
});

export default router;
