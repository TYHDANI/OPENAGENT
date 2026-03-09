import Foundation

enum SampleData {
    static let entities: [LegalEntity] = [
        LegalEntity(name: "Personal", entityType: .individual, taxTreatment: .taxable),
        LegalEntity(name: "Family Trust", entityType: .trust, taxTreatment: .taxDeferred),
        LegalEntity(name: "Crypto LLC", entityType: .llc, taxTreatment: .taxable)
    ]

    static let accounts: [CustodialAccount] = [
        CustodialAccount(entityID: entities[0].id, custodian: .coinbase, accountLabel: "Main Coinbase",
                         holdings: [
                            Holding(asset: "BTC", quantity: 1.5, currentPrice: 67000),
                            Holding(asset: "ETH", quantity: 12.0, currentPrice: 3400)
                         ]),
        CustodialAccount(entityID: entities[0].id, custodian: .kraken, accountLabel: "Kraken Trading",
                         holdings: [
                            Holding(asset: "SOL", quantity: 200, currentPrice: 145),
                            Holding(asset: "ETH", quantity: 5.0, currentPrice: 3400)
                         ]),
        CustodialAccount(entityID: entities[1].id, custodian: .iTrustCapital, accountLabel: "Trust IRA",
                         holdings: [
                            Holding(asset: "BTC", quantity: 3.0, currentPrice: 67000)
                         ])
    ]

    static let products: [YieldProduct] = [
        YieldProduct(name: "Aave V3", chain: "Ethereum", category: .lending,
                     apy: 4.2, tvl: 12_500_000_000, tvlChange7d: 2.1, tvlChange30d: 8.5,
                     collateralRatio: 1.45, sentinelScore: 82),
        YieldProduct(name: "Lido", chain: "Ethereum", category: .liquidStaking,
                     apy: 3.8, tvl: 28_000_000_000, tvlChange7d: 0.5, tvlChange30d: 3.2,
                     collateralRatio: 1.0, sentinelScore: 88),
        YieldProduct(name: "Curve 3pool", chain: "Ethereum", category: .dex,
                     apy: 2.1, tvl: 3_200_000_000, tvlChange7d: -1.2, tvlChange30d: -5.8,
                     collateralRatio: 1.0, sentinelScore: 72),
        YieldProduct(name: "MakerDAO", chain: "Ethereum", category: .cdp,
                     apy: 5.0, tvl: 8_700_000_000, tvlChange7d: 1.8, tvlChange30d: 12.0,
                     collateralRatio: 1.5, sentinelScore: 85),
        YieldProduct(name: "Yearn V3", chain: "Ethereum", category: .yieldAggregator,
                     apy: 7.5, tvl: 450_000_000, tvlChange7d: -0.3, tvlChange30d: -2.1,
                     collateralRatio: 1.0, sentinelScore: 68),
        YieldProduct(name: "EigenLayer", chain: "Ethereum", category: .restaking,
                     apy: 12.0, tvl: 15_000_000_000, tvlChange7d: 5.2, tvlChange30d: 25.0,
                     collateralRatio: 1.0, sentinelScore: 55),
        YieldProduct(name: "Marinade", chain: "Solana", category: .liquidStaking,
                     apy: 6.8, tvl: 1_500_000_000, tvlChange7d: 3.1, tvlChange30d: 15.0,
                     collateralRatio: 1.0, sentinelScore: 74),
        YieldProduct(name: "Kamino", chain: "Solana", category: .lending,
                     apy: 9.2, tvl: 800_000_000, tvlChange7d: -2.5, tvlChange30d: -8.0,
                     collateralRatio: 1.25, sentinelScore: 48)
    ]
}
