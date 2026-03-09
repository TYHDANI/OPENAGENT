import Foundation

actor NewsService {
    private let session = URLSession.shared

    func fetchAllFeeds() async throws -> [NewsArticle] {
        var allArticles: [NewsArticle] = []

        for feed in RSSFeed.worldFeeds {
            if let articles = try? await fetchFeed(feed) {
                allArticles.append(contentsOf: articles)
            }
        }

        return allArticles.sorted { ($0.pubDate ?? .distantPast) > ($1.pubDate ?? .distantPast) }
    }

    func fetchFeed(_ feed: RSSFeed) async throws -> [NewsArticle] {
        guard let url = URL(string: feed.url) else { return [] }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let (data, _) = try await session.data(for: request)

        guard let xmlString = String(data: data, encoding: .utf8) else { return [] }
        return parseRSS(xmlString, source: feed.name, category: feed.category)
    }

    private func parseRSS(_ xml: String, source: String, category: String) -> [NewsArticle] {
        var articles: [NewsArticle] = []
        let items = xml.components(separatedBy: "<item>").dropFirst()

        for item in items.prefix(10) {
            let title = extractTag("title", from: item)
            let desc = extractTag("description", from: item)
            let link = extractTag("link", from: item)
            let pubDateStr = extractTag("pubDate", from: item)

            guard let title, let link else { continue }

            let pubDate = parseRSSDate(pubDateStr)

            articles.append(NewsArticle(
                title: cleanHTML(title),
                description: desc.map { cleanHTML($0) },
                link: link,
                pubDate: pubDate,
                source: source,
                category: category,
                imageURL: extractImageURL(from: item),
                coordinate: nil
            ))
        }

        return articles
    }

    private func extractTag(_ tag: String, from xml: String) -> String? {
        // Handle CDATA wrapped content
        let cdataPattern = "<\(tag)><![CDATA["
        if let cdataStart = xml.range(of: cdataPattern),
           let cdataEnd = xml.range(of: "]]></\(tag)>", range: cdataStart.upperBound..<xml.endIndex) {
            return String(xml[cdataStart.upperBound..<cdataEnd.lowerBound])
        }

        guard let start = xml.range(of: "<\(tag)>"),
              let end = xml.range(of: "</\(tag)>", range: start.upperBound..<xml.endIndex) else {
            return nil
        }
        return String(xml[start.upperBound..<end.lowerBound])
    }

    private func extractImageURL(from item: String) -> String? {
        // Try media:content url
        if let start = item.range(of: "url=\"", range: item.startIndex..<item.endIndex),
           let end = item.range(of: "\"", range: start.upperBound..<item.endIndex) {
            let url = String(item[start.upperBound..<end.lowerBound])
            if url.hasSuffix(".jpg") || url.hasSuffix(".png") || url.hasSuffix(".jpeg") || url.contains("image") {
                return url
            }
        }
        return nil
    }

    private func cleanHTML(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseRSSDate(_ dateStr: String?) -> Date? {
        guard let dateStr else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Try common RSS date formats
        for format in ["EEE, dd MMM yyyy HH:mm:ss Z", "EEE, dd MMM yyyy HH:mm:ss zzz", "yyyy-MM-dd'T'HH:mm:ssZ"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateStr) { return date }
        }
        return nil
    }
}
