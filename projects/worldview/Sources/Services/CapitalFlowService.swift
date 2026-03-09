import Foundation

actor CapitalFlowService {
    private let session = URLSession.shared

    // MARK: - House Stock Trades (NO KEY NEEDED)
    private let houseTradesURL = "https://house-stock-watcher-data.s3-us-west-2.amazonaws.com/data/all_transactions.json"

    func fetchHouseTrades() async throws -> [CongressTrade] {
        let url = URL(string: houseTradesURL)!
        let (data, _) = try await session.data(from: url)
        let trades = try JSONDecoder().decode([CongressTrade].self, from: data)
        // Return last 90 days of trades
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: .now)!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return trades.filter { trade in
            guard let dateStr = trade.transactionDate,
                  let date = formatter.date(from: dateStr) else { return false }
            return date >= cutoff
        }.sorted { ($0.transactionDate ?? "") > ($1.transactionDate ?? "") }
    }

    // MARK: - Senate Stock Trades (NO KEY NEEDED)
    private let senateTradesURL = "https://senate-stock-watcher-data.s3-us-west-2.amazonaws.com/data/all_transactions.json"

    func fetchSenateTrades() async throws -> [CongressTrade] {
        let url = URL(string: senateTradesURL)!
        let (data, _) = try await session.data(from: url)
        let trades = try JSONDecoder().decode([CongressTrade].self, from: data)
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: .now)!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return trades.filter { trade in
            guard let dateStr = trade.transactionDate,
                  let date = formatter.date(from: dateStr) else { return false }
            return date >= cutoff
        }.sorted { ($0.transactionDate ?? "") > ($1.transactionDate ?? "") }
    }

    // MARK: - USASpending.gov Contracts (NO KEY NEEDED)
    private let usaSpendingURL = "https://api.usaspending.gov/api/v2/search/spending_by_award/"

    func fetchRecentContracts(naicsCodes: [String]? = nil, keyword: String? = nil) async throws -> [USASpendingResult] {
        let url = URL(string: usaSpendingURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Nighteye/1.0", forHTTPHeaderField: "User-Agent")

        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: .now)!
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var filters: [String: Any] = [
            "award_type_codes": ["A", "B", "C", "D"],
            "time_period": [
                ["start_date": dateFormatter.string(from: thirtyDaysAgo),
                 "end_date": dateFormatter.string(from: .now)]
            ]
        ]

        if let naics = naicsCodes {
            filters["naics_codes"] = ["require": naics]
        }
        if let kw = keyword {
            filters["keywords"] = [kw]
        }

        let body: [String: Any] = [
            "filters": filters,
            "fields": ["Award ID", "Recipient Name", "Award Amount", "Description", "Start Date", "Awarding Agency", "NAICS Code"],
            "limit": 50,
            "page": 1,
            "sort": "Award Amount",
            "order": "desc"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(USASpendingResponse.self, from: data)
        return response.results ?? []
    }

    // MARK: - Lobbying Data (LDA Senate, NO KEY NEEDED)
    private let lobbyingURL = "https://lda.senate.gov/api/v1/filings/"

    func fetchRecentLobbying(issueCode: String? = nil) async throws -> [LobbyingFiling] {
        var components = URLComponents(string: lobbyingURL)!
        var queryItems = [
            URLQueryItem(name: "filing_year", value: "\(Calendar.current.component(.year, from: .now))"),
            URLQueryItem(name: "page_size", value: "50"),
        ]
        if let issue = issueCode {
            queryItems.append(URLQueryItem(name: "lobbying_activity_issues", value: issue))
        }
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.setValue("Nighteye/1.0", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await session.data(for: request)

        struct LDAResponse: Codable {
            let results: [LobbyingFiling]?
        }
        let response = try JSONDecoder().decode(LDAResponse.self, from: data)
        return response.results ?? []
    }

    // MARK: - Treasury Fiscal Data (NO KEY NEEDED)
    private let treasuryURL = "https://api.fiscaldata.treasury.gov/services/api/fiscal_service"

    func fetchNationalDebt() async throws -> Double {
        let url = URL(string: "\(treasuryURL)/v2/accounting/od/debt_to_penny?sort=-record_date&page[size]=1&format=json")!
        let (data, _) = try await session.data(from: url)
        struct TreasuryResponse: Codable {
            let data: [TreasuryRecord]?
        }
        struct TreasuryRecord: Codable {
            let totPubDebtOutAmt: String?
            let recordDate: String?
            enum CodingKeys: String, CodingKey {
                case totPubDebtOutAmt = "tot_pub_debt_out_amt"
                case recordDate = "record_date"
            }
        }
        let response = try JSONDecoder().decode(TreasuryResponse.self, from: data)
        return Double(response.data?.first?.totPubDebtOutAmt ?? "0") ?? 0
    }

    // MARK: - BLS Jobs Data (NO KEY NEEDED for v1)
    private let blsURL = "https://api.bls.gov/publicAPI/v1/timeseries/data"

    func fetchJobOpenings() async throws -> [(String, Double)] {
        let url = URL(string: blsURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "seriesid": ["JTS000000000000000JOL"],
            "startyear": "\(Calendar.current.component(.year, from: .now) - 1)",
            "endyear": "\(Calendar.current.component(.year, from: .now))"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await session.data(for: request)

        struct BLSResponse: Codable {
            let Results: BLSResults?
        }
        struct BLSResults: Codable {
            let series: [BLSSeries]?
        }
        struct BLSSeries: Codable {
            let data: [BLSDataPoint]?
        }
        struct BLSDataPoint: Codable {
            let year: String
            let period: String
            let periodName: String?
            let value: String
        }

        let response = try JSONDecoder().decode(BLSResponse.self, from: data)
        return response.Results?.series?.first?.data?.compactMap { point in
            guard let val = Double(point.value) else { return nil }
            return ("\(point.year)-\(point.period)", val)
        } ?? []
    }

    // MARK: - Signal Analysis Engine
    func analyzeSectorSignals(
        houseTrades: [CongressTrade],
        senateTrades: [CongressTrade],
        contracts: [USASpendingResult]
    ) -> [SectorSignal] {
        let allTrades = houseTrades + senateTrades

        // Group trades by ticker/sector
        var tickerBuys: [String: [CongressTrade]] = [:]
        var tickerSells: [String: [CongressTrade]] = [:]

        for trade in allTrades {
            guard let ticker = trade.ticker, !ticker.isEmpty, ticker != "--" else { continue }
            if trade.isPurchase {
                tickerBuys[ticker, default: []].append(trade)
            } else if trade.isSale {
                tickerSells[ticker, default: []].append(trade)
            }
        }

        // Find tickers with 3+ politician buyers (signal threshold)
        var signals: [SectorSignal] = []

        for (ticker, buys) in tickerBuys where buys.count >= 3 {
            let uniqueBuyers = Set(buys.map { $0.memberName })
            let sells = tickerSells[ticker] ?? []
            let totalVolume = buys.reduce(0.0) { $0 + $1.midpointEstimate }

            let strength: SignalStrength = {
                if uniqueBuyers.count >= 10 { return .veryStrong }
                if uniqueBuyers.count >= 6 { return .strong }
                if uniqueBuyers.count >= 3 { return .moderate }
                return .weak
            }()

            let trend: TrendDirection = {
                if buys.count > sells.count * 2 { return .accumulating }
                if sells.count > buys.count * 2 { return .distributing }
                return .neutral
            }()

            // Determine cascade phase based on signal patterns
            let phase: CascadePhase = {
                if uniqueBuyers.count >= 10 { return .contractAward }
                if uniqueBuyers.count >= 6 { return .hedgeFundFollow }
                return .politicianEntry
            }()

            signals.append(SectorSignal(
                sector: ticker, // Using ticker as proxy; real impl would map to sector
                naicsCode: nil,
                politicianBuyCount: buys.count,
                politicianSellCount: sells.count,
                totalPoliticianVolume: totalVolume,
                hedgeFundFilings: 0, // Would come from 13F data
                governmentContracts: 0,
                totalContractValue: 0,
                lobbyingSpend: 0,
                signalStrength: strength,
                trendDirection: trend,
                cascadePhase: phase,
                topTickers: [ticker],
                topPoliticians: Array(uniqueBuyers.prefix(5)),
                lastUpdated: .now
            ))
        }

        return signals.sorted { $0.opportunityScore > $1.opportunityScore }
    }
}
