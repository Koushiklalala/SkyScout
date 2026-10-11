const { connectToDatabase, client } = require('./db');
const fs = require('fs');
const path = require('path');

async function initializeDatabase() {
    try {
        const db = await connectToDatabase();

        // 1. Setup 'users' collection 
        console.log("Setting up 'users' collection...");
        const usersCollection = db.collection('users');
        await usersCollection.createIndex({ email: 1 }, { unique: true });
        console.log("'users' collection and indexes ready.");

        // 2. Setup 'constellations' collection from JSON file
        console.log("Setting up 'constellations' collection...");
        const constellationsCollection = db.collection('constellations');
        
        // Read the AI-generated JSON file
        const dataPath = path.join(__dirname, 'src', 'scripts', 'seeds', 'constellations.json');
        const fileContent = fs.readFileSync(dataPath, 'utf-8');
        const constellationData = JSON.parse(fileContent);

        await constellationsCollection.deleteMany({}); // Clear existing
        const result = await constellationsCollection.insertMany(constellationData);
        console.log(`Seeded ${result.insertedCount} 'constellations' with enriched data.`);

        // 3. Setup 'stargazing_history' collection
        console.log("Setting up 'stargazing_history' collection...");
        const historyCollection = db.collection('stargazing_history');
        await historyCollection.createIndex({ userId: 1 });
        console.log("'stargazing_history' collection and indexes ready.");

        console.log("Database initialization complete!");

    } catch (error) {
        console.error("Error during database initialization:", error);
    } finally {
        await client.close();
        console.log("Database connection closed.");
    }
}

initializeDatabase();
