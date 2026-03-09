import Foundation

enum ExchangeError: LocalizedError {
    case invalidCredentials
    case rateLimited
    case networkError(Error)
    case parseError
    case unsupportedPlatform

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid API credentials"
        case .rateLimited: return "Rate limited — please try again later"
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .parseError: return "Failed to parse exchange response"
        case .unsupportedPlatform: return "Platform not yet supported"
        }
    }
}

struct ExchangeBalanceResult {
    var holdings: [Holding]
    var totalValueUSD: Double
    var lastActivityDate: Date?
}

actor ExchangeService {
    static let shared = ExchangeService()

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    // MARK: - Fetch Balances

    func fetchBalances(for account: Account) async throws -> ExchangeBalanceResult {
        switch account.platform {
        case .coinbase:
            return try await fetchCoinbaseBalances(keychainRef: account.keychainReference)
        case .kraken:
            return try await fetchKrakenBalances(keychainRef: account.keychainReference)
        case .ethWallet:
            return try await fetchEthWalletBalance(keychainRef: account.keychainReference)
        case .btcWallet:
            return try await fetchBtcWalletBalance(keychainRef: account.keychainReference)
        case .solWallet:
            return try await fetchSolWalletBalance(keychainRef: account.keychainReference)
        default:
            throw ExchangeError.unsupportedPlatform
        }
    }

    // MARK: - Coinbase

    private func fetchCoinbaseBalances(keychainRef: String) async throws -> ExchangeBalanceResult {
        let apiKey: String
        do {
            apiKey = try KeychainService.loadString(forKey: keychainRef)
        } catch {
            throw ExchangeError.invalidCredentials
        }

        guard let url = URL(string: "https://api.coinbase.com/v2/accounts") else {
            throw ExchangeError.parseError
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("2024-01-01", forHTTPHeaderField: "CB-VERSION")

        let (data, response) = try await performRequest(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ExchangeError.parseError
        }

        if httpResponse.statusCode == 429 {
            throw ExchangeError.rateLimited
        }
        if httpResponse.statusCode == 401 {
            throw ExchangeError.invalidCredentials
        }

        return try parseCoinbaseResponse(data)
    }

    private func parseCoinbaseResponse(_ data: Data) throws -> ExchangeBalanceResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accounts = json["data"] as? [[String: Any]] else {
            throw ExchangeError.parseError
        }

        var holdings: [Holding] = []
        var totalValue: Double = 0

        for account in accounts {
            guard let balance = account["balance"] as? [String: Any],
                  let amountStr = balance["amount"] as? String,
                  let amount = Double(amountStr),
                  let currency = balance["currency"] as? String,
                  amount > 0 else { continue }

            let nativeBalance = account["native_balance"] as? [String: Any]
            let valueStr = nativeBalance?["amount"] as? String ?? "0"
            let valueUSD = Double(valueStr) ?? 0

            let holding = Holding(
                symbol: currency,
                name: currency,
                quantity: amount,
                valueUSD: valueUSD,
                priceUSD: amount > 0 ? valueUSD / amount : 0
            )
            holdings.append(holding)
            totalValue += valueUSD
        }

        return ExchangeBalanceResult(
            holdings: holdings,
            totalValueUSD: totalValue,
            lastActivityDate: nil
        )
    }

    // MARK: - Kraken

    private func fetchKrakenBalances(keychainRef: String) async throws -> ExchangeBalanceResult {
        let credentials: String
        do {
            credentials = try KeychainService.loadString(forKey: keychainRef)
        } catch {
            throw ExchangeError.invalidCredentials
        }

        let parts = credentials.components(separatedBy: ":")
        guard parts.count == 2 else {
            throw ExchangeError.invalidCredentials
        }

        guard let url = URL(string: "https://api.kraken.com/0/private/Balance") else {
            throw ExchangeError.parseError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(parts[0], forHTTPHeaderField: "API-Key")
        request.setValue(parts[1], forHTTPHeaderField: "API-Sign")

        let (data, _) = try await performRequest(request)
        return try parseKrakenResponse(data)
    }

    private func parseKrakenResponse(_ data: Data) throws -> ExchangeBalanceResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: String] else {
            throw ExchangeError.parseError
        }

        var holdings: [Holding] = []
        var totalValue: Double = 0

        for (asset, balanceStr) in result {
            guard let balance = Double(balanceStr), balance > 0 else { continue }
            let holding = Holding(
                symbol: asset,
                name: asset,
                quantity: balance,
                valueUSD: 0,
                priceUSD: 0
            )
            holdings.append(holding)
        }

        return ExchangeBalanceResult(
            holdings: holdings,
            totalValueUSD: totalValue,
            lastActivityDate: nil
        )
    }

    // MARK: - On-Chain Wallets

    private func fetchEthWalletBalance(keychainRef: String) async throws -> ExchangeBalanceResult {
        let address: String
        do {
            address = try KeychainService.loadString(forKey: keychainRef)
        } catch {
            throw ExchangeError.invalidCredentials
        }

        guard let url = URL(string: "https://api.etherscan.io/api?module=account&action=balance&address=\(address)&tag=latest") else {
            throw ExchangeError.parseError
        }

        let request = URLRequest(url: url)
        let (data, _) = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let resultStr = json["result"] as? String,
              let weiBalance = Double(resultStr) else {
            throw ExchangeError.parseError
        }

        let ethBalance = weiBalance / 1_000_000_000_000_000_000

        let holding = Holding(
            symbol: "ETH",
            name: "Ethereum",
            quantity: ethBalance,
            valueUSD: 0,
            priceUSD: 0
        )

        return ExchangeBalanceResult(
            holdings: [holding],
            totalValueUSD: 0,
            lastActivityDate: nil
        )
    }

    private func fetchBtcWalletBalance(keychainRef: String) async throws -> ExchangeBalanceResult {
        let address: String
        do {
            address = try KeychainService.loadString(forKey: keychainRef)
        } catch {
            throw ExchangeError.invalidCredentials
        }

        guard let url = URL(string: "https://blockstream.info/api/address/\(address)") else {
            throw ExchangeError.parseError
        }

        let request = URLRequest(url: url)
        let (data, _) = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let chainStats = json["chain_stats"] as? [String: Any],
              let fundedSum = chainStats["funded_txo_sum"] as? Int,
              let spentSum = chainStats["spent_txo_sum"] as? Int else {
            throw ExchangeError.parseError
        }

        let satBalance = fundedSum - spentSum
        let btcBalance = Double(satBalance) / 100_000_000

        let holding = Holding(
            symbol: "BTC",
            name: "Bitcoin",
            quantity: btcBalance,
            valueUSD: 0,
            priceUSD: 0
        )

        return ExchangeBalanceResult(
            holdings: [holding],
            totalValueUSD: 0,
            lastActivityDate: nil
        )
    }

    private func fetchSolWalletBalance(keychainRef: String) async throws -> ExchangeBalanceResult {
        let address: String
        do {
            address = try KeychainService.loadString(forKey: keychainRef)
        } catch {
            throw ExchangeError.invalidCredentials
        }

        guard let url = URL(string: "https://api.mainnet-beta.solana.com") else {
            throw ExchangeError.parseError
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "getBalance",
            "params": [address]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any],
              let lamports = result["value"] as? Int else {
            throw ExchangeError.parseError
        }

        let solBalance = Double(lamports) / 1_000_000_000

        let holding = Holding(
            symbol: "SOL",
            name: "Solana",
            quantity: solBalance,
            valueUSD: 0,
            priceUSD: 0
        )

        return ExchangeBalanceResult(
            holdings: [holding],
            totalValueUSD: 0,
            lastActivityDate: nil
        )
    }

    // MARK: - Price Fetching

    func fetchPrices(symbols: [String]) async throws -> [String: Double] {
        let ids = symbols.map { $0.lowercased() }.joined(separator: ",")
        guard let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=\(ids)&vs_currencies=usd") else {
            return [:]
        }

        let request = URLRequest(url: url)
        let (data, _) = try await performRequest(request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: [String: Double]] else {
            return [:]
        }

        var prices: [String: Double] = [:]
        for (coin, priceData) in json {
            if let usdPrice = priceData["usd"] {
                prices[coin.uppercased()] = usdPrice
            }
        }
        return prices
    }

    // MARK: - Helpers

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw ExchangeError.networkError(error)
        }
    }
}
