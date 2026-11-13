import SwiftUI

struct RecipeReportView: View {
    let recordID: UUID

    @EnvironmentObject private var store: DataStore
    @EnvironmentObject private var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var shareURL: IdentifiedValue<URL>? = nil
    @State private var isExporting = false
    @State private var exportError: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            CKNavHeader(title: "Recipe Report", onBack: { dismiss() })

            if let record = store.record(id: recordID) {
                content(record)
            } else {
                CKEmptyState(icon: "doc.text", title: "Report not found", message: "This report may have been deleted.")
                Spacer()
            }
        }
        .ckScreenBackground(waveHeight: 100)
        .sheet(item: $shareURL) { item in
            ShareSheet(items: [item.value])
                .presentationDetents([.medium, .large])
        }
        .alert("Couldn't create PDF", isPresented: Binding(get: { exportError != nil }, set: { if !$0 { exportError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "")
        }
    }

    private func content(_ record: ProductionRecord) -> some View {
        let summary = CostSummary(ingredientCost: record.ingredientCost,
                                  overheadCost: record.overheadCost,
                                  totalCost: record.totalCost,
                                  yield: record.quantity,
                                  desiredProfitPercent: record.desiredProfitPercent,
                                  costPerPiece: record.costPerPiece,
                                  suggestedSRP: record.suggestedSRP,
                                  estimatedProfit: record.estimatedProfit)

        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    CKThumbnail(record: record, size: 72, radius: 12)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.productName)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundStyle(CKColor.navy)
                        HStack(spacing: 6) {
                            Label(Fmt.longDate(record.date), systemImage: "calendar")
                                .font(.system(size: 12))
                                .foregroundStyle(CKColor.textSecondary)
                        }
                        HStack(spacing: 6) {
                            Text("Yield: \(record.yieldLabel)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(CKColor.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(CKColor.aqua))
                            CKBadge(record.productCategory)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .ckCard(padding: 12)

                VStack(spacing: 0) {
                    tableRow(icon: nil, ["Ingredient", "Qty", "Unit Cost", "Total"], header: true)
                    ForEach(record.lines) { line in
                        tableRow(icon: line.emoji,
                                 [line.name, line.quantityLabel, Fmt.unitCost(line.unitCost), Fmt.peso(line.total)])
                        Divider().overlay(CKColor.border)
                    }
                    HStack {
                        Text("Total Ingredient Cost")
                            .font(.system(size: 13, weight: .bold))
                        Spacer()
                        Text(Fmt.peso(record.ingredientCost))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(CKColor.primary)
                    }
                    .foregroundStyle(CKColor.navy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: CKMetrics.cardRadius, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: CKMetrics.cardRadius, style: .continuous).stroke(CKColor.border, lineWidth: 1))

                if !record.overheadList.isEmpty {
                    VStack(spacing: 0) {
                        tableRow(icon: nil, ["Labor & Other Costs", "Basis", "Rate", "Total"], header: true)
                        ForEach(record.overheadList) { line in
                            tableRow(icon: nil,
                                     [line.name, line.basis == .perBatch ? "batch" : "piece",
                                      Fmt.peso(line.amount), Fmt.peso(line.total)])
                            Divider().overlay(CKColor.border)
                        }
                        HStack {
                            Text("Total Labor & Other Costs")
                                .font(.system(size: 13, weight: .bold))
                            Spacer()
                            Text(Fmt.peso(record.overheadCost))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(CKColor.primary)
                        }
                        .foregroundStyle(CKColor.navy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 10)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: CKMetrics.cardRadius, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: CKMetrics.cardRadius, style: .continuous)
                        .stroke(CKColor.border, lineWidth: 1))
                }

                CKSummaryPanel(summary: summary, large: true)

                if !record.notes.isEmpty {
                    CKSectionCard(title: "Notes") {
                        Text(record.notes)
                            .font(.system(size: 13))
                            .foregroundStyle(CKColor.textSecondary)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: record.materialsDeducted ? "checkmark.circle" : "info.circle")
                    Text(record.materialsDeducted ? "Ingredients were deducted from inventory." : "Inventory was not changed for this batch.")
                }
                .font(.system(size: 11))
                .foregroundStyle(CKColor.textSecondary)
            }
            .padding(.horizontal, CKMetrics.hPadding)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CKBottomBar {
                Button {
                    exportPDF(record)
                } label: {
                    if isExporting {
                        ProgressView().tint(.white)
                    } else {
                        Label("Download PDF", systemImage: "arrow.down.to.line")
                    }
                }
                .buttonStyle(.ckPrimary)
                .disabled(isExporting)
            }
        }
    }

    private func tableRow(icon: String?, _ values: [String], header: Bool = false) -> some View {
        HStack(spacing: 6) {
            HStack(spacing: 6) {
                if let icon {
                    Text(icon)
                        .font(.system(size: 15))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(CKColor.aquaSoft))
                }
                Text(values[0]).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(values[1]).frame(width: 54, alignment: .center)
            Text(values[2]).frame(width: 62, alignment: .trailing)
            Text(values[3]).frame(width: 66, alignment: .trailing)
        }
        .font(.system(size: 12, weight: header ? .semibold : .regular))
        .foregroundStyle(CKColor.navy)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .padding(.horizontal, 10)
        .padding(.vertical, header ? 9 : 7)
        .background(header ? CKColor.aqua : Color.white)
    }

    private func exportPDF(_ record: ProductionRecord) {
        isExporting = true
        let user = session.currentUser
        Task { @MainActor in
            defer { isExporting = false }
            do {
                let url = try PDFReportService.makeRecipeReport(
                    record: record,
                    businessName: user?.businessName.isEmpty == false ? user!.businessName : "My Business",
                    preparedBy: user?.fullName ?? "CheKita User")
                shareURL = IdentifiedValue(value: url)
            } catch {
                exportError = error.localizedDescription
            }
        }
    }
}
