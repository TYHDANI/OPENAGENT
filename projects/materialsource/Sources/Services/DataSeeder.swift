import Foundation
import SwiftData

/// Seeds initial material data for the app
final class DataSeeder {
    static func seedDataIfNeeded(modelContext: ModelContext) async {
        await MainActor.run {
            do {
                // Check if data already exists
                let materialCount = try modelContext.fetchCount(FetchDescriptor<Material>())
                if materialCount > 0 {
                    return // Data already seeded
                }

                // Create suppliers
                let suppliers = createSuppliers()
                suppliers.forEach { modelContext.insert($0) }

                // Create materials with suppliers
                let materials = createMaterials(suppliers: suppliers)
                materials.forEach { modelContext.insert($0) }

                try modelContext.save()
                print("Successfully seeded \(materials.count) materials and \(suppliers.count) suppliers")
            } catch {
                print("Failed to seed data: \(error)")
            }
        }
    }

    private static func createSuppliers() -> [Supplier] {
        [
            Supplier(
                name: "Titanium Industries Inc.",
                location: "United States",
                leadTimeRange: "2-4 weeks",
                minimumOrderQuantity: "10 lbs",
                certifications: ["ISO 9001:2015", "AS9100D", "ITAR Registered"],
                verified: true
            ),
            Supplier(
                name: "Advanced Alloys Ltd.",
                location: "United Kingdom",
                leadTimeRange: "3-6 weeks",
                minimumOrderQuantity: "5 kg",
                certifications: ["ISO 9001:2015", "NADCAP", "EN 9100"],
                verified: true
            ),
            Supplier(
                name: "Precision Materials Corp.",
                location: "Germany",
                leadTimeRange: "1-3 weeks",
                minimumOrderQuantity: "1 sheet",
                certifications: ["ISO 9001:2015", "ISO 14001", "IATF 16949"],
                verified: true
            ),
            Supplier(
                name: "Pacific Metals Supply",
                location: "Japan",
                leadTimeRange: "4-8 weeks",
                minimumOrderQuantity: "20 kg",
                certifications: ["JIS Q 9100", "ISO 9001:2015"],
                verified: false
            ),
            Supplier(
                name: "Aerospace Materials Direct",
                location: "Canada",
                leadTimeRange: "1-2 weeks",
                minimumOrderQuantity: "5 lbs",
                certifications: ["AS9100D", "ISO 9001:2015", "ITAR Registered"],
                verified: true
            )
        ]
    }

    private static func createMaterials(suppliers: [Supplier]) -> [Material] {
        var materials: [Material] = []

        // Titanium Alloys
        materials.append(Material(
            name: "Ti-6Al-4V Grade 5",
            category: "Titanium Alloys",
            descriptionText: "The most widely used titanium alloy, offering excellent strength-to-weight ratio and corrosion resistance. Ideal for aerospace, medical, and marine applications.",
            specifications: [
                Specification(standard: "AMS", number: "4911", title: "Titanium Alloy Sheet, Strip, and Plate"),
                Specification(standard: "ASTM", number: "B265", title: "Titanium and Titanium Alloy Strip, Sheet, and Plate"),
                Specification(standard: "ASTM", number: "F1472", title: "Wrought Ti-6Al-4V Alloy for Surgical Implant")
            ],
            properties: [
                MaterialProperty(name: "Density", value: "4.43", unit: "g/cm³", category: .physical),
                MaterialProperty(name: "Tensile Strength", value: "950", unit: "MPa", category: .mechanical),
                MaterialProperty(name: "Yield Strength", value: "880", unit: "MPa", category: .mechanical),
                MaterialProperty(name: "Melting Point", value: "1660", unit: "°C", category: .thermal),
                MaterialProperty(name: "Elastic Modulus", value: "113.8", unit: "GPa", category: .mechanical)
            ],
            suppliers: [suppliers[0], suppliers[1], suppliers[4]],
            applications: ["Aerospace structures", "Gas turbine engines", "Medical implants", "Marine equipment"]
        ))

        materials.append(Material(
            name: "Ti-6Al-2Sn-4Zr-2Mo",
            category: "Titanium Alloys",
            descriptionText: "High-strength titanium alloy with excellent creep resistance at elevated temperatures up to 450°C. Used in jet engine compressor blades and discs.",
            specifications: [
                Specification(standard: "AMS", number: "4975", title: "Titanium Alloy Bars and Forgings"),
                Specification(standard: "AMS", number: "4976", title: "Titanium Alloy Sheet and Plate")
            ],
            properties: [
                MaterialProperty(name: "Density", value: "4.54", unit: "g/cm³", category: .physical),
                MaterialProperty(name: "Tensile Strength", value: "1030", unit: "MPa", category: .mechanical),
                MaterialProperty(name: "Service Temperature", value: "450", unit: "°C", category: .thermal)
            ],
            suppliers: [suppliers[0], suppliers[4]],
            applications: ["Jet engine components", "High-temperature aerospace structures"]
        ))

        // Nickel Alloys
        materials.append(Material(
            name: "Inconel 718",
            category: "Nickel Alloys",
            descriptionText: "Precipitation-hardenable nickel-chromium alloy with excellent strength from -423°F to 1300°F. Highly resistant to corrosion and oxidation.",
            specifications: [
                Specification(standard: "AMS", number: "5596", title: "Nickel Alloy Sheet and Strip"),
                Specification(standard: "AMS", number: "5662", title: "Nickel Alloy Bars and Forgings"),
                Specification(standard: "ASTM", number: "B637", title: "Precipitation-Hardening Nickel Alloy Bars")
            ],
            properties: [
                MaterialProperty(name: "Density", value: "8.19", unit: "g/cm³", category: .physical),
                MaterialProperty(name: "Tensile Strength", value: "1375", unit: "MPa", category: .mechanical),
                MaterialProperty(name: "Yield Strength", value: "1100", unit: "MPa", category: .mechanical),
                MaterialProperty(name: "Max Service Temp", value: "704", unit: "°C", category: .thermal)
            ],
            suppliers: [suppliers[1], suppliers[2], suppliers[4]],
            applications: ["Gas turbine components", "Rocket engines", "Nuclear reactors", "Cryogenic tanks"]
        ))

        materials.append(Material(
            name: "Hastelloy C-276",
            category: "Nickel Alloys",
            descriptionText: "Versatile corrosion-resistant alloy with excellent resistance to pitting, stress corrosion cracking, and oxidizing atmospheres up to 1900°F.",
            specifications: [
                Specification(standard: "ASTM", number: "B575", title: "Low-Carbon Nickel-Chromium-Molybdenum"),
                Specification(standard: "AMS", number: "5666", title: "Nickel Alloy Sheet and Strip")
            ],
            properties: [
                MaterialProperty(name: "Density", value: "8.89", unit: "g/cm³", category: .physical),
                MaterialProperty(name: "Tensile Strength", value: "790", unit: "MPa", category: .mechanical),
                MaterialProperty(name: "Corrosion Rate", value: "<0.001", unit: "mm/year", category: .chemical)
            ],
            suppliers: [suppliers[1], suppliers[2]],
            applications: ["Chemical processing", "Pollution control", "Pulp and paper production"]
        ))

        // Aluminum Alloys
        materials.append(Material(
            name: "Aluminum 7075-T6",
            category: "Aluminum Alloys",
            descriptionText: "High-strength aluminum alloy with excellent fatigue resistance. Primary alloying element is zinc. Heat-treated to T6 condition for maximum strength.",
            specifications: [
                Specification(standard: "AMS", number: "4045", title: "Aluminum Alloy Sheet and Plate"),
                Specification(standard: "ASTM", number: "B209", title: "Aluminum and Aluminum-Alloy Sheet and Plate")
            ],
            properties: [
                MaterialProperty(name: "Density", value: "2.81", unit: "g/cm³", category: .physical),
                MaterialProperty(name: "Tensile Strength", value: "572", unit: "MPa", category: .mechanical),
                MaterialProperty(name: "Yield Strength", value: "503", unit: "MPa", category: .mechanical),
                MaterialProperty(name: "Thermal Conductivity", value: "130", unit: "W/m·K", category: .thermal)
            ],
            suppliers: [suppliers[0], suppliers[2], suppliers[3], suppliers[4]],
            applications: ["Aircraft structures", "High-stress parts", "Military applications", "Rock climbing equipment"]
        ))

        // Stainless Steels
        materials.append(Material(
            name: "316L Stainless Steel",
            category: "Stainless Steels",
            descriptionText: "Low-carbon austenitic stainless steel with excellent corrosion resistance, especially against chlorides. Non-magnetic and suitable for medical implants.",
            specifications: [
                Specification(standard: "ASTM", number: "A240", title: "Chromium and Chromium-Nickel Stainless Steel"),
                Specification(standard: "ASTM", number: "F138", title: "Stainless Steel Bar and Wire for Surgical Implants")
            ],
            properties: [
                MaterialProperty(name: "Density", value: "7.99", unit: "g/cm³", category: .physical),
                MaterialProperty(name: "Tensile Strength", value: "515", unit: "MPa", category: .mechanical),
                MaterialProperty(name: "Corrosion Resistance", value: "Excellent", unit: "", category: .chemical),
                MaterialProperty(name: "Magnetic", value: "Non-magnetic", unit: "", category: .physical)
            ],
            suppliers: Array(suppliers.prefix(3)),
            applications: ["Medical implants", "Marine equipment", "Chemical processing", "Pharmaceutical equipment"]
        ))

        // Composites
        materials.append(Material(
            name: "Carbon Fiber T700",
            category: "Composites",
            descriptionText: "Standard modulus carbon fiber with excellent strength and stiffness. 12K tow count. Used in aerospace and high-performance applications.",
            specifications: [
                Specification(standard: "AMS", number: "2968", title: "Quality Control of Carbon Fiber"),
                Specification(standard: "ASTM", number: "D4018", title: "Carbon and Graphite Fibers")
            ],
            properties: [
                MaterialProperty(name: "Density", value: "1.80", unit: "g/cm³", category: .physical),
                MaterialProperty(name: "Tensile Strength", value: "4900", unit: "MPa", category: .mechanical),
                MaterialProperty(name: "Tensile Modulus", value: "230", unit: "GPa", category: .mechanical),
                MaterialProperty(name: "Filament Diameter", value: "7", unit: "μm", category: .physical)
            ],
            suppliers: [suppliers[1], suppliers[2]],
            applications: ["Aerospace structures", "Wind turbine blades", "Sporting goods", "Automotive"]
        ))

        // Ceramics
        materials.append(Material(
            name: "Silicon Carbide (SiC)",
            category: "Ceramics",
            descriptionText: "Advanced ceramic with exceptional hardness, thermal conductivity, and chemical resistance. Suitable for extreme temperature and wear applications.",
            specifications: [
                Specification(standard: "ASTM", number: "C1793", title: "Silicon Carbide Fiber/Silicon Carbide Matrix")
            ],
            properties: [
                MaterialProperty(name: "Density", value: "3.21", unit: "g/cm³", category: .physical),
                MaterialProperty(name: "Hardness", value: "2800", unit: "HV", category: .mechanical),
                MaterialProperty(name: "Max Use Temperature", value: "1650", unit: "°C", category: .thermal),
                MaterialProperty(name: "Thermal Conductivity", value: "120", unit: "W/m·K", category: .thermal)
            ],
            suppliers: [suppliers[2], suppliers[3]],
            applications: ["Semiconductor processing", "Armor systems", "High-temperature bearings", "Abrasives"]
        ))

        // Assign price ranges to suppliers
        for material in materials {
            for supplier in material.suppliers {
                let basePrice = Double.random(in: 50...500)
                supplier.priceRange = PriceRange(
                    minPrice: basePrice * 0.9,
                    maxPrice: basePrice * 1.1,
                    currency: "USD",
                    unit: "per kg"
                )
                supplier.rating = Double.random(in: 4.0...5.0)
            }
        }

        return materials
    }
}