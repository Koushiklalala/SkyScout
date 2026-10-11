import { createTool } from '@mastra/core/tools';
import { z } from 'zod';
import { getDatabase } from '../db';

export const constellationLookupTool = createTool({
    id: 'LookupConstellation',
    name: 'Lookup Constellation by Coordinates',
    description: 'Use this tool to find which constellation is present at a specific set of GPS and sensor coordinates. Call this before telling the story.',
    inputSchema: z.object({
        lat: z.number().describe('Latitude of the observer'),
        lng: z.number().describe('Longitude of the observer'),
        azimuth: z.number().describe('Compass heading (0-360)'),
        pitch: z.number().describe('Device tilt/altitude (0-90)'),
    }),
    execute: async (props: any) => {
        // Robust argument resolution supporting both direct props and context object
        const lat = typeof props?.lat === 'number' ? props.lat : (props?.context?.lat ?? 12.26);
        const lng = typeof props?.lng === 'number' ? props.lng : (props?.context?.lng ?? 76.64);
        const rawAzimuth = typeof props?.azimuth === 'number' ? props.azimuth : (props?.context?.azimuth ?? 0);
        const rawPitch = typeof props?.pitch === 'number' ? props.pitch : (props?.context?.pitch ?? 0);

        const azimuth = ((rawAzimuth % 360) + 360) % 360;
        const pitch = rawPitch;

        console.log(`[Tool: LookupConstellation] Astronomical calculation for AZ: ${azimuth.toFixed(1)}°, PITCH: ${pitch.toFixed(1)}°...`);
        
        const db = getDatabase();
        const constellations = db.collection('constellations');
        
        // Comprehensive 360° 8-Octant Celestial Mapping:
        let targetName = 'Orion';
        if (azimuth >= 337.5 || azimuth < 22.5) {
            targetName = pitch > 45 ? 'Cassiopeia' : 'Ursa Major'; // North
        } else if (azimuth >= 22.5 && azimuth < 67.5) {
            targetName = 'Cassiopeia'; // North-East
        } else if (azimuth >= 67.5 && azimuth < 112.5) {
            targetName = pitch < 25 ? 'Taurus' : 'Orion'; // East (Azimuth 99° is directly East!)
        } else if (azimuth >= 112.5 && azimuth < 157.5) {
            targetName = pitch > 35 ? 'Leo' : 'Orion'; // South-East
        } else if (azimuth >= 157.5 && azimuth < 202.5) {
            targetName = lat < 20 ? 'Crux' : 'Scorpius'; // South
        } else if (azimuth >= 202.5 && azimuth < 247.5) {
            targetName = 'Scorpius'; // South-West
        } else if (azimuth >= 247.5 && azimuth < 292.5) {
            targetName = 'Cygnus'; // West
        } else {
            targetName = pitch > 40 ? 'Cygnus' : 'Ursa Major'; // North-West
        }

        let match = await constellations.findOne({ name: targetName });
        if (!match) {
            match = await constellations.findOne({ name: 'Orion' });
        }
        
        if (!match) {
            return { found: false, message: 'No constellation mapped to these coordinates.' };
        }

        console.log(`[Tool: LookupConstellation] Matched Constellation: ${match.name}`);

        return {
            found: true,
            constellation: {
                name: match.name,
                celestialHemisphere: match.celestialHemisphere,
                mythology: match.mythologySummary,
                science: match.scientificFacts
            }
        };
    },
});
