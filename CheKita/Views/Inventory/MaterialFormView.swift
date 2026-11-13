import SwiftUI

/// Add / Edit Material. Reads the store from the environment and builds its view model once.
struct MaterialFormView: View {
    let materialID: UUID?
    @EnvironmentObject private var store: DataStore

    var body: some View {
        MaterialFormContent(store: store, materialID: materialID)
    }
}

private struct MaterialFormContent: View {
    @StateObject private var vm: MaterialFormViewModel
    @Environment(\.dismiss) private var dismiss

    init(store: DataStore, materialID: UUID?) {
        _vm = StateObject(wrappedValue: MaterialFormViewModel(store: store, editingID: materialID))
    }

    var body: some View {
        VStack(spacing: 0) {
            CKNavHeader(title: vm.title,
                        subtitle: vm.isEditing ? "Update the details of your material." : "Fill in the details of your material.",
                        onBack: { dismiss() })

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    photoRow

                    VStack(alignment: .leading, spacing: 6) {
                        CKFieldLabel("Material Name", required: true)
                        CKTextField(icon: "shippingbox", placeholder: "e.g. All-Purpose Flour", text: $vm.name,
                                    capitalization: .words, errorMessage: vm.nameError)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        CKFieldLabel("Category", required: true)
                        CKPickerField(icon: "square.grid.2x2", placeholder: "Select category",
                                      options: MaterialCategory.allCases, selection: $vm.category,
                                      title: { $0.rawValue }, errorMessage: vm.categoryError)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        CKFieldLabel("Unit", required: true)
                        CKPickerField(icon: "scalemass", placeholder: "Select unit",
                                      options: MeasurementUnit.allCases, selection: $vm.unit,
                                      title: { $0.displayName }, errorMessage: vm.unitError)
                    }

                    costField

                    VStack(alignment: .leading, spacing: 6) {
                        CKFieldLabel("Current Stock", required: true)
                        CKTextField(icon: "archivebox", placeholder: "e.g. 2", text: $vm.stockText,
                                    keyboard: .decimalPad, errorMessage: vm.stockError)
                        if let unit = vm.unit, vm.stockError == nil {
                            Text("Measured in \(unit.displayName.lowercased()).")
                                .font(.system(size: 11))
                                .foregroundStyle(CKColor.textSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        CKFieldLabel("Notes (Optional)")
                        CKTextArea(icon: "note.text", placeholder: "Supplier, brand, storage tips…", text: $vm.notes)
                    }

                    if vm.isEditing && vm.usedInProductsCount > 0 {
                        Label("Used in \(vm.usedInProductsCount) product\(vm.usedInProductsCount == 1 ? "" : "s"). Price changes update their costs automatically.",
                              systemImage: "info.circle")
                            .font(.system(size: 12))
                            .foregroundStyle(CKColor.primary)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 10).fill(CKColor.aqua))
                    }
                }
                .padding(.horizontal, CKMetrics.hPadding)
                .padding(.top, 6)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                CKBottomBar {
                    HStack(spacing: 10) {
                        Button("Cancel") { dismiss() }
                            .buttonStyle(.ckOutline)
                        Button {
                            if vm.save() { dismiss() }
                        } label: {
                            Label("Save", systemImage: "square.and.arrow.down")
                        }
                        .buttonStyle(.ckPrimary)
                    }
                }
            }
        }
        .ckScreenBackground(waveHeight: 100)
    }

    private var photoRow: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                CKPhotoPicker(data: $vm.newImageData) {
                    Group {
                        if let image = vm.previewImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            VStack(spacing: 6) {
                                Image(systemName: "camera")
                                    .font(.system(size: 22))
                                Text("Add Photo")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(CKColor.primary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(CKColor.aquaSoft)
                        }
                    }
                    .frame(width: 96, height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(CKColor.primary.opacity(0.5), style: StrokeStyle(lineWidth: 1.2, dash: vm.previewImage == nil ? [6, 4] : [])))
                }
                .accessibilityLabel(vm.previewImage == nil ? "Add photo" : "Change photo")

                if vm.previewImage != nil {
                    Button {
                        withAnimation { vm.removeImage() }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(CKColor.navy.opacity(0.75)))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 6, y: -6)
                    .accessibilityLabel("Remove photo")
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "photo")
                    .foregroundStyle(CKColor.primary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Optional")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CKColor.navy)
                    Text("Add a photo of your material.")
                        .font(.system(size: 12))
                        .foregroundStyle(CKColor.textSecondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(CKColor.aquaSoft))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(CKColor.border, lineWidth: 1))
        }
    }

    private var costField: some View {
        VStack(alignment: .leading, spacing: 6) {
            CKFieldLabel("Cost per Unit (₱)", required: true)
            HStack(spacing: 0) {
                Text("₱")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(CKColor.textSecondary)
                    .frame(width: 40)
                Rectangle().fill(CKColor.border).frame(width: 1)
                TextField("0.00", text: $vm.costText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 15))
                    .foregroundStyle(CKColor.navy)
                    .padding(.horizontal, 12)
                Rectangle().fill(CKColor.border).frame(width: 1)
                Text("per")
                    .font(.system(size: 12))
                    .foregroundStyle(CKColor.textSecondary)
                    .padding(.leading, 10)
                TextField("1", text: $vm.costQuantityText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
                    .foregroundStyle(CKColor.navy)
                    .frame(width: 52)
                Text(vm.unit?.rawValue ?? "unit")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(CKColor.navy)
                    .padding(.trailing, 12)
            }
            .frame(height: CKMetrics.fieldHeight)
            .background(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius)
                .stroke(vm.costError == nil ? CKColor.fieldBorder : CKColor.danger, lineWidth: 1))
            if let error = vm.costError {
                CKErrorText(message: error)
            } else {
                Text("Tip: for butter bought at ₱120 per 500 g, enter 120 per 500 with unit g.")
                    .font(.system(size: 11))
                    .foregroundStyle(CKColor.textSecondary)
            }
        }
    }
}
