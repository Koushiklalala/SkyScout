const { MongoClient } = require('mongodb');
require('dotenv').config();

const uri = process.env.MONGODB_URI;

// Throw an error early if URI is not provided
if (!uri) {
    console.warn("WARNING: MONGODB_URI is not set in the .env file.");
}

const client = new MongoClient(uri || 'mongodb://localhost:27017');
let db;

async function connectToDatabase() {
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

function getDatabase() {
    if (!db) {
        throw new Error('Database not initialized. Call connectToDatabase first.');
    }
    return db;
}

module.exports = { connectToDatabase, getDatabase, client };
