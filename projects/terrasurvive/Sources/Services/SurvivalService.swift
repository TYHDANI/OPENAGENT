import Foundation
import SwiftUI
import CoreLocation
import MapKit

// MARK: - Survival Service

@Observable
final class SurvivalService {
    // MARK: State
    var guides: [SurvivalGuide] = []
    var species: [Species] = []
    var regions: [Region] = []
    var emergencyContacts: [EmergencyContact] = []
    var sosBeacons: [SOSBeacon] = []
    var annotations: [MapAnnotationItem] = []

    var selectedRegionFilter: String? = nil
    var currentTier: SubscriptionTier = .free
    var unitsPreference: UnitsPreference = .metric

    // MARK: Init
    init() {
        loadSampleData()
    }

    // MARK: - SOS Beacon Management

    func createBeacon(latitude: Double, longitude: Double, message: String) {
        let beacon = SOSBeacon(
            latitude: latitude,
            longitude: longitude,
            message: message
        )
        sosBeacons.insert(beacon, at: 0)
    }

    func markBeaconSent(_ beacon: SOSBeacon) {
        if let index = sosBeacons.firstIndex(where: { $0.id == beacon.id }) {
            sosBeacons[index].isSent = true
        }
    }

    func deleteBeacon(_ beacon: SOSBeacon) {
        sosBeacons.removeAll { $0.id == beacon.id }
    }

    // MARK: - Filtering

    func guides(for category: GuideCategory) -> [SurvivalGuide] {
        guides.filter { $0.category == category }
    }

    func species(dangerLevel: DangerLevel) -> [Species] {
        species.filter { $0.dangerLevel == dangerLevel }
    }

    func speciesForRegion(_ regionName: String) -> [Species] {
        species.filter { $0.regions.contains(regionName) }
    }

    func edibleSpecies() -> [Species] {
        species.filter { $0.isEdible }
    }

    func dangerousSpecies() -> [Species] {
        species.filter { $0.dangerLevel == .deadly || $0.dangerLevel == .caution }
    }

    func contactsForCountry(_ country: String) -> EmergencyContact? {
        emergencyContacts.first { $0.country == country }
    }

    var allRegionNames: [String] {
        Array(Set(species.flatMap { $0.regions })).sorted()
    }

    // MARK: - Region Management

    func toggleRegionDownload(_ region: Region) {
        if let index = regions.firstIndex(where: { $0.id == region.id }) {
            regions[index].isDownloaded.toggle()
        }
    }

    // MARK: - Sample Data

    private func loadSampleData() {
        loadRegions()
        loadGuides()
        loadSpecies()
        loadEmergencyContacts()
        loadAnnotations()
    }

    private func loadRegions() {
        regions = [
            Region(
                name: "Pacific Northwest",
                biome: .temperate,
                latitude: 47.6062,
                longitude: -122.3321,
                radiusKm: 200,
                description: "Dense coniferous forests with heavy rainfall. Rich in edible plants and freshwater but challenging terrain and hypothermia risk.",
                keyThreats: ["Hypothermia", "Black bears", "Flash floods", "Dense undergrowth"],
                downloadSizeMB: 85,
                isDownloaded: true
            ),
            Region(
                name: "Mojave Desert",
                biome: .desert,
                latitude: 35.0110,
                longitude: -115.4734,
                radiusKm: 150,
                description: "Arid desert with extreme heat during the day and cold nights. Water is the primary survival challenge. Rattlesnakes and scorpions present.",
                keyThreats: ["Dehydration", "Heat stroke", "Rattlesnakes", "Scorpions", "Flash floods"],
                downloadSizeMB: 45,
                isDownloaded: false
            ),
            Region(
                name: "Appalachian Mountains",
                biome: .mountain,
                latitude: 37.3861,
                longitude: -79.9901,
                radiusKm: 300,
                description: "Eastern mountain range with deciduous forests, abundant water sources, and moderate wildlife. Good foraging opportunities in season.",
                keyThreats: ["Black bears", "Copperhead snakes", "Steep terrain", "Thunderstorms"],
                downloadSizeMB: 110,
                isDownloaded: false
            ),
        ]
    }

    private func loadGuides() {
        guides = [
            // MARK: Fire Guides (5 methods)
            SurvivalGuide(
                title: "Bow Drill Fire",
                category: .fire,
                difficulty: .intermediate,
                summary: "Create fire using friction between a spindle and fireboard. One of the most reliable primitive fire-making methods.",
                steps: [
                    "Find a dry softwood board (cedar, willow, poplar) and carve a flat surface.",
                    "Carve a spindle from the same or similar wood, about 12 inches long.",
                    "Cut a V-shaped notch in the fireboard with a small depression nearby.",
                    "Create a bow from a curved branch and cordage (shoelace, paracord, plant fiber).",
                    "Place the spindle in the depression, wrap the bowstring around it.",
                    "Apply downward pressure with a socket (hardwood or stone) on top of the spindle.",
                    "Saw the bow back and forth rapidly to spin the spindle.",
                    "Once ember forms in the notch, transfer to a tinder bundle and blow gently."
                ],
                tips: [
                    "The fireboard and spindle should be the same type of wood for best friction.",
                    "Tinder bundle should be bone-dry — birch bark, dry grass, or cedar shavings work well.",
                    "Practice this technique before you need it in an emergency."
                ],
                applicableBiomes: [.temperate, .tropical, .mountain, .grassland],
                estimatedTime: "15-30 min"
            ),
            SurvivalGuide(
                title: "Flint and Steel",
                category: .fire,
                difficulty: .beginner,
                summary: "Strike sparks from flint (or quartz) against carbon steel to ignite char cloth or fine tinder.",
                steps: [
                    "Gather char cloth or very fine tinder (birch bark, cattail fluff).",
                    "Hold the flint firmly in one hand with tinder against the top edge.",
                    "Strike downward with the steel striker at a 30-degree angle.",
                    "Direct sparks onto the char cloth or tinder.",
                    "Once the tinder catches an ember, transfer to a tinder bundle.",
                    "Blow gently until flames appear, then build up with kindling."
                ],
                tips: [
                    "Any hard, sharp rock (quartz, jasper, chert) can substitute for flint.",
                    "A carbon steel knife spine works as a striker in a pinch.",
                    "Keep your flint and steel kit in a waterproof container."
                ],
                estimatedTime: "5-10 min"
            ),
            SurvivalGuide(
                title: "Hand Drill Fire",
                category: .fire,
                difficulty: .advanced,
                summary: "The most primitive fire-starting method using only hands and wood. Requires significant skill and stamina.",
                steps: [
                    "Select a dry, straight spindle of soft wood (mullein, cattail stalk, yucca).",
                    "Prepare a fireboard with a depression and V-notch, same as bow drill.",
                    "Place tinder bundle beneath the notch to catch embers.",
                    "Roll the spindle rapidly between your palms while pressing down.",
                    "Move hands down the spindle as you press; quickly return to top and repeat.",
                    "Continue until you see smoke and a black ember forms in the notch.",
                    "Transfer ember to tinder bundle and blow to flame."
                ],
                tips: [
                    "This is extremely tiring — build hand calluses beforehand.",
                    "Spit on your palms for better grip on the spindle.",
                    "Desert plants like yucca and sotol are ideal spindle materials."
                ],
                applicableBiomes: [.desert, .tropical, .grassland],
                estimatedTime: "20-45 min"
            ),
            SurvivalGuide(
                title: "Fire Plow",
                category: .fire,
                difficulty: .intermediate,
                summary: "Create fire by plowing a hardwood shaft along a groove in softer wood, generating friction and hot dust.",
                steps: [
                    "Find a flat piece of soft wood (hibiscus, sotol, cedar) for the base.",
                    "Carve a straight groove about 6-8 inches long in the base.",
                    "Shape a harder wood stick to fit the groove.",
                    "Press the stick firmly into the groove and push forward rapidly.",
                    "Maintain constant pressure and speed.",
                    "Hot wood dust will accumulate at the end of the groove.",
                    "When smoking begins, carefully transfer to tinder bundle."
                ],
                tips: [
                    "Common in tropical environments where bow drill materials are less ideal.",
                    "Hibiscus wood is the traditional choice in Pacific Island cultures."
                ],
                applicableBiomes: [.tropical, .coastal],
                estimatedTime: "15-30 min"
            ),
            SurvivalGuide(
                title: "Solar Fire (Lens Method)",
                category: .fire,
                difficulty: .beginner,
                summary: "Focus sunlight through a lens or reflective surface to ignite tinder. Only works on clear, sunny days.",
                steps: [
                    "Gather a magnifying lens, eyeglasses, clear water bottle, or polished can bottom.",
                    "Prepare a dark-colored tinder bundle (char cloth is ideal).",
                    "Angle the lens to focus sunlight into the smallest possible point.",
                    "Hold the focused beam steady on the tinder.",
                    "Wait for the tinder to begin smoking and glowing.",
                    "Gently blow on the ember to encourage flame.",
                    "Build up fire with progressively larger kindling."
                ],
                tips: [
                    "A clear water bottle filled with water acts as a crude lens.",
                    "A polished soda can bottom with chocolate or toothpaste polish also works.",
                    "Only effective during clear daytime conditions."
                ],
                applicableBiomes: [.desert, .grassland, .mountain],
                estimatedTime: "5-15 min"
            ),

            // MARK: Water Guides (3 methods)
            SurvivalGuide(
                title: "Boiling Purification",
                category: .water,
                difficulty: .beginner,
                summary: "The simplest and most reliable water purification method. Kills bacteria, viruses, and parasites through sustained heat.",
                steps: [
                    "Collect water from the cleanest source available (flowing water preferred).",
                    "Pre-filter through cloth, sand, or grass to remove sediment.",
                    "Bring water to a rolling boil in a metal container.",
                    "Maintain the boil for at least 1 minute (3 minutes above 6,500 ft elevation).",
                    "Allow to cool before drinking.",
                    "Store in a clean container."
                ],
                tips: [
                    "You can boil water in a non-metal container using hot rocks from a fire.",
                    "Even cloudy water becomes safe after boiling — taste may be poor but it is safe.",
                    "At high altitude, water boils at a lower temperature — boil for 3+ minutes."
                ],
                estimatedTime: "10-20 min"
            ),
            SurvivalGuide(
                title: "Solar Water Disinfection (SODIS)",
                category: .water,
                difficulty: .beginner,
                summary: "Use UV radiation from sunlight to kill pathogens in clear water. Works with just a plastic bottle and sunlight.",
                steps: [
                    "Fill a clean, clear PET plastic bottle with water.",
                    "If water is cloudy, pre-filter through cloth first.",
                    "Shake the bottle vigorously for 20 seconds to oxygenate.",
                    "Place the bottle on a reflective surface (metal roof, aluminum foil).",
                    "Expose to direct sunlight for at least 6 hours (or 2 days if cloudy).",
                    "Water is now safe to drink."
                ],
                tips: [
                    "Only works with clear water — turbid water blocks UV penetration.",
                    "PET bottles only — colored or PVC bottles do not transmit UV effectively.",
                    "Endorsed by the WHO for emergency water treatment."
                ],
                applicableBiomes: [.desert, .tropical, .coastal],
                estimatedTime: "6+ hours"
            ),
            SurvivalGuide(
                title: "Improvised Sand Filter",
                category: .water,
                difficulty: .intermediate,
                summary: "Build a multi-layer gravity filter using natural materials to remove sediment and some pathogens from water.",
                steps: [
                    "Cut the bottom off a plastic bottle or use a hollow log section.",
                    "Layer materials from bottom to top: small pebbles, coarse sand, fine sand, charcoal, fine sand.",
                    "Each layer should be 2-3 inches thick.",
                    "Place a cloth or grass layer at the very bottom to hold materials.",
                    "Pour dirty water through the top slowly.",
                    "Collect filtered water at the bottom.",
                    "IMPORTANT: Still boil or treat the filtered water — this removes sediment but not all pathogens."
                ],
                tips: [
                    "Charcoal from your campfire is the key filtering agent — crush it to small pieces.",
                    "Run water through the filter multiple times for clearer results.",
                    "This is a pre-filter — always combine with boiling or chemical treatment."
                ],
                estimatedTime: "30-60 min to build"
            ),

            // MARK: Shelter Guides
            SurvivalGuide(
                title: "Debris Hut",
                category: .shelter,
                difficulty: .beginner,
                summary: "A simple, insulated shelter built from forest debris. Retains body heat effectively in temperate climates.",
                steps: [
                    "Find a long, sturdy ridgepole branch (8-10 feet).",
                    "Prop one end on a stump or Y-shaped branch, about 3 feet high.",
                    "Lean shorter branches along both sides of the ridgepole at 45 degrees.",
                    "Layer small sticks across the ribs to create a lattice.",
                    "Pile leaves, pine needles, and debris 2-3 feet thick over the lattice.",
                    "Fill the interior floor with dry leaves for insulation (at least 6 inches).",
                    "Make the shelter only slightly larger than your body to retain heat."
                ],
                tips: [
                    "The smaller the shelter, the warmer it will be — just enough room to lie down.",
                    "Entrance should face away from prevailing wind.",
                    "A thick bed of debris underneath you is more important than coverage above."
                ],
                applicableBiomes: [.temperate, .mountain],
                estimatedTime: "1-2 hours"
            ),
            SurvivalGuide(
                title: "Desert Shade Shelter",
                category: .shelter,
                difficulty: .beginner,
                summary: "A simple shade structure using available materials to reduce sun exposure and conserve body moisture in desert environments.",
                steps: [
                    "Find or dig a shallow depression in the ground (natural shade is ideal).",
                    "Use a tarp, emergency blanket, or clothing stretched between rocks or sticks.",
                    "Raise the cover 12-18 inches above the ground to allow airflow.",
                    "Anchor edges with rocks or buried stakes.",
                    "If double-layering is possible, leave an air gap between layers for better insulation.",
                    "Stay in shade during peak heat (10am-4pm)."
                ],
                tips: [
                    "A reflective emergency blanket reflects up to 90% of radiant heat.",
                    "Dig into the sand — it is cooler just a few inches below the surface.",
                    "Build shelter before you need it — working in peak heat wastes critical water."
                ],
                applicableBiomes: [.desert],
                estimatedTime: "30-60 min"
            ),

            // MARK: Signaling Guides
            SurvivalGuide(
                title: "Signal Fire",
                category: .signaling,
                difficulty: .intermediate,
                summary: "Build a fire designed to produce maximum smoke or flame visibility for rescue aircraft and ground teams.",
                steps: [
                    "Choose an open, elevated location visible from air and ground.",
                    "Build three fires in a triangle pattern (international distress signal), 100 feet apart.",
                    "Prepare each fire with dry kindling for quick ignition.",
                    "Keep green branches, wet leaves, or rubber nearby for smoke production.",
                    "When aircraft is spotted, light fires and add green material for thick white smoke.",
                    "At night, keep fires burning bright — flame is more visible than smoke."
                ],
                tips: [
                    "Three fires in a triangle is the universal distress signal.",
                    "Birch bark produces intense black smoke visible for miles.",
                    "Have signal fires pre-built and ready to light at a moment's notice."
                ],
                estimatedTime: "30-60 min to prepare"
            ),
            SurvivalGuide(
                title: "Mirror Signaling",
                category: .signaling,
                difficulty: .beginner,
                summary: "Use a reflective surface to flash sunlight toward aircraft or distant rescuers. Visible up to 50 miles on clear days.",
                steps: [
                    "Find any reflective surface: signal mirror, phone screen, metal lid, foil.",
                    "Hold the reflector near your face and aim at the target (aircraft, distant people).",
                    "Extend your other hand toward the target with two fingers in a V shape.",
                    "Tilt the mirror to cast the reflected light between your fingers toward the target.",
                    "Flash the light in sets of three (SOS pattern).",
                    "Continue flashing as long as the target is visible."
                ],
                tips: [
                    "A signal mirror can be seen up to 50 miles away on a clear day.",
                    "Even a phone screen or credit card can produce a visible flash.",
                    "Practice the two-finger aiming technique before an emergency."
                ],
                estimatedTime: "Instant"
            ),

            // MARK: First Aid Guides
            SurvivalGuide(
                title: "Wound Cleaning and Closure",
                category: .firstAid,
                difficulty: .intermediate,
                summary: "Clean, close, and dress wounds in the field to prevent infection when medical help is unavailable.",
                steps: [
                    "Stop bleeding by applying direct pressure with the cleanest cloth available.",
                    "Once bleeding slows, irrigate the wound with clean (ideally purified) water.",
                    "Remove visible debris with clean hands or sterilized tweezers.",
                    "Apply antibiotic ointment if available.",
                    "Close the wound with butterfly strips, medical tape, or improvised closures.",
                    "Cover with a clean bandage and change daily.",
                    "Monitor for signs of infection: redness spreading, warmth, swelling, pus, fever."
                ],
                tips: [
                    "Irrigation is the most important step — flush with volume, not pressure.",
                    "Super glue (cyanoacrylate) can close small cuts in an emergency.",
                    "Do NOT close bite wounds — they have high infection risk and need to drain."
                ],
                estimatedTime: "10-20 min"
            ),
            SurvivalGuide(
                title: "Splinting a Fracture",
                category: .firstAid,
                difficulty: .intermediate,
                summary: "Immobilize a suspected broken bone using improvised materials to prevent further injury during evacuation.",
                steps: [
                    "Assess the injury — do not attempt to straighten an obviously deformed limb.",
                    "Find rigid splinting material: straight sticks, trekking poles, rolled clothing.",
                    "Pad the splint with soft material (cloth, moss, clothing).",
                    "Immobilize the joint above AND below the fracture.",
                    "Secure with strips of cloth, belt, paracord, or medical tape.",
                    "Check circulation below the splint regularly (feeling, color, pulse).",
                    "Evacuate to medical care as soon as possible."
                ],
                tips: [
                    "Splint in the position found — do not try to realign bones.",
                    "A SAM splint or trekking pole makes an excellent improvised splint.",
                    "Swelling will increase — leave room and check tightness every 30 minutes."
                ],
                estimatedTime: "10-15 min"
            ),

            // MARK: Navigation Guide
            SurvivalGuide(
                title: "Shadow Stick Navigation",
                category: .navigation,
                difficulty: .beginner,
                summary: "Determine cardinal directions using the sun and a stick. Works anywhere the sun is visible, no equipment needed.",
                steps: [
                    "Push a straight stick (3-4 feet) vertically into the ground.",
                    "Mark the tip of the shadow with a small stone.",
                    "Wait 15-20 minutes.",
                    "Mark the new shadow tip position with another stone.",
                    "Draw a line between the two marks — this is your East-West line.",
                    "The first mark is West, the second mark is East.",
                    "A perpendicular line gives you North-South."
                ],
                tips: [
                    "Works in both hemispheres — the shadow always moves from west to east.",
                    "More accurate during midday hours when the sun is highest.",
                    "Combine with terrain features to confirm direction."
                ],
                estimatedTime: "20-30 min"
            ),
        ]
    }

    private func loadSpecies() {
        species = [
            // MARK: Edible / Safe Species
            Species(
                commonName: "Dandelion",
                scientificName: "Taraxacum officinale",
                kind: .plant,
                dangerLevel: .safe,
                isEdible: true,
                description: "Entire plant is edible — leaves, flowers, and roots. Rich in vitamins A, C, and K. Common worldwide in temperate regions.",
                identificationTips: [
                    "Distinctive yellow flower heads on hollow stems",
                    "Rosette of deeply toothed leaves at the base",
                    "White milky sap when stem is broken",
                    "Fluffy seed heads (puffballs) in later stages"
                ],
                regions: ["Pacific Northwest", "Appalachian Mountains"],
                habitat: "Meadows, lawns, roadsides, disturbed ground",
                seasonality: "Spring through fall"
            ),
            Species(
                commonName: "Cattail",
                scientificName: "Typha latifolia",
                kind: .plant,
                dangerLevel: .safe,
                isEdible: true,
                description: "One of the most useful survival plants. Roots, shoots, and pollen are edible. Leaves useful for weaving. Found near water worldwide.",
                identificationTips: [
                    "Tall, straight stems up to 10 feet with flat, blade-like leaves",
                    "Distinctive brown, cigar-shaped seed head",
                    "Always found in or near standing water",
                    "Young shoots resemble green corn stalks"
                ],
                regions: ["Pacific Northwest", "Appalachian Mountains", "Mojave Desert"],
                habitat: "Wetlands, pond edges, stream banks, ditches",
                seasonality: "Year-round (best spring-summer)"
            ),
            Species(
                commonName: "Hen of the Woods",
                scientificName: "Grifola frondosa",
                kind: .fungus,
                dangerLevel: .safe,
                isEdible: true,
                description: "Large, distinctive edible mushroom found at the base of oak trees. Also known as maitake. Excellent flavor and high nutritional value.",
                identificationTips: [
                    "Large clusters of overlapping gray-brown fan-shaped caps",
                    "Grows at the base of hardwood trees, especially oaks",
                    "White pore surface underneath (not gills)",
                    "Can grow to 50+ pounds in ideal conditions"
                ],
                regions: ["Appalachian Mountains", "Pacific Northwest"],
                habitat: "Base of hardwood trees, especially oaks",
                seasonality: "September through November"
            ),
            Species(
                commonName: "Wild Blueberry",
                scientificName: "Vaccinium angustifolium",
                kind: .plant,
                dangerLevel: .safe,
                isEdible: true,
                description: "Small, sweet berries growing on low bushes. Safe and calorie-dense. A reliable trail food in season.",
                identificationTips: [
                    "Low shrubs, 6-24 inches tall",
                    "Small, oval leaves with fine-toothed edges",
                    "Blue-purple berries with a dusty bloom coating",
                    "Five-pointed crown on the bottom of each berry"
                ],
                regions: ["Pacific Northwest", "Appalachian Mountains"],
                habitat: "Forest clearings, rocky slopes, acidic soils",
                seasonality: "July through September"
            ),

            // MARK: Caution Species
            Species(
                commonName: "Copperhead Snake",
                scientificName: "Agkistrodon contortrix",
                kind: .animal,
                dangerLevel: .caution,
                isEdible: false,
                description: "Venomous pit viper found throughout the eastern US. Responsible for more snakebites than any other US species. Venom is rarely fatal to healthy adults but requires medical attention.",
                identificationTips: [
                    "Distinctive hourglass-shaped copper/tan crossbands",
                    "Triangular, copper-colored head wider than the neck",
                    "Vertical (cat-eye) pupils",
                    "Heat-sensing pit between eye and nostril",
                    "Body length 2-3 feet, thick-bodied"
                ],
                regions: ["Appalachian Mountains"],
                habitat: "Rocky hillsides, leaf litter, woodpiles, forest edges",
                seasonality: "Active April through October"
            ),
            Species(
                commonName: "Arizona Bark Scorpion",
                scientificName: "Centruroides sculpturatus",
                kind: .insect,
                dangerLevel: .caution,
                isEdible: false,
                description: "The most venomous scorpion in North America. Stings cause intense pain, numbness, and potentially life-threatening symptoms in children and elderly.",
                identificationTips: [
                    "Pale yellow to orange-brown color, 2-3 inches long",
                    "Slender pincers and a thin, segmented tail with stinger",
                    "Glows bright green under UV/blacklight",
                    "Can climb walls and ceilings (unusual for scorpions)"
                ],
                regions: ["Mojave Desert"],
                habitat: "Under rocks, bark, inside shoes, crevices in buildings",
                seasonality: "Year-round (most active summer)"
            ),
            Species(
                commonName: "Morel Mushroom",
                scientificName: "Morchella esculenta",
                kind: .fungus,
                dangerLevel: .caution,
                isEdible: true,
                description: "Highly prized edible mushroom but must be distinguished from toxic false morels. True morels have a hollow interior. Must be cooked before eating.",
                identificationTips: [
                    "Honeycomb-patterned cap with pits and ridges",
                    "Completely hollow interior when cut lengthwise (key identifier)",
                    "Cap attached directly to the stem at the base (not hanging free)",
                    "Cream to dark brown color depending on species"
                ],
                regions: ["Pacific Northwest", "Appalachian Mountains"],
                habitat: "Burned areas, near dying trees, river bottoms",
                seasonality: "March through May"
            ),
            Species(
                commonName: "Black Widow Spider",
                scientificName: "Latrodectus hesperus",
                kind: .insect,
                dangerLevel: .caution,
                isEdible: false,
                description: "Venomous spider found throughout the western US. Bite causes severe pain and muscle cramps. Rarely fatal but requires medical attention.",
                identificationTips: [
                    "Shiny, jet-black body, about the size of a small grape",
                    "Red hourglass marking on the underside of the abdomen",
                    "Irregular, tangled web close to the ground",
                    "Females are larger and more dangerous than males"
                ],
                regions: ["Mojave Desert", "Pacific Northwest", "Appalachian Mountains"],
                habitat: "Dark, undisturbed areas: woodpiles, outhouses, garages, rock crevices",
                seasonality: "Year-round (most active summer)"
            ),

            // MARK: Deadly Species
            Species(
                commonName: "Death Cap Mushroom",
                scientificName: "Amanita phalloides",
                kind: .fungus,
                dangerLevel: .deadly,
                isEdible: false,
                description: "The world's most dangerous mushroom, responsible for 90% of mushroom fatality deaths. A single cap contains enough toxin to kill an adult. Symptoms are delayed 6-12 hours, making treatment difficult.",
                identificationTips: [
                    "Greenish-yellow to olive cap, 3-6 inches wide, smooth and slightly sticky",
                    "White gills (never pink or brown) that do not attach to the stem",
                    "White ring (annulus) on the upper stem",
                    "Bulbous base with a cup-like volva (often buried — dig to check!)",
                    "Smells pleasant — do NOT trust smell as a safety indicator"
                ],
                regions: ["Pacific Northwest", "Appalachian Mountains"],
                habitat: "Near oak, chestnut, and pine trees, often in disturbed urban settings",
                seasonality: "Late summer through fall"
            ),
            Species(
                commonName: "Western Diamondback Rattlesnake",
                scientificName: "Crotalus atrox",
                kind: .animal,
                dangerLevel: .deadly,
                isEdible: false,
                description: "Large, aggressive rattlesnake responsible for the most snakebite fatalities in the US. Venom causes tissue destruction and can be fatal without antivenom treatment.",
                identificationTips: [
                    "Diamond-shaped darker patches along the back bordered by lighter scales",
                    "Black and white banded tail just before the rattle",
                    "Triangular head much wider than the neck",
                    "Distinctive rattle sound when threatened (but may strike without warning)",
                    "Body length 3-5 feet, heavy-bodied"
                ],
                regions: ["Mojave Desert"],
                habitat: "Rocky desert, scrubland, canyon floors, abandoned buildings",
                seasonality: "Active March through October"
            ),
            Species(
                commonName: "Poison Hemlock",
                scientificName: "Conium maculatum",
                kind: .plant,
                dangerLevel: .deadly,
                isEdible: false,
                description: "One of the most poisonous plants in North America. All parts are toxic. Often confused with wild carrot or parsley. Ingestion causes respiratory failure.",
                identificationTips: [
                    "Smooth, hollow green stems with purple or reddish spots/blotches",
                    "Finely divided, fern-like leaves resembling parsley",
                    "Small white flowers in umbrella-shaped clusters",
                    "Musty, unpleasant smell when leaves are crushed",
                    "Grows 3-8 feet tall"
                ],
                regions: ["Pacific Northwest", "Appalachian Mountains"],
                habitat: "Roadsides, ditches, meadows, stream banks, disturbed areas",
                seasonality: "Spring through summer (flowers May-July)"
            ),
            Species(
                commonName: "Gila Monster",
                scientificName: "Heloderma suspectum",
                kind: .animal,
                dangerLevel: .caution,
                isEdible: false,
                description: "One of only two venomous lizards in North America. Slow-moving but has an extremely strong bite. Venom causes intense pain but is rarely fatal.",
                identificationTips: [
                    "Stocky body, 18-24 inches long with a thick tail",
                    "Beaded, bumpy skin with black and orange/pink/yellow pattern",
                    "Large, broad head with small, dark eyes",
                    "Slow, deliberate movement — does not chase prey"
                ],
                regions: ["Mojave Desert"],
                habitat: "Rocky desert, scrubland, burrows, under rocks",
                seasonality: "Most active April through June"
            ),
        ]
    }

    private func loadEmergencyContacts() {
        emergencyContacts = [
            EmergencyContact(
                country: "United States",
                countryCode: "US",
                police: "911",
                fire: "911",
                ambulance: "911",
                universalEmergency: "911",
                coastGuard: "1-800-424-8802",
                mountainRescue: "911"
            ),
            EmergencyContact(
                country: "Canada",
                countryCode: "CA",
                police: "911",
                fire: "911",
                ambulance: "911",
                universalEmergency: "911",
                coastGuard: "1-800-267-6687"
            ),
            EmergencyContact(
                country: "United Kingdom",
                countryCode: "GB",
                police: "999",
                fire: "999",
                ambulance: "999",
                universalEmergency: "112",
                coastGuard: "999",
                mountainRescue: "999"
            ),
            EmergencyContact(
                country: "Australia",
                countryCode: "AU",
                police: "000",
                fire: "000",
                ambulance: "000",
                universalEmergency: "112",
                coastGuard: "1800 641 792"
            ),
            EmergencyContact(
                country: "Germany",
                countryCode: "DE",
                police: "110",
                fire: "112",
                ambulance: "112",
                universalEmergency: "112",
                mountainRescue: "112"
            ),
            EmergencyContact(
                country: "Japan",
                countryCode: "JP",
                police: "110",
                fire: "119",
                ambulance: "119",
                universalEmergency: "110",
                coastGuard: "118"
            ),
        ]
    }

    private func loadAnnotations() {
        annotations = [
            MapAnnotationItem(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 47.6588, longitude: -122.3076),
                title: "Green Lake",
                kind: .waterSource
            ),
            MapAnnotationItem(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 47.5480, longitude: -121.7370),
                title: "Snoqualmie Pass Shelter",
                kind: .shelter
            ),
            MapAnnotationItem(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 47.7511, longitude: -120.7401),
                title: "Alpine Lakes Trailhead",
                kind: .trailhead
            ),
            MapAnnotationItem(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 35.1414, longitude: -115.5105),
                title: "Clark Spring",
                kind: .waterSource
            ),
            MapAnnotationItem(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 35.0078, longitude: -115.4723),
                title: "Rattlesnake Area",
                kind: .danger
            ),
            MapAnnotationItem(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 37.4220, longitude: -79.9559),
                title: "McAfee Knob Campsite",
                kind: .campsite
            ),
            MapAnnotationItem(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(latitude: 37.3936, longitude: -79.5142),
                title: "James River Water Access",
                kind: .waterSource
            ),
        ]
    }
}
