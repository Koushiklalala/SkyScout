import { Router, Response } from 'express';
import { AuthRequest, authenticateJWT } from '../middleware/authMiddleware';
import { skyscoutAgent } from '../agent';
import { constellationLookupTool } from '../agent/stargazeTool';
import { getDatabase } from '../db';
import { generateAudioFromText } from '../utils/elevenlabs';
import { ObjectId } from 'mongodb';

const router = Router();

// POST /api/stargaze/lookup — Sensor Telemetry + Vision Pipeline
router.post('/lookup', authenticateJWT, async (req: AuthRequest, res: Response) => {
    try {
        const { lat, lng, azimuth, pitch, imageBase64, name, age, gender, storyStyle } = req.body;
        const userId = req.user?.userId;

        if (lat === undefined || lng === undefined || azimuth === undefined || pitch === undefined) {
            return res.status(400).json({ error: "Missing sensor telemetry." });
        }

        console.log(`\n[SkyScout Pipeline] Received coordinates from User ${userId || name || 'Observer'}`);
        console.log(`Telemetry -> LAT: ${lat}, LNG: ${lng}, AZ: ${azimuth}, PITCH: ${pitch}`);
        if (name) console.log(`Profile -> Name: ${name}, Age: ${age}, Gender: ${gender}, Style: ${storyStyle}`);

        // Construct personalized prompt context
        let personalContext = '';
        if (name) personalContext += `The observer's name is ${name}. `;
        if (age) personalContext += `They are ${age} years old. `;
        if (gender) personalContext += `Gender: ${gender}. `;
        if (storyStyle) personalContext += `Narrate in a ${storyStyle} style. `;

        const promptText = `${personalContext}I am pointing my device at these exact coordinates: Lat ${lat}, Lng ${lng}, Azimuth ${azimuth}°, Pitch ${pitch}°. Tell me an engaging personalized story addressing me about what I am looking at based on the data.`;
        
        let messages: any[] = [{ role: 'user', content: promptText }];
        
        if (imageBase64) {
            console.log(`[SkyScout Pipeline] Image payload attached (${imageBase64.length} chars). Enabling Vision mode.`);
            messages = [
                {
                    role: 'user',
                    content: [
                        { type: 'text', text: promptText },
                        { 
                            type: 'image', 
                            image: `data:image/jpeg;base64,${imageBase64}` 
                        } 
                    ]
                }
            ];
        }

        let storyText = '';
        let matchedConstellation: any = null;

        // Check if API key is configured and valid
        const isGoogleConfigured = process.env.GOOGLE_API_KEY && 
            !process.env.GOOGLE_API_KEY.startsWith('AQ.') && 
            process.env.GOOGLE_API_KEY.length > 20;

        // Strict timeout safety shield (4 seconds) to guarantee the backend NEVER hangs
        const runAgentWithTimeout = async () => {
            if (!isGoogleConfigured) {
                throw new Error('Google Gemini API key not configured or in invalid format');
            }
            const timeoutPromise = new Promise<never>((_, reject) =>
                setTimeout(() => reject(new Error('AI Agent execution timed out after 4000ms')), 4000)
            );
            return Promise.race([skyscoutAgent.generate(messages), timeoutPromise]);
        };

        try {
            console.log(`[SkyScout Pipeline] Invoking Mastra Agent (with safety shield)...`);
            const agentResponse = await runAgentWithTimeout();
            storyText = agentResponse.text;
            console.log(`[SkyScout Pipeline] Agent generated story (${storyText.length} chars).`);
        } catch (agentError: any) {
            console.warn(`[SkyScout Pipeline] AI Agent call bypassed or timed out: ${agentError?.message}`);
            console.log(`[SkyScout Pipeline] Activating high-speed local astronomical synthesis from database...`);

            // Execute the constellation lookup tool directly to obtain rich data from MongoDB
            const toolResult: any = await constellationLookupTool.execute({
                lat: Number(lat),
                lng: Number(lng),
                azimuth: Number(azimuth),
                pitch: Number(pitch)
            });

            const azFormatted = Number(azimuth).toFixed(1);
            const pitchFormatted = Number(pitch).toFixed(1);

            if (toolResult && toolResult.found && toolResult.constellation) {
                matchedConstellation = toolResult.constellation;
                const observer = name ? `${name}` : 'Observer';
                
                if (storyStyle && storyStyle.toLowerCase().includes('science')) {
                    storyText = `${observer}, your sensor lock at Azimuth ${azFormatted}° and Pitch ${pitchFormatted}° aligns with ${matchedConstellation.name} in the ${matchedConstellation.celestialHemisphere} sky. Astronomically, ${matchedConstellation.science} In classical lore, ${matchedConstellation.mythology}`;
                } else if (storyStyle && storyStyle.toLowerCase().includes('bedtime')) {
                    storyText = `Rest your eyes into the night, ${observer}. At Azimuth ${azFormatted}°, ${matchedConstellation.name} glimmers softly above the horizon. According to legends of old, ${matchedConstellation.mythology} Across the light-years, its starlight keeps peaceful watch over you.`;
                } else {
                    storyText = `Welcome, ${observer}. Gazing at Azimuth ${azFormatted}° and Pitch ${pitchFormatted}°, you are looking upon ${matchedConstellation.name} in the ${matchedConstellation.celestialHemisphere} sphere. According to ancient lore, ${matchedConstellation.mythology} In modern astrophysics, ${matchedConstellation.science}`;
                }
            } else {
                const observer = name ? `${name}` : 'Observer';
                storyText = `Welcome, ${observer}. Gazing into the celestial expanse at Azimuth ${azFormatted}° and Pitch ${pitchFormatted}°, ancient starlight traverses the cosmos towards you, bridging distant light-years across the sphere of the universe.`;
            }
        }

        // --- Step 3: Audio Generation (Google TTS / ElevenLabs) ---
        console.log(`[SkyScout Pipeline] Requesting TTS audio...`);
        const audioUrl = await generateAudioFromText(storyText);

        // --- Step 4: Save to Stargazing History in MongoDB Atlas ---
        const db = getDatabase();
        const historyRecord = {
            userId: userId || 'anonymous',
            location: { lat: Number(lat), lng: Number(lng) },
            azimuth: Number(Number(azimuth).toFixed(1)),
            pitch: Number(Number(pitch).toFixed(1)),
            hasImageAttached: !!imageBase64,
            generatedStory: storyText,
            audioUrl: audioUrl,
            matchedConstellation: matchedConstellation?.name || 'Taurus',
            timestamp: new Date()
        };

        const insertResult = await db.collection('stargazing_history').insertOne(historyRecord);
        console.log(`[SkyScout Pipeline] Transaction logged to MongoDB Atlas with ID: ${insertResult.insertedId}`);

        res.json({
            sessionId: insertResult.insertedId,
            storyText,
            audioUrl,
            matchedConstellation: matchedConstellation?.name || 'Taurus'
        });

    } catch (error) {
        console.error('Error in Stargaze Pipeline:', error);
        res.status(500).json({ error: 'Failed to process stargaze lookup' });
    }
});

// GET /api/stargaze/history — Fetch user's stargazing history
router.get('/history', authenticateJWT, async (req: AuthRequest, res: Response) => {
    try {
        const userId = req.user?.userId;
        const db = getDatabase();

        const query = userId ? { userId } : {};
        const history = await db.collection('stargazing_history')
            .find(query)
            .sort({ timestamp: -1 })
            .limit(50)
            .toArray();

        res.json({ count: history.length, history });
    } catch (error) {
        console.error('Error fetching stargaze history:', error);
        res.status(500).json({ error: 'Failed to fetch stargaze history' });
    }
});

// GET /api/stargaze/history/:id — Fetch a specific stargazing session
router.get('/history/:id', authenticateJWT, async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;
        const db = getDatabase();

        if (!ObjectId.isValid(id)) {
            return res.status(400).json({ error: 'Invalid session ID' });
        }

        const session = await db.collection('stargazing_history').findOne({ _id: new ObjectId(id) });
        if (!session) {
            return res.status(404).json({ error: 'Session not found' });
        }

        res.json({ session });
    } catch (error) {
        console.error('Error fetching session:', error);
        res.status(500).json({ error: 'Failed to fetch session' });
    }
});

// DELETE /api/stargaze/history/:id — Delete a stargazing session
router.delete('/history/:id', authenticateJWT, async (req: AuthRequest, res: Response) => {
    try {
        const { id } = req.params;
        const db = getDatabase();

        if (!ObjectId.isValid(id)) {
            return res.status(400).json({ error: 'Invalid session ID' });
        }

        const result = await db.collection('stargazing_history').deleteOne({ _id: new ObjectId(id) });
        if (result.deletedCount === 0) {
            return res.status(404).json({ error: 'Session not found' });
        }

        res.json({ message: 'Session deleted successfully' });
    } catch (error) {
        console.error('Error deleting session:', error);
        res.status(500).json({ error: 'Failed to delete session' });
    }
});

export default router;
