import SwiftUI

struct ProductDetailsStepView: View {
    @ObservedObject var vm: CreateProductViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                CKFieldLabel("Product Name", required: true)
                CKTextField(icon: "shippingbox", placeholder: "e.g. Chocolate Chip Cookie", text: $vm.name,
                            capitalization: .words, errorMessage: vm.nameError)
            }

            VStack(alignment: .leading, spacing: 6) {
                CKFieldLabel("Description (Optional)")
                CKTextArea(icon: "doc.text", placeholder: "Short description of your product", text: $vm.productDescription)
            }

            VStack(alignment: .leading, spacing: 6) {
                CKFieldLabel("Product Image")
                imagePicker
            }

            VStack(alignment: .leading, spacing: 6) {
                CKFieldLabel("Category", required: true)
                CKPickerField(icon: "square.grid.2x2", placeholder: "Select category",
                              options: ProductCategory.allCases, selection: $vm.category,
                              title: { $0.rawValue }, errorMessage: vm.categoryError)
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var imagePicker: some View {
        if let image = vm.previewImage {
            HStack(spacing: 14) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                CKPhotoPicker(data: $vm.newImageData) {
                    Label("Change Image", systemImage: "photo")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CKColor.primary)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(CKColor.primary, lineWidth: 1))
                }
                Spacer()
                Button {
                    withAnimation { vm.removeImage() }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(CKColor.navy)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(CKColor.pill))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove image")
            }
            .padding(10)
            .overlay(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius).stroke(CKColor.fieldBorder, lineWidth: 1))
        } else {
            CKPhotoPicker(data: $vm.newImageData) {
                VStack(spacing: 6) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 26))
                        .foregroundStyle(CKColor.primary)
                    Text("Add Product Image")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CKColor.primary)
                    Text("Optional • JPG or PNG from your photos")
                        .font(.system(size: 11))
                        .foregroundStyle(CKColor.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .background(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius).fill(CKColor.aquaSoft))
                .overlay(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius)
                    .stroke(CKColor.primary.opacity(0.5), style: StrokeStyle(lineWidth: 1.2, dash: [6, 4])))
            }
        }
    }
}
