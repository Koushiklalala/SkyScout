import { MongoClient, Db } from 'mongodb';
import * as dotenv from 'dotenv';

dotenv.config();

const uri = process.env.MONGODB_URI;

if (!uri) {
    console.warn("WARNING: MONGODB_URI is not set in the .env file.");
}

const client = new MongoClient(uri || 'mongodb://localhost:27017');
let db: Db;

export async function connectToDatabase(): Promise<Db> {
    if (db) return db;
    try {
        await client.connect();
        db = client.db('skyscout');
        console.log('Successfully connected to MongoDB Atlas');
        return db;
    } catch (error) {
        console.error('Error connecting to MongoDB:', error);
        throw error;
    }
}

export function getDatabase(): Db {
    if (!db) {
        throw new Error('Database not initialized. Call connectToDatabase first.');
    }
    return db;
}

export { client };
