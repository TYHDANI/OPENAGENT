import SwiftUI
import SwiftData

struct RFQListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @State private var viewModel: RFQViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    rfqContent(viewModel)
                } else {
                    ProgressView()
                        .onAppear {
                            setupViewModel()
                        }
                }
            }
            .navigationTitle("Quote Requests")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private func rfqContent(_ viewModel: RFQViewModel) -> some View {
        if viewModel.rfqs.isEmpty {
            ContentUnavailableView {
                Label("No RFQs Yet", systemImage: "envelope")
            } description: {
                Text("Request quotes from suppliers to see them here")
            } actions: {
                NavigationLink(destination: SearchView()) {
                    Text("Browse Materials")
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Stats card
                    StatsCard(viewModel: viewModel)

                    // Grouped RFQs by status
                    ForEach(viewModel.groupedRFQs, id: \.0) { status, rfqs in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                StatusBadge(status: status)
                                Text("\(rfqs.count)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }

                            ForEach(rfqs) { rfq in
                                RFQCard(rfq: rfq, viewModel: viewModel)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    private func setupViewModel() {
        let rfqService = RFQService(modelContext: modelContext)
        viewModel = RFQViewModel(rfqService: rfqService, storeManager: storeManager)

        Task {
            await viewModel?.loadRFQs()
        }
    }
}

struct StatsCard: View {
    let viewModel: RFQViewModel

    private var activeRFQs: Int {
        viewModel.rfqs.filter { $0.status == .pending || $0.status == .submitted }.count
    }

    private var quotedRFQs: Int {
        viewModel.rfqs.filter { $0.status == .quoted }.count
    }

    var body: some View {
        HStack(spacing: 20) {
            StatItem(
                value: "\(viewModel.rfqs.count)",
                label: "Total RFQs",
                icon: "envelope.fill",
                color: .blue
            )

            StatItem(
                value: "\(activeRFQs)",
                label: "Active",
                icon: "clock.fill",
                color: .orange
            )

            StatItem(
                value: "\(quotedRFQs)",
                label: "Quoted",
                icon: "checkmark.circle.fill",
                color: .green
            )
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RFQCard: View {
    let rfq: RFQ
    let viewModel: RFQViewModel

    var body: some View {
        NavigationLink(destination: RFQDetailView(rfq: rfq)) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(rfq.material.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(rfq.supplier.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    StatusBadge(status: rfq.status)
                }

                // Details
                HStack(spacing: 16) {
                    Label("\(rfq.quantity) \(rfq.unit)", systemImage: "number.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(viewModel.formatDate(rfq.submittedDate), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let targetDate = rfq.targetDeliveryDate {
                        Label(viewModel.formatDate(targetDate), systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                // Quote info if available
                if let quote = rfq.quoteReceived {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quote Received")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(viewModel.formatCurrency(quote.totalPrice))
                                .font(.headline)
                                .foregroundStyle(.green)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Lead Time")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(quote.leadTime)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.top, 4)
                }

                // Action button for draft RFQs
                if rfq.status == .draft {
                    Button {
                        Task {
                            await viewModel.submitRFQ(rfq)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Submit RFQ")
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct StatusBadge: View {
    let status: RFQStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconForStatus)
                .font(.caption2)

            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(status.color).opacity(0.15))
        .foregroundStyle(Color(status.color))
        .clipShape(Capsule())
    }

    private var iconForStatus: String {
        switch status {
        case .draft: return "pencil"
        case .submitted: return "paperplane"
        case .pending: return "clock"
        case .quoted: return "checkmark.circle"
        case .accepted: return "checkmark.seal"
        case .declined: return "xmark.circle"
        case .expired: return "exclamationmark.triangle"
        }
    }
}

#Preview {
    RFQListView()
        .environment(StoreManager())
        .modelContainer(for: [Material.self, Supplier.self, RFQ.self])
}