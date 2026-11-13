import SwiftUI

/// 4-step Create / Edit Product flow: Product Details → Ingredients → Profit Calculator → Review Product.
struct CreateProductView: View {
    @StateObject private var vm: CreateProductViewModel
    @EnvironmentObject private var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @State private var showDiscardAlert = false

    init(store: DataStore, editingProductID: UUID?) {
        _vm = StateObject(wrappedValue: CreateProductViewModel(store: store, editingProductID: editingProductID))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                CKNavHeader(title: vm.title, subtitle: vm.subtitle, onBack: handleBack)

                CKStepIndicator(current: vm.step.rawValue, onSelect: { step in
                    if let target = CreateProductViewModel.Step(rawValue: step), target.rawValue < vm.step.rawValue {
                        Keyboard.dismiss()
                        vm.step = target
                    }
                })
                .padding(.horizontal, CKMetrics.hPadding)
                .padding(.top, 4)
                .padding(.bottom, 10)

                ScrollViewReader { proxy in
                    ScrollView {
                        Color.clear.frame(height: 0).id("top")
                        Group {
                            switch vm.step {
                            case .details: ProductDetailsStepView(vm: vm)
                            case .ingredients: IngredientsStepView(vm: vm)
                            case .profit: ProfitCalculatorStepView(vm: vm)
                            case .review: ReviewProductStepView(vm: vm)
                            }
                        }
                        .padding(.horizontal, CKMetrics.hPadding)
                        .padding(.bottom, 20)
                        .transition(.opacity)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: vm.step) { _, _ in
                        withAnimation { proxy.scrollTo("top", anchor: .top) }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
            }
            .ckScreenBackground(waveHeight: 110)
            .animation(.easeInOut(duration: 0.22), value: vm.step)

            if vm.showSuccess {
                successModal
                    .zIndex(2)
            }
        }
        .alert(vm.isEditing ? "Discard changes?" : "Discard this product?", isPresented: $showDiscardAlert) {
            Button("Keep Editing", role: .cancel) {}
            Button("Discard", role: .destructive) { dismiss() }
        } message: {
            Text("Your unsaved information will be lost.")
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        CKBottomBar {
            HStack(spacing: 10) {
                if vm.step != .details {
                    Button {
                        _ = vm.goBack()
                    } label: {
                        Label("Back", systemImage: "arrow.left")
                    }
                    .buttonStyle(.ckOutline)
                }
                if vm.step == .review {
                    Button {
                        vm.save()
                    } label: {
                        Label(vm.isEditing ? "Save Changes" : "Save Product", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(.ckPrimary)
                } else {
                    Button {
                        vm.goNext()
                    } label: {
                        CKArrowLabel(title: "Next")
                    }
                    .buttonStyle(.ckPrimary)
                }
            }
        }
    }

    private var successModal: some View {
        CKSuccessModal(
            title: vm.isEditing ? "Product Updated Successfully!" : "Product Saved Successfully!",
            highlight: vm.savedProductName,
            message: vm.isEditing ? "has been updated." : "has been added to your products.",
            primaryTitle: "View Products",
            secondaryTitle: vm.isEditing ? "Back to Product" : "Add Another Product",
            onPrimary: {
                dismiss()
                router.showProductList()
            },
            onSecondary: {
                if vm.isEditing {
                    dismiss()
                } else {
                    vm.resetForNewProduct()
                }
            }
        )
    }

    private func handleBack() {
        if vm.goBack() { return }
        if vm.hasUnsavedInput {
            showDiscardAlert = true
        } else {
            dismiss()
        }
    }
}
