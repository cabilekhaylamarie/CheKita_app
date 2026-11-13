import SwiftUI
import PhotosUI
import UIKit

// MARK: - Headers

/// Large title + subtitle used at the top of each tab ("Products / Manage your food products.").
struct CKScreenHeader<Trailing: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var trailing: () -> Trailing

    init(title: String, subtitle: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(CKColor.navy)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(CKColor.textSecondary)
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 8)
            trailing()
        }
    }
}

extension CKScreenHeader where Trailing == EmptyView {
    init(title: String, subtitle: String) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// Back button + title row used on pushed screens ("← Product Details   ⋮").
struct CKNavHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    let onBack: () -> Void
    @ViewBuilder var trailing: () -> Trailing

    init(title: String, subtitle: String? = nil, onBack: @escaping () -> Void,
         @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            CKBackButton(action: onBack)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(CKColor.navy)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(CKColor.textSecondary)
                }
            }
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, CKMetrics.hPadding)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}

extension CKNavHeader where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, onBack: @escaping () -> Void) {
        self.init(title: title, subtitle: subtitle, onBack: onBack) { EmptyView() }
    }
}

/// "👤 Hi, User! ⌄" chip with a small account menu.
struct CKUserChip: View {
    @EnvironmentObject private var session: SessionViewModel
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        Menu {
            Button {
                router.select(.profile)
            } label: {
                Label("My Profile", systemImage: "person")
            }
            Button {
                router.selectedTab = .profile
                router.popToRoot(.profile)
                router.push(.appSettings, in: .profile)
            } label: {
                Label("App Settings", systemImage: "gearshape")
            }
        } label: {
            HStack(spacing: 6) {
                CKAvatar(fileName: session.currentUser?.avatarFileName, base64: session.currentUser?.avatarData,
                         cacheKey: "avatar-\(session.currentUser?.id ?? "")", size: 26)
                Text("Hi, \(session.currentUser?.firstName ?? "User")!")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CKColor.navy)
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(CKColor.navy)
            }
            .padding(.vertical, 4)
            .padding(.leading, 4)
            .padding(.trailing, 6)
        }
        .accessibilityLabel("Account menu")
    }
}

struct CKAvatar: View {
    let fileName: String?
    /// base64 thumbnail stored on the user document (shown when the device copy is gone).
    var base64: String? = nil
    var cacheKey: String? = nil
    var size: CGFloat = 26

    private var image: UIImage? {
        ImageStore.shared.bestImage(fileName: fileName, base64: base64, assetName: nil, cacheKey: cacheKey)
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(hex: 0x7C8A96)
                    Image(systemName: "person.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .padding(size * 0.2)
                        .offset(y: size * 0.1)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Category pills

struct CKCategoryPills: View {
    let options: [String]
    @Binding var selection: String
    var columns: Int = 4

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: columns), spacing: 6) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = option }
                } label: {
                    Text(option)
                        .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                        .foregroundStyle(isSelected ? Color.white : CKColor.navy)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(Capsule().fill(isSelected ? CKColor.primary : CKColor.pill))
                        .overlay(Capsule().stroke(isSelected ? Color.clear : CKColor.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

// MARK: - Badge

struct CKBadge: View {
    let text: String
    let background: Color
    let foreground: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(background))
    }
}

extension CKBadge {
    init(_ category: ProductCategory) {
        self.init(text: category.rawValue, background: category.badgeBackground, foreground: category.badgeForeground)
    }

    init(_ category: MaterialCategory) {
        self.init(text: category.rawValue, background: category.badgeBackground, foreground: category.badgeForeground)
    }
}

// MARK: - Thumbnail (user photo → bundled asset → emoji)

struct CKThumbnail: View {
    var fileName: String?
    var assetName: String?
    /// base64 thumbnail stored in Firestore (used when the photo isn't on this device).
    var base64: String?
    var cacheKey: String?
    var emoji: String
    /// `nil` width stretches to the available width.
    var width: CGFloat?
    var height: CGFloat
    var radius: CGFloat = 10
    var tint: Color = CKColor.aquaSoft

    init(fileName: String?, assetName: String?, base64: String? = nil, cacheKey: String? = nil,
         emoji: String, size: CGFloat, radius: CGFloat = 10, tint: Color = CKColor.aquaSoft) {
        self.init(fileName: fileName, assetName: assetName, base64: base64, cacheKey: cacheKey,
                  emoji: emoji, width: size, height: size, radius: radius, tint: tint)
    }

    init(fileName: String?, assetName: String?, base64: String? = nil, cacheKey: String? = nil,
         emoji: String, width: CGFloat?, height: CGFloat, radius: CGFloat = 10, tint: Color = CKColor.aquaSoft) {
        self.fileName = fileName
        self.assetName = assetName
        self.base64 = base64
        self.cacheKey = cacheKey
        self.emoji = emoji
        self.width = width
        self.height = height
        self.radius = radius
        self.tint = tint
    }

    private var uiImage: UIImage? {
        ImageStore.shared.bestImage(fileName: fileName, base64: base64, assetName: assetName, cacheKey: cacheKey)
    }

    var body: some View {
        Color.clear
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? CGFloat.infinity : nil)
            .overlay {
                if let uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        LinearGradient(colors: [tint, CKColor.aqua], startPoint: .topLeading, endPoint: .bottomTrailing)
                        Text(emoji)
                            .font(.system(size: min(width ?? height, height) * 0.52))
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .accessibilityHidden(true)
    }
}

extension CKThumbnail {
    init(product: Product, size: CGFloat, radius: CGFloat = 10) {
        self.init(fileName: product.imageFileName, assetName: product.imageAssetName,
                  base64: product.imageData, cacheKey: "p-\(product.id)-\(product.updatedAt.timeIntervalSince1970)",
                  emoji: product.emoji, size: size, radius: radius, tint: product.category.badgeBackground)
    }

    init(material: Material, size: CGFloat, radius: CGFloat = 10) {
        self.init(fileName: material.imageFileName, assetName: material.imageAssetName,
                  base64: material.imageData, cacheKey: "m-\(material.id)-\(material.updatedAt.timeIntervalSince1970)",
                  emoji: material.emoji, size: size, radius: radius, tint: material.category.badgeBackground)
    }

    init(record: ProductionRecord, size: CGFloat, radius: CGFloat = 10) {
        self.init(fileName: record.imageFileName, assetName: record.imageAssetName,
                  base64: record.imageData, cacheKey: "r-\(record.id)",
                  emoji: record.productEmoji, size: size, radius: radius, tint: record.productCategory.badgeBackground)
    }

    init(sale: SaleRecord, size: CGFloat, radius: CGFloat = 10) {
        self.init(fileName: sale.imageFileName, assetName: sale.imageAssetName,
                  base64: sale.imageData, cacheKey: "s-\(sale.id)",
                  emoji: sale.productEmoji, size: size, radius: radius, tint: sale.productCategory.badgeBackground)
    }
}

/// Small image used next to ingredient names (asset → emoji on soft circle).
struct CKIngredientIcon: View {
    let emoji: String
    var assetName: String? = nil
    var fileName: String? = nil
    var base64: String? = nil
    var cacheKey: String? = nil
    var size: CGFloat = 30

    var body: some View {
        CKThumbnail(fileName: fileName, assetName: assetName, base64: base64, cacheKey: cacheKey,
                    emoji: emoji, size: size, radius: size * 0.3, tint: Color.white)
    }
}

// MARK: - Step indicator

struct CKStepIndicator: View {
    let current: Int
    var titles: [String] = ["Product Details", "Ingredients", "Profit Calculator", "Review Product"]
    var onSelect: ((Int) -> Void)? = nil

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                ForEach(Array(titles.indices), id: \.self) { index in
                    let step = index + 1
                    circle(step)
                    if step < titles.count {
                        Rectangle()
                            .fill(step < current ? CKColor.primary : CKColor.border)
                            .frame(height: 2)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .padding(.horizontal, 22)

            HStack(spacing: 0) {
                ForEach(Array(titles.enumerated()), id: \.offset) { index, title in
                    Text(title)
                        .font(.system(size: 10, weight: index + 1 == current ? .semibold : .regular))
                        .foregroundStyle(CKColor.navy)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current) of \(titles.count): \(titles[max(0, min(current - 1, titles.count - 1))])")
    }

    @ViewBuilder
    private func circle(_ step: Int) -> some View {
        let done = step < current
        let active = step == current
        Button {
            onSelect?(step)
        } label: {
            ZStack {
                Circle()
                    .fill(done || active ? CKColor.primary : CKColor.pill)
                Circle()
                    .stroke(done || active ? CKColor.primary : CKColor.border, lineWidth: 1)
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(step)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(active ? Color.white : CKColor.navy)
                }
            }
            .frame(width: 30, height: 30)
            .shadow(color: active ? CKColor.primary.opacity(0.25) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(onSelect == nil || !done)
    }
}

// MARK: - Cards & rows

struct CKSectionCard<Trailing: View, Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder var content: () -> Content

    init(title: String, subtitle: String? = nil,
         @ViewBuilder trailing: @escaping () -> Trailing,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(CKColor.navy)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(CKColor.textSecondary)
                    }
                }
                Spacer()
                trailing()
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ckCard(padding: 12)
    }
}

extension CKSectionCard where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.init(title: title, subtitle: subtitle, trailing: { EmptyView() }, content: content)
    }
}

/// "Label ............ value" row with an optional divider.
struct CKInfoRow: View {
    let label: String
    let value: String
    var highlight = false
    var showDivider = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(CKColor.navy)
                Spacer(minLength: 8)
                Text(value)
                    .font(.system(size: highlight ? 15 : 13, weight: .bold))
                    .foregroundStyle(highlight ? CKColor.primary : CKColor.navy)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 7)
            if showDivider {
                Divider().overlay(CKColor.border)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Aqua results panel ("Total Cost ₱170.00 ...").
struct CKSummaryPanel: View {
    let summary: CostSummary
    var large = false
    var totalLabel = "Total Cost"
    /// Shows the ingredients / labor split and the profit % above the totals.
    var showsBreakdown = true

    var body: some View {
        VStack(spacing: large ? 8 : 6) {
            if showsBreakdown {
                smallRow("Ingredients", Fmt.peso(summary.ingredientCost))
                if summary.overheadCost > 0 {
                    smallRow("Labor & Other Costs", Fmt.peso(summary.overheadCost))
                }
                Divider().overlay(CKColor.aquaStrong)
            }
            row(totalLabel, Fmt.peso(summary.totalCost))
            row("Cost per Piece", Fmt.peso(summary.costPerPiece))
            row("Suggested SRP", Fmt.peso(summary.suggestedSRP))
            row("Estimated Profit", Fmt.peso(summary.estimatedProfit))
            if showsBreakdown && summary.desiredProfitPercent > 0 {
                smallRow("Profit Margin", Fmt.percent(summary.desiredProfitPercent.rounded()))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, large ? 14 : 10)
        .background(RoundedRectangle(cornerRadius: CKMetrics.cardRadius, style: .continuous).fill(CKColor.aqua))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: large ? 14 : 13))
                .foregroundStyle(CKColor.navy)
            Spacer()
            Text(value)
                .font(.system(size: large ? 22 : 16, weight: .bold))
                .foregroundStyle(CKColor.primary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
    }

    private func smallRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(CKColor.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CKColor.navy)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

struct CKEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(CKColor.primary)
                .frame(width: 64, height: 64)
                .background(Circle().fill(CKColor.aqua))
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(CKColor.navy)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(CKColor.textSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus")
                }
                .buttonStyle(.ckCompact)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 24)
    }
}

// MARK: - Modal

/// Dimmed success dialog ("Product Saved Successfully!").
struct CKSuccessModal: View {
    let title: String
    let highlight: String
    let message: String
    let primaryTitle: String
    let secondaryTitle: String
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.38)
                .ignoresSafeArea()
                .transition(.opacity)

            VStack(spacing: 14) {
                ZStack {
                    Circle().fill(CKColor.aqua)
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(CKColor.primary)
                        .scaleEffect(appeared ? 1 : 0.4)
                }
                .frame(width: 76, height: 76)
                .padding(.top, 6)

                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(CKColor.navy)
                    .multilineTextAlignment(.center)

                VStack(spacing: 2) {
                    Text(highlight)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CKColor.navy)
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundStyle(CKColor.textSecondary)
                }
                .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    Button(primaryTitle, action: onPrimary)
                        .buttonStyle(.ckPrimary(height: 44, fontSize: 14))
                    Button(secondaryTitle, action: onSecondary)
                        .buttonStyle(CKOutlineButtonStyle(height: 44, fontSize: 14))
                }
                .padding(.top, 4)
            }
            .padding(18)
            .frame(maxWidth: 290)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white))
            .shadow(color: .black.opacity(0.15), radius: 20, y: 8)
            .padding(.horizontal, 40)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.05)) { appeared = true }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        .accessibilityAddTraits(.isModal)
    }
}

// MARK: - Swipe to delete

extension View {
    /// Native swipe-left "Delete" action styled in CheKita red. The row is NOT removed here;
    /// `onRequest` should present a confirmation alert first.
    func ckSwipeToDelete(_ onRequest: @escaping () -> Void) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                onRequest()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(CKColor.danger)
        }
    }

    /// "Delete X?" confirmation alert with Cancel / Delete.
    func ckDeleteAlert<Item>(_ kind: String, item: Binding<Item?>, name: @escaping (Item) -> String,
                             onDelete: @escaping (Item) -> Void) -> some View {
        let isPresented = Binding<Bool>(
            get: { item.wrappedValue != nil },
            set: { if !$0 { item.wrappedValue = nil } }
        )
        return alert("Delete \(kind)?", isPresented: isPresented, presenting: item.wrappedValue) { value in
            Button("Cancel", role: .cancel) { item.wrappedValue = nil }
            Button("Delete", role: .destructive) {
                onDelete(value)
                item.wrappedValue = nil
            }
        } message: { value in
            Text("Are you sure you want to delete \(name(value))?")
        }
    }
}

// MARK: - Photo picking

/// Wraps PhotosPicker and loads the chosen image into `data`.
struct CKPhotoPicker<PickerLabel: View>: View {
    @Binding var data: Data?
    @ViewBuilder var label: () -> PickerLabel
    @State private var item: PhotosPickerItem? = nil

    var body: some View {
        PhotosPicker(selection: $item, matching: .images, photoLibrary: .shared()) {
            label()
        }
        .buttonStyle(.plain)
        .onChange(of: item) { _, newItem in
            guard let newItem else { return }
            Task {
                if let loaded = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run { data = loaded }
                }
                await MainActor.run { item = nil }
            }
        }
    }
}

// MARK: - Share sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// Identifiable wrapper so plain values can drive `.sheet(item:)`.
struct IdentifiedValue<Value: Hashable>: Identifiable {
    let value: Value
    var id: Value { value }
}

/// Bottom action bar with a white background and top hairline.
struct CKBottomBar<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(.horizontal, CKMetrics.hPadding)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(
                Color.white
                    .shadow(color: CKColor.navy.opacity(0.06), radius: 6, y: -2)
                    .ignoresSafeArea(edges: .bottom)
            )
    }
}
