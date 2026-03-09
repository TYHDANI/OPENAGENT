import Foundation

actor IPTVService {
    private let channelsURL = "https://iptv-org.github.io/api/channels.json"
    private let streamsURL = "https://iptv-org.github.io/api/streams.json"
    private let categoriesURL = "https://iptv-org.github.io/api/categories.json"
    private let countriesURL = "https://iptv-org.github.io/api/countries.json"
    private let session = URLSession.shared

    func fetchChannelsAndStreams() async throws -> ([IPTVChannel], [IPTVStream]) {
        async let channelsTask = fetchChannels()
        async let streamsTask = fetchStreams()
        let (channels, streams) = try await (channelsTask, streamsTask)
        return (channels, streams)
    }

    func fetchChannels() async throws -> [IPTVChannel] {
        let url = URL(string: channelsURL)!
        let (data, _) = try await session.data(from: url)
        let allChannels = try JSONDecoder().decode([IPTVChannel].self, from: data)
        // Filter to news and weather channels for Nighteye relevance
        return allChannels.filter { channel in
            let cats = channel.categories ?? []
            return cats.contains("news") || cats.contains("weather") || cats.contains("documentary")
        }
    }

    func fetchStreams() async throws -> [IPTVStream] {
        let url = URL(string: streamsURL)!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([IPTVStream].self, from: data)
    }

    func fetchCountries() async throws -> [IPTVCountry] {
        let url = URL(string: countriesURL)!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode([IPTVCountry].self, from: data)
    }

    /// Get stream URL for a specific channel
    func streamURL(for channelId: String) -> String? {
        // Build M3U URL for a specific country's news
        return "https://iptv-org.github.io/iptv/categories/news.m3u"
    }

    /// Get country-specific playlist
    func countryPlaylistURL(countryCode: String) -> String {
        "https://iptv-org.github.io/iptv/countries/\(countryCode.lowercased()).m3u"
    }
}
