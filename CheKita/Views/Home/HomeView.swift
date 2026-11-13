import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var router: AppRouter

    /// Sum of each product's current batch cost (resolved against today's inventory prices,
    /// including labor and other costs).
    private var totalCost: Double {
        store.products.reduce(0) { $0 + store.summary(for: $1).totalCost }
    }

    /// Profit expected if every product's batch sells at its suggested SRP.
    private var estimatedProfit: Double {
        store.products.reduce(0) { $0 + store.summary(for: $1).estimatedProfit }
    }

    private var monthSales: SalesReport {
        SalesReport(sales: SalesReport.thisMonth(store.sales))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    CKUserChip()
                }
                .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome Back!")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(CKColor.navy)
                    Text("Let's keep track of your business.")
                        .font(.system(size: 14))
                        .foregroundStyle(CKColor.textSecondary)
                }
                .padding(.top, 14)

                VStack(spacing: 12) {
                    HomeStatCard(icon: "bag", title: "Total Products", value: "\(store.products.count)") {
                        router.select(.products)
                    }
                    HomeStatCard(icon: "creditcard", title: "Total Cost", value: Fmt.peso(totalCost)) {
                        router.select(.inventory)
                    }
                    HomeStatCard(icon: "chart.line.uptrend.xyaxis", title: "Estimated Profit", value: Fmt.peso(estimatedProfit)) {
                        router.select(.reports)
                    }
                }
                .padding(.top, 22)

                salesSection
                    .padding(.top, 22)
            }
            .padding(.horizontal, CKMetrics.hPadding + 4)
            .padding(.bottom, 24)
        }
        .ckScreenBackground(waveHeight: 150)
        .refreshable { await store.refresh() }
    }

    /// Real money: what was actually sold this month.
    private var salesSection: some View {
        let report = monthSales
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Month's Sales")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(CKColor.navy)
                    Text(report.transactions == 0
                         ? "No sales recorded yet this month."
                         : "\(report.transactions) sale\(report.transactions == 1 ? "" : "s") · \(report.unitsSold) sold")
                        .font(.system(size: 12))
                        .foregroundStyle(CKColor.textSecondary)
                }
                Spacer()
                Button("See all") { router.select(.reports) }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CKColor.primary)
            }

            HStack(spacing: 12) {
                salesTile(title: "Sales Revenue", value: Fmt.peso(report.revenue), icon: "cart")
                salesTile(title: "Actual Profit", value: Fmt.peso(report.profit), icon: "arrow.up.right", highlight: true)
            }

            if let best = report.bestSeller {
                HStack(spacing: 10) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(CKColor.primary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.white))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Best seller this month")
                            .font(.system(size: 11))
                            .foregroundStyle(CKColor.textSecondary)
                        Text(best.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(CKColor.navy)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text(Fmt.peso(best.revenue))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(CKColor.primary)
                        .monospacedDigit()
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: CKMetrics.cardRadius).fill(CKColor.aqua))
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func salesTile(title: String, value: String, icon: String, highlight: Bool = false) -> some View {
        Button {
            router.select(.reports)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(CKColor.primary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(CKColor.aqua))
                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(CKColor.textSecondary)
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(highlight ? CKColor.primary : CKColor.navy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .ckCard(padding: 0, radius: 14)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private struct HomeStatCard: View {
    let icon: String
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(CKColor.primary)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(CKColor.aqua))
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CKColor.navy)
                    Text(value)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(CKColor.navy)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .monospacedDigit()
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .ckCard(padding: 0, radius: 14)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
