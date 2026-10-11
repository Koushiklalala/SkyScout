const { connectToDatabase, client } = require('./db');

const initialConstellations = [
    {
        name: "Ursa Major",
        abbreviation: "UMa",
        ra_range: { min: 8.0, max: 14.5 },
        dec_range: { min: 28.0, max: 73.0 },
        description: "The Great Bear, visible throughout the year in most of the northern hemisphere."
    },
    {
        name: "Orion",
        abbreviation: "Ori",
        ra_range: { min: 4.5, max: 6.5 },
        dec_range: { min: -11.0, max: 23.0 },
        description: "The Hunter, one of the most conspicuous and recognizable constellations in the night sky."
    },
    {
        name: "Scorpius",
        abbreviation: "Sco",
        ra_range: { min: 15.5, max: 18.0 },
        dec_range: { min: -46.0, max: -8.0 },
        description: "The Scorpion, a large constellation located in the southern hemisphere near the center of the Milky Way."
    }
];

const initialMythologies = [
    {
        constellation: "Ursa Major",
        culture: "Greek",
        story: "In Greek mythology, Ursa Major is associated with Callisto, a nymph who was turned into a bear by Hera, the jealous wife of Zeus. To protect her from hunters, Zeus placed her in the sky."
    },
    {
        constellation: "Ursa Major",
        culture: "Native American (Iroquois)",
        story: "The bowl of the Big Dipper represents a giant bear, and the three stars of the handle represent three hunters eternally chasing it across the sky."
    },
    {
        constellation: "Orion",
        culture: "Greek",
        story: "Orion was a gigantic, supernaturally strong hunter of ancient times. Zeus placed him among the stars along with his hunting dogs, Canis Major and Canis Minor."
    },
    {
        constellation: "Scorpius",
        culture: "Polynesian (Māori)",
        story: "In Māori tradition, the constellation is known as Maui's Fishhook (Te Matau-a-Māui), the magical hook used by the demigod Maui to pull up the North Island of New Zealand from the ocean."
    }
];

async function seedDatabase() {
    try {
        const db = await connectToDatabase();

        console.log("Seeding Constellations...");
        const constellationsCollection = db.collection('constellations');
        // Clear existing data
        await constellationsCollection.deleteMany({});
        await constellationsCollection.insertMany(initialConstellations);
        console.log("Constellations seeded.");

        console.log("Seeding Mythologies...");
        const mythologiesCollection = db.collection('mythologies');
        // Clear existing data
        await mythologiesCollection.deleteMany({});
        await mythologiesCollection.insertMany(initialMythologies);
        console.log("Mythologies seeded.");

    } catch (error) {
        console.error("Error during seeding:", error);
    } finally {
        await client.close();
        console.log("Database connection closed.");
    }
}

// Execute the seed function
seedDatabase();
