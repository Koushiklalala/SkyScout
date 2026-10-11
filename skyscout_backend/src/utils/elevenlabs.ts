import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';


/**
 * Synthesizes text to MP3 audio using Google TTS service as a high-reliability fallback.
 */
async function synthesizeWithGoogleTTS(text: string, savePath: string): Promise<boolean> {
    try {
        // Clean text: strip markdown, special characters
        const cleanText = text.replace(/[*_#`~[\]]/g, ' ').replace(/\s+/g, ' ').trim();
        const sentences = cleanText.match(/[^.!?]+[.!?]+/g) || [cleanText];
        const chunks: string[] = [];
        
        for (let s of sentences) {
            s = s.trim();
            if (!s) continue;
            while (s.length > 180) {
                const part = s.substring(0, 180);
                chunks.push(part);
                s = s.substring(180);
            }
            if (s.length > 0) chunks.push(s);
        }

        const audioBuffers: Buffer[] = [];
        for (const chunk of chunks) {
            const url = `https://translate.google.com/translate_tts?ie=UTF-8&q=${encodeURIComponent(chunk)}&tl=en&client=tw-ob`;
            const res = await fetch(url, {
                headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' },
                signal: AbortSignal.timeout(6000)
            });
            if (res.ok) {
                const arrayBuffer = await res.arrayBuffer();
                audioBuffers.push(Buffer.from(arrayBuffer));
            }
        }

        if (audioBuffers.length > 0) {
            const combinedBuffer = Buffer.concat(audioBuffers);
            fs.writeFileSync(savePath, combinedBuffer);
            console.log(`[TTS Engine] Successfully synthesized ${audioBuffers.length} audio chunks (${combinedBuffer.length} bytes) to ${savePath}`);
            return true;
        }
    } catch (err) {
        console.warn(`[TTS Engine] Google TTS synthesis warning:`, err);
    }
    return false;
}

/**
 * Generates an audio file from text using ElevenLabs API or Google TTS.
 * @param text The story text to convert to speech.
 * @returns The relative URL of the generated audio file (e.g. /audio/xyz.mp3)
 */
export async function generateAudioFromText(text: string): Promise<string> {
    const audioDir = path.join(process.cwd(), 'public', 'audio');
    if (!fs.existsSync(audioDir)) {
        fs.mkdirSync(audioDir, { recursive: true });
    }

    const hash = crypto.createHash('md5').update(text).digest('hex').substring(0, 8);
    const filename = `story_${Date.now()}_${hash}.mp3`;
    const savePath = path.join(audioDir, filename);

    const apiKey = process.env.ELEVENLABS_API_KEY;

    // 1. If ElevenLabs API key is provided, attempt ElevenLabs synthesis
    if (apiKey) {
        const voiceId = "21m00Tcm4TlvDq8ikWAM"; 
        const url = `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`;

        try {
            console.log(`[ElevenLabs] Generating audio for text length: ${text.length}`);
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'xi-api-key': apiKey,
                },
                signal: AbortSignal.timeout(5000),
                body: JSON.stringify({
                    text: text,
                    model_id: "eleven_monolingual_v1",
                    voice_settings: {
                        stability: 0.5,
                        similarity_boost: 0.75
                    }
                })
            });

            if (response.ok) {
                const arrayBuffer = await response.arrayBuffer();
                const buffer = Buffer.from(arrayBuffer);
                fs.writeFileSync(savePath, buffer);
                console.log(`[ElevenLabs] Audio saved successfully to ${savePath}`);
                return `/audio/${filename}`;
            } else {
                console.warn(`[ElevenLabs] API returned status ${response.status}. Falling back to TTS engine.`);
            }
        } catch (error) {
            console.warn("[ElevenLabs] Generation timed out or failed. Falling back to TTS engine.");
        }
    } else {
        console.log("[ElevenLabs] No API key found. Using high-speed cloud TTS synthesizer.");
    }

    // 2. High-speed, crystal-clear Google TTS engine fallback
    const ttsSuccess = await synthesizeWithGoogleTTS(text, savePath);
    if (ttsSuccess) {
        return `/audio/${filename}`;
    }

    // 3. Static fallback audio
    const fallbackPath = path.join(audioDir, 'fallback_story.mp3');
    if (!fs.existsSync(fallbackPath) || fs.statSync(fallbackPath).size < 1000) {
        await synthesizeWithGoogleTTS("Welcome, stargazing observer. The cosmic skies are quiet and waiting for your exploration.", fallbackPath);
    }
    return "/audio/fallback_story.mp3";
}

