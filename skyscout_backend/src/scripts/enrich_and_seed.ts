import { connectToDatabase, client } from '../db';
import { GoogleGenAI } from '@google/genai';
import * as dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config();

// Ensure the API key is present
const apiKey = process.env.GOOGLE_API_KEY;
if (!apiKey) {
    console.error("ERROR: GOOGLE_API_KEY is required in .env to enrich the data.");
    process.exit(1);
}

const ai = new GoogleGenAI({ apiKey });

// We fetch basic names from a known open-source list
const CONSTELLATIONS_URL = "https://raw.githubusercontent.com/pirtleshell/constellations/master/constellations.json";

async function enrichAndSeed() {
    try {
        console.log("1. Fetching raw constellation data from GitHub...");
        const response = await fetch(CONSTELLATIONS_URL);
        const rawData = await response.json();
        
        // rawData is typically an array or object. Assuming it's an array of objects with { name, abbreviation }
        // For safety, let's take just the first 5 during testing, or all 88 if running fully.
        const targetConstellations = Array.isArray(rawData) ? rawData : Object.values(rawData);
        
        console.log(`-> Found ${targetConstellations.length} constellations. Beginning enrichment...`);
        
        const enrichedData = [];

        // Loop through and ask Gemma (Gemini) to enrich the data
        for (let i = 0; i < targetConstellations.length; i++) {
            const basicInfo: any = targetConstellations[i];
            const name = basicInfo.name || basicInfo; // Depends on the JSON structure

            console.log(`Enriching [${i + 1}/${targetConstellations.length}]: ${name}...`);

            const prompt = `Provide astronomical data for the constellation "${name}". 
Return strictly a raw JSON object with no markdown formatting containing these exact keys:
{
  "celestialHemisphere": "Northern, Southern, or Equatorial",
  "raRange": [min, max], // estimated Right Ascension bounds in hours (numbers)
  "decRange": [min, max], // estimated Declination bounds in degrees (numbers)
  "mythologySummary": "A 2-sentence mythological summary.",
  "scientificFacts": "A 1-sentence scientific fact mentioning key stars or distance."
}`;

            try {
                const aiResponse = await ai.models.generateContent({
                    model: 'gemini-2.5-flash',
                    contents: prompt,
                });

                let responseText = aiResponse.text || "{}";
                // Clean up possible markdown block formatting from the LLM
                responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();

                const parsedAI = JSON.parse(responseText);

                enrichedData.push({
                    name: name,
                    celestialHemisphere: parsedAI.celestialHemisphere,
                    raRange: parsedAI.raRange || [0, 0],
                    decRange: parsedAI.decRange || [0, 0],
                    mythologySummary: parsedAI.mythologySummary || "Data unavailable.",
                    scientificFacts: parsedAI.scientificFacts || "Data unavailable."
                });

                // Respect rate limits by adding a small delay
                await new Promise(res => setTimeout(res, 1000));

            } catch (err) {
                console.error(`Failed to enrich ${name}:`, err);
            }
        }

        // Save a local backup just in case
        const backupPath = path.join(__dirname, 'constellations_enriched.json');
        fs.writeFileSync(backupPath, JSON.stringify(enrichedData, null, 2));
        console.log(`\n2. Backup saved to ${backupPath}`);

        // Seed to MongoDB
        console.log("3. Connecting to MongoDB Atlas...");
        const db = await connectToDatabase();
        const collection = db.collection('constellations');

        console.log("4. Clearing old data and inserting newly enriched dataset...");
        await collection.deleteMany({});
        const result = await collection.insertMany(enrichedData);

        console.log(`✅ Successfully seeded ${result.insertedCount} fully enriched constellations into MongoDB!`);

    } catch (error) {
        console.error("Critical error during the seeding process:", error);
    } finally {
        await client.close();
        process.exit(0);
    }
}

enrichAndSeed();
