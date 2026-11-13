import SwiftUI

// MARK: - App Settings

struct AppSettingsView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmSample = false
    @State private var confirmClear = false
    @State private var toast: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            CKNavHeader(title: "App Settings", subtitle: "Data, currency and more.", onBack: { dismiss() })
            ScrollView {
                VStack(spacing: 14) {
                    ProfileSection(title: "General") {
                        infoRow(icon: "pesosign.circle", title: "Currency", value: "Philippine Peso (₱)")
                        infoRow(icon: "globe", title: "Language", value: "English")
                        infoRow(icon: "cloud", title: "Data Storage",
                                value: ServiceFactory.isFirebaseConfigured ? "Cloud Firestore" : "Not connected")
                        infoRow(icon: "photo", title: "Photos", value: "This device + thumbnail", isLast: true)
                    }

                    ProfileSection(title: "Your Data") {
                        infoRow(icon: "bag", title: "Products", value: "\(store.products.count)")
                        infoRow(icon: "shippingbox", title: "Materials", value: "\(store.materials.count)")
                        infoRow(icon: "chart.bar", title: "Production Records", value: "\(store.records.count)")
                        infoRow(icon: "cart", title: "Sales", value: "\(store.sales.count)", isLast: true)
                    }

                    ProfileSection(title: "Maintenance") {
                        ProfileRow(icon: "tray.and.arrow.down", title: "Load Sample Data",
                                   subtitle: "Replace your data with the demo bakery") { confirmSample = true }
                        ProfileRow(icon: "hand.wave", title: "Show Onboarding Again",
                                   subtitle: "See the welcome screen on next launch") {
                            UserDefaults.standard.set(false, forKey: "chekita.hasSeenOnboarding")
                            showToast("Onboarding will show after you log out.")
                        }
                        ProfileRow(icon: "trash", title: "Clear All Data",
                                   subtitle: "Delete all products, materials and reports", isLast: true) { confirmClear = true }
                    }

                    if let toast {
                        Label(toast, systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(CKColor.primary)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 10).fill(CKColor.aqua))
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, CKMetrics.hPadding)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
        .ckScreenBackground(waveHeight: 100)
        .alert("Load Sample Data?", isPresented: $confirmSample) {
            Button("Cancel", role: .cancel) {}
            Button("Load", role: .destructive) {
                store.loadSampleData()
                showToast("Sample data loaded.")
            }
        } message: {
            Text("This replaces your current products, materials and reports.")
        }
        .alert("Clear All Data?", isPresented: $confirmClear) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.clearAllData()
                showToast("All data cleared.")
            }
        } message: {
            Text("Are you sure you want to delete all products, materials and reports? This can't be undone.")
        }
    }

    private func infoRow(icon: String, title: String, value: String, isLast: Bool = false) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(CKColor.primary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(CKColor.aqua))
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(CKColor.navy)
                Spacer()
                Text(value).font(.system(size: 13)).foregroundStyle(CKColor.textSecondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            if !isLast { Divider().overlay(CKColor.border).padding(.leading, 58) }
        }
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            withAnimation { if toast == message { toast = nil } }
        }
    }
}

// MARK: - About

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            CKNavHeader(title: "About CheKita", onBack: { dismiss() })
            ScrollView {
                VStack(spacing: 14) {
                    Image("chekitaapp_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 130)
                    Text("Small Business Costing and Profit Analyzer")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(CKColor.navy)
                    Text("Version \(AppInfo.version) (\(AppInfo.build))")
                        .font(.system(size: 12))
                        .foregroundStyle(CKColor.textSecondary)

                    CKSectionCard(title: "What CheKita does") {
                        VStack(alignment: .leading, spacing: 8) {
                            feature("shippingbox", "Track the ingredients and packaging you buy, with their costs and stock.")
                            feature("function", "Compute ingredient cost, total cost and cost per piece automatically.")
                            feature("tag", "Get a suggested selling price (SRP) from your desired profit.")
                            feature("chart.bar", "Record production, update stock and export recipe reports as PDF.")
                            feature("cart", "Record sales to see your real income and profit, not just estimates.")
                        }
                    }
                    Text("Made for Filipino home bakers and small food businesses.")
                        .font(.system(size: 12))
                        .foregroundStyle(CKColor.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, CKMetrics.hPadding)
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
        .ckScreenBackground(waveHeight: 100)
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(CKColor.primary)
                .frame(width: 22)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(CKColor.navy)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Legal

struct LegalDocumentView: View {
    let document: LegalDocument
    var showsBackButton = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            if showsBackButton {
                CKNavHeader(title: document.rawValue, onBack: { dismiss() })
            } else {
                Text(document.rawValue)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(CKColor.navy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, CKMetrics.hPadding)
                    .padding(.top, 12)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Last updated: May 1, 2026")
                        .font(.system(size: 12))
                        .foregroundStyle(CKColor.textSecondary)
                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(section.0)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(CKColor.navy)
                            Text(section.1)
                                .font(.system(size: 13))
                                .foregroundStyle(CKColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(CKMetrics.hPadding)
            }
        }
        .ckScreenBackground(waveHeight: 100)
    }

    private var sections: [(String, String)] {
        switch document {
        case .terms:
            return [
                ("1. Using CheKita", "CheKita helps you estimate costs, prices and profit for your products. By creating an account you agree to use the app for lawful business purposes."),
                ("2. Your account", "You're responsible for keeping your login details secure and for all activity under your account."),
                ("3. Calculations", "Cost, SRP and profit figures are estimates based on the data you enter. Always review them before making pricing decisions."),
                ("4. Your content", "Products, materials, photos and reports you add remain yours. You can delete them at any time."),
                ("5. Changes", "We may update these terms. Continued use of CheKita means you accept the updated terms.")
            ]
        case .privacy:
            return [
                ("Information we collect", "Your name, email address, business name, and the products, materials, photos and production records you add."),
                ("How we use it", "Only to provide CheKita's features: costing, inventory, reports and PDF exports. We don't sell your data."),
                ("Where it's stored", "On this device, or in your secure cloud account when cloud sync is enabled."),
                ("Your choices", "You can edit your profile, delete any record, or clear all data from App Settings."),
                ("Contact", "Questions about privacy? Reach us through the support channel listed on the App Store page.")
            ]
        }
    }
}
