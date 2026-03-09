import Foundation
import CoreLocation

// MARK: - IPTV Channel
struct IPTVChannel: Identifiable, Codable {
    let id: String
    let name: String
    let country: String?
    let languages: [String]?
    let categories: [String]?
    let logo: String?
    let url: String?
    let isNsfw: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, country, languages, categories, logo, url
        case isNsfw = "is_nsfw"
    }

    var isNewsChannel: Bool {
        categories?.contains("news") ?? false
    }

    var isWeatherChannel: Bool {
        categories?.contains("weather") ?? false
    }
}

struct IPTVStream: Codable {
    let channel: String
    let url: String
    let httpReferrer: String?
    let userAgent: String?

    enum CodingKeys: String, CodingKey {
        case channel, url
        case httpReferrer = "http_referrer"
        case userAgent = "user_agent"
    }
}

struct IPTVCountry: Codable, Identifiable {
    let name: String
    let code: String
    let flag: String?

    var id: String { code }
}

// MARK: - Webcam (Windy API)
struct WebcamSearchResponse: Codable {
    let webcams: [Webcam]?
}

struct Webcam: Identifiable, Codable {
    let id: String
    let title: String
    let status: String?
    let location: WebcamLocation?
    let images: WebcamImages?
    let player: WebcamPlayer?
    let categories: [WebcamCategory]?

    var coordinate: CLLocationCoordinate2D? {
        guard let loc = location else { return nil }
        return CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
    }
}

struct WebcamLocation: Codable {
    let latitude: Double
    let longitude: Double
    let city: String?
    let region: String?
    let country: String?
}

struct WebcamImages: Codable {
    let current: WebcamImageSet?
    let daylight: WebcamImageSet?
}

struct WebcamImageSet: Codable {
    let preview: String?
    let thumbnail: String?
}

struct WebcamPlayer: Codable {
    let day: String?
    let month: String?
    let year: String?
    let lifetime: String?
}

struct WebcamCategory: Codable, Identifiable {
    let id: String
    let name: String
}

// MARK: - RSS News Feed
struct RSSFeed: Identifiable {
    let id = UUID()
    let name: String
    let url: String
    let category: String
    let region: String?
}

struct NewsArticle: Identifiable {
    let id = UUID()
    let title: String
    let description: String?
    let link: String
    let pubDate: Date?
    let source: String
    let category: String
    let imageURL: String?
    let coordinate: CLLocationCoordinate2D?

    var timeAgo: String {
        guard let date = pubDate else { return "Unknown" }
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

// MARK: - Live Feed Item (unified)
struct LiveFeedItem: Identifiable {
    let id: String
    let title: String
    let streamURL: String
    let thumbnailURL: String?
    let category: LiveFeedCategory
    let country: String?
    let coordinate: CLLocationCoordinate2D?
    let isLive: Bool

    enum LiveFeedCategory: String, CaseIterable {
        case news = "News"
        case weather = "Weather"
        case nature = "Nature"
        case traffic = "Traffic"
        case webcam = "Webcam"
        case sports = "Sports"

        var icon: String {
            switch self {
            case .news: return "newspaper"
            case .weather: return "cloud.sun"
            case .nature: return "leaf"
            case .traffic: return "car"
            case .webcam: return "web.camera"
            case .sports: return "sportscourt"
            }
        }
    }
}

// MARK: - Predefined News Feeds
extension RSSFeed {
    static let worldFeeds: [RSSFeed] = [
        RSSFeed(name: "Reuters World", url: "https://feeds.reuters.com/reuters/worldNews", category: "world", region: nil),
        RSSFeed(name: "BBC World", url: "https://feeds.bbci.co.uk/news/world/rss.xml", category: "world", region: nil),
        RSSFeed(name: "Al Jazeera", url: "https://www.aljazeera.com/xml/rss/all.xml", category: "world", region: "mena"),
        RSSFeed(name: "AP News", url: "https://rsshub.app/apnews/topics/apf-topnews", category: "world", region: nil),
        RSSFeed(name: "France 24", url: "https://www.france24.com/en/rss", category: "world", region: "europe"),
        RSSFeed(name: "NHK World", url: "https://www3.nhk.or.jp/rss/news/cat0.xml", category: "world", region: "asia"),
        RSSFeed(name: "USGS Earthquakes", url: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_month.atom", category: "hazards", region: nil),
        RSSFeed(name: "ReliefWeb", url: "https://reliefweb.int/updates/rss.xml", category: "humanitarian", region: nil),
    ]
}
