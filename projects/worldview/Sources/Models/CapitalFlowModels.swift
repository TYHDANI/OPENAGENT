import Foundation
import CoreLocation

// MARK: - Politician Stock Trades (House/Senate Stock Watcher)
struct CongressTrade: Identifiable, Codable {
    var id: String { "\(representative ?? senator ?? "unknown")-\(transactionDate ?? "")-\(ticker ?? "N/A")" }

    let transactionDate: String?
    let owner: String?
    let ticker: String?
    let assetDescription: String?
    let assetType: String?
    let type: String? // "purchase" or "sale_full" or "sale_partial"
    let amount: String? // "$1,001 - $15,000" etc
    let representative: String? // House
    let senator: String? // Senate
    let district: String?
    let ptrLink: String?
    let capGainsOver200Usd: Bool?

    enum CodingKeys: String, CodingKey {
        case transactionDate = "transaction_date"
        case owner, ticker
        case assetDescription = "asset_description"
        case assetType = "asset_type"
        case type, amount, representative, senator, district
        case ptrLink = "ptr_link"
        case capGainsOver200Usd = "cap_gains_over_200_usd"
    }

    var memberName: String { representative ?? senator ?? "Unknown" }
    var isPurchase: Bool { type?.lowercased().contains("purchase") ?? false }
    var isSale: Bool { type?.lowercased().contains("sale") ?? false }
    var chamber: String { representative != nil ? "House" : "Senate" }

    var amountRange: (Int, Int) {
        guard let amount else { return (0, 0) }
        let cleaned = amount.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        let parts = cleaned.components(separatedBy: "-")
        let low = Int(parts.first ?? "0") ?? 0
        let high = Int(parts.last ?? "0") ?? 0
        return (low, high)
    }

    var midpointEstimate: Double {
        let (low, high) = amountRange
        return Double(low + high) / 2.0
    }
}

// MARK: - Government Contract (USASpending.gov)
struct GovernmentContract: Identifiable, Codable {
    let id: String
    let recipientName: String?
    let awardAmount: Double?
    let description: String?
    let startDate: String?
    let endDate: String?
    let awardingAgency: String?
    let fundingAgency: String?
    let naicsCode: String?
    let naicsDescription: String?
    let placeOfPerformance: String?

    enum CodingKeys: String, CodingKey {
        case id = "Award ID"
        case recipientName = "Recipient Name"
        case awardAmount = "Award Amount"
        case description = "Description"
        case startDate = "Start Date"
        case endDate = "End Date"
        case awardingAgency = "Awarding Agency"
        case fundingAgency = "Funding Agency"
        case naicsCode = "NAICS Code"
        case naicsDescription = "NAICS Description"
        case placeOfPerformance = "Place of Performance State Code"
    }
}

struct USASpendingResponse: Codable {
    let results: [USASpendingResult]?
    let page_metadata: USASpendingPageMeta?
}

struct USASpendingResult: Codable, Identifiable {
    var id: String { internalId ?? UUID().uuidString }
    let internalId: String?
    let recipientName: String?
    let awardAmount: Double?
    let description: String?
    let startDate: String?
    let awardingAgencyName: String?
    let naicsCode: String?

    enum CodingKeys: String, CodingKey {
        case internalId = "internal_id"
        case recipientName = "Recipient Name"
        case awardAmount = "Award Amount"
        case description = "Description"
        case startDate = "Start Date"
        case awardingAgencyName = "Awarding Agency"
        case naicsCode = "NAICS Code"
    }
}

struct USASpendingPageMeta: Codable {
    let page: Int?
    let hasNext: Bool?

    enum CodingKeys: String, CodingKey {
        case page
        case hasNext = "has_next"
    }
}

// MARK: - SEC 13F Filing (Hedge Fund Holdings)
struct SECFiling: Identifiable, Codable {
    let accessionNumber: String
    let filingDate: String
    let companyName: String
    let formType: String
    let cik: String

    var id: String { accessionNumber }

    enum CodingKeys: String, CodingKey {
        case accessionNumber = "accession_number"
        case filingDate = "filing_date"
        case companyName = "company_name"
        case formType = "form_type"
        case cik
    }
}

// MARK: - Insider Trade (SEC Form 4)
struct InsiderTrade: Identifiable {
    let id = UUID()
    let companyName: String
    let companyTicker: String?
    let insiderName: String
    let relationship: String
    let transactionDate: String
    let transactionType: String // P = Purchase, S = Sale
    let shares: Double
    let pricePerShare: Double?
    let sharesAfter: Double?

    var totalValue: Double? {
        guard let price = pricePerShare else { return nil }
        return shares * price
    }

    var isPurchase: Bool { transactionType == "P" }
}

// MARK: - Lobbying Filing (LDA)
struct LobbyingFiling: Identifiable, Codable {
    let id: Int?
    let filingUuid: String?
    let filingYear: Int?
    let filingPeriod: String?
    let registrantName: String?
    let clientName: String?
    let income: Double?
    let expenses: Double?
    let lobbyingActivities: [LobbyingActivity]?

    enum CodingKeys: String, CodingKey {
        case id
        case filingUuid = "filing_uuid"
        case filingYear = "filing_year"
        case filingPeriod = "filing_period"
        case registrantName = "registrant_name"
        case clientName = "client_name"
        case income, expenses
        case lobbyingActivities = "lobbying_activities"
    }

    var computedId: String { filingUuid ?? "\(id ?? 0)" }
}

struct LobbyingActivity: Codable {
    let generalIssueCode: String?
    let description: String?
    let governmentEntities: [String]?

    enum CodingKeys: String, CodingKey {
        case generalIssueCode = "general_issue_code"
        case description
        case governmentEntities = "government_entities"
    }
}

// MARK: - Sector Signal (Computed)
struct SectorSignal: Identifiable {
    let id = UUID()
    let sector: String
    let naicsCode: String?
    let politicianBuyCount: Int
    let politicianSellCount: Int
    let totalPoliticianVolume: Double
    let hedgeFundFilings: Int
    let governmentContracts: Int
    let totalContractValue: Double
    let lobbyingSpend: Double
    let signalStrength: SignalStrength
    let trendDirection: TrendDirection
    let cascadePhase: CascadePhase
    let topTickers: [String]
    let topPoliticians: [String]
    let lastUpdated: Date

    var opportunityScore: Double {
        let politScore = Double(politicianBuyCount) * 2.0
        let hedgeScore = Double(hedgeFundFilings) * 1.5
        let contractScore = min(totalContractValue / 1_000_000, 50)
        let lobbyScore = min(lobbyingSpend / 100_000, 20)
        return min(100, politScore + hedgeScore + contractScore + lobbyScore)
    }
}

enum SignalStrength: String, CaseIterable {
    case weak = "Weak"
    case moderate = "Moderate"
    case strong = "Strong"
    case veryStrong = "Very Strong"

    var color: String {
        switch self {
        case .weak: return "#90A4AE"
        case .moderate: return "#FFC107"
        case .strong: return "#FF9800"
        case .veryStrong: return "#F44336"
        }
    }

    var icon: String {
        switch self {
        case .weak: return "antenna.radiowaves.left.and.right"
        case .moderate: return "chart.line.uptrend.xyaxis"
        case .strong: return "bolt.fill"
        case .veryStrong: return "flame.fill"
        }
    }
}

enum TrendDirection: String {
    case accumulating = "Accumulating"
    case distributing = "Distributing"
    case neutral = "Neutral"
}

enum CascadePhase: Int, CaseIterable {
    case politicianEntry = 0
    case hedgeFundFollow = 1
    case contractAward = 2
    case budgetUnlock = 3

    var label: String {
        switch self {
        case .politicianEntry: return "Month 0-2: Political Entry"
        case .hedgeFundFollow: return "Month 2-4: Institutional Follow"
        case .contractAward: return "Month 4-6: Contract Awards"
        case .budgetUnlock: return "Month 6-8: Budget Unlock"
        }
    }

    var shortLabel: String {
        switch self {
        case .politicianEntry: return "Political Entry"
        case .hedgeFundFollow: return "Institutional"
        case .contractAward: return "Contracts"
        case .budgetUnlock: return "Budget Unlock"
        }
    }

    var description: String {
        switch self {
        case .politicianEntry: return "Politicians buying into sector. Legislation signals incoming."
        case .hedgeFundFollow: return "Hedge funds aligning positions. Signal strengthening."
        case .contractAward: return "Gov contracts awarded. Companies now funded."
        case .budgetUnlock: return "Vendor budgets unlocked. Hiring & spending surge."
        }
    }

    var color: String {
        switch self {
        case .politicianEntry: return "#2196F3"
        case .hedgeFundFollow: return "#FFC107"
        case .contractAward: return "#FF9800"
        case .budgetUnlock: return "#4CAF50"
        }
    }
}

// MARK: - Weekly Opportunity Report
struct OpportunityReport: Identifiable {
    let id = UUID()
    let generatedAt: Date
    let topSignals: [SectorSignal]
    let topCompanies: [OpportunityCompany]
    let weeklyHighlights: [String]
}

struct OpportunityCompany: Identifiable {
    let id = UUID()
    let name: String
    let ticker: String?
    let sector: String
    let recentContractValue: Double
    let politicianInterest: Int
    let opportunityScore: Double
    let cascadePhase: CascadePhase
    let painPoints: [String]
    let estimatedBudgetUnlock: String // "Q2 2026"
}
