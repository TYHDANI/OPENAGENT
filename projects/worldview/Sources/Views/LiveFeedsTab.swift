import SwiftUI
import AVKit

struct LiveFeedsTab: View {
    @Environment(DataOrchestrator.self) private var data
    @State private var selectedCategory: FeedCategory = .news
    @State private var selectedChannel: IPTVChannel?
    @State private var selectedStream: IPTVStream?
    @State private var showPlayer = false

    enum FeedCategory: String, CaseIterable {
        case news = "News"
        case weather = "Weather"
        case rss = "Articles"

        var icon: String {
            switch self {
            case .news: return "play.tv"
            case .weather: return "cloud.sun"
            case .rss: return "newspaper"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NETheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Category selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(FeedCategory.allCases, id: \.self) { cat in
                                Button {
                                    withAnimation { selectedCategory = cat }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: cat.icon)
                                        Text(cat.rawValue)
                                    }
                                    .font(NETheme.body(13))
                                    .foregroundStyle(selectedCategory == cat ? .white : NETheme.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == cat ? NETheme.accent : NETheme.surfaceOverlay)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)

                    // Content
                    switch selectedCategory {
                    case .news:
                        IPTVChannelList(
                            channels: data.iptvChannels.filter { $0.isNewsChannel },
                            streams: data.iptvStreams,
                            onSelect: { channel, stream in
                                selectedChannel = channel
                                selectedStream = stream
                                showPlayer = true
                            }
                        )
                    case .weather:
                        IPTVChannelList(
                            channels: data.iptvChannels.filter { $0.isWeatherChannel },
                            streams: data.iptvStreams,
                            onSelect: { channel, stream in
                                selectedChannel = channel
                                selectedStream = stream
                                showPlayer = true
                            }
                        )
                    case .rss:
                        NewsArticleList(articles: data.newsArticles)
                    }
                }
            }
            .navigationTitle("Live Feeds")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showPlayer) {
                if let stream = selectedStream {
                    LivePlayerView(channel: selectedChannel, streamURL: stream.url)
                }
            }
        }
    }
}

// MARK: - IPTV Channel List
struct IPTVChannelList: View {
    let channels: [IPTVChannel]
    let streams: [IPTVStream]
    let onSelect: (IPTVChannel, IPTVStream) -> Void

    var body: some View {
        if channels.isEmpty {
            ContentUnavailableView("Loading Channels...", systemImage: "play.tv", description: Text("Fetching live stream data from 190+ countries"))
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(channels) { channel in
                        Button {
                            if let stream = streams.first(where: { $0.channel == channel.id }) {
                                onSelect(channel, stream)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                // Channel logo placeholder
                                if let logo = channel.logo, let url = URL(string: logo) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().aspectRatio(contentMode: .fit)
                                    } placeholder: {
                                        Image(systemName: "tv")
                                            .foregroundStyle(NETheme.accent)
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Image(systemName: "tv")
                                        .foregroundStyle(NETheme.accent)
                                        .frame(width: 40, height: 40)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(channel.name)
                                        .font(NETheme.body(14))
                                        .foregroundStyle(NETheme.textPrimary)
                                        .lineLimit(1)
                                    HStack(spacing: 4) {
                                        if let country = channel.country {
                                            Text(country.uppercased())
                                                .font(NETheme.mono(10))
                                        }
                                        if let cats = channel.categories {
                                            Text(cats.joined(separator: ", "))
                                                .font(NETheme.caption())
                                        }
                                    }
                                    .foregroundStyle(NETheme.textTertiary)
                                }

                                Spacer()

                                // Live indicator
                                HStack(spacing: 4) {
                                    Circle().fill(.red).frame(width: 6, height: 6)
                                    Text("LIVE")
                                        .font(NETheme.mono(9))
                                        .foregroundStyle(.red)
                                }
                            }
                            .padding(12)
                            .glassCard(cornerRadius: 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - News Article List
struct NewsArticleList: View {
    let articles: [NewsArticle]

    var body: some View {
        if articles.isEmpty {
            ContentUnavailableView("Loading News...", systemImage: "newspaper", description: Text("Aggregating RSS feeds from global sources"))
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(articles) { article in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(article.source)
                                    .font(NETheme.mono(10))
                                    .foregroundStyle(NETheme.accent)
                                Spacer()
                                Text(article.timeAgo)
                                    .font(NETheme.caption())
                                    .foregroundStyle(NETheme.textTertiary)
                            }

                            Text(article.title)
                                .font(NETheme.subheading(14))
                                .foregroundStyle(NETheme.textPrimary)
                                .lineLimit(2)

                            if let desc = article.description {
                                Text(desc)
                                    .font(NETheme.body(12))
                                    .foregroundStyle(NETheme.textSecondary)
                                    .lineLimit(3)
                            }
                        }
                        .padding(12)
                        .glassCard(cornerRadius: 12)
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Live Player
struct LivePlayerView: View {
    let channel: IPTVChannel?
    let streamURL: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                NETheme.background.ignoresSafeArea()

                VStack(spacing: 16) {
                    if let url = URL(string: streamURL) {
                        VideoPlayer(player: AVPlayer(url: url))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .frame(maxHeight: 300)
                    }

                    if let channel {
                        VStack(spacing: 4) {
                            Text(channel.name)
                                .font(NETheme.heading(18))
                                .foregroundStyle(NETheme.textPrimary)
                            if let country = channel.country {
                                Text(country)
                                    .font(NETheme.body())
                                    .foregroundStyle(NETheme.textSecondary)
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(NETheme.accent)
                }
            }
        }
    }
}
