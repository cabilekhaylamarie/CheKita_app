import SwiftUI

struct CKFieldLabel: View {
    let title: String
    var required = false

    init(_ title: String, required: Bool = false) {
        self.title = title
        self.required = required
    }

    var body: some View {
        (Text(title).foregroundColor(CKColor.navy)
         + Text(required ? " *" : "").foregroundColor(CKColor.danger))
            .font(.system(size: 14, weight: .semibold))
    }
}

struct CKErrorText: View {
    let message: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
            Text(message)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 12))
        .foregroundStyle(CKColor.danger)
        .transition(.opacity)
    }
}

struct CKTextField: View {
    let icon: String?
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool
    var keyboard: UIKeyboardType
    var contentType: UITextContentType?
    var capitalization: TextInputAutocapitalization
    var errorMessage: String?
    var height: CGFloat

    @State private var isRevealed = false
    @FocusState private var isFocused: Bool

    init(icon: String? = nil,
         placeholder: String,
         text: Binding<String>,
         isSecure: Bool = false,
         keyboard: UIKeyboardType = .default,
         contentType: UITextContentType? = nil,
         capitalization: TextInputAutocapitalization = .sentences,
         errorMessage: String? = nil,
         height: CGFloat = CKMetrics.fieldHeight) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
        self.keyboard = keyboard
        self.contentType = contentType
        self.capitalization = capitalization
        self.errorMessage = errorMessage
        self.height = height
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(CKColor.textSecondary)
                        .frame(width: 22)
                }
                Group {
                    if isSecure && !isRevealed {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                    }
                }
                .font(.system(size: 15))
                .foregroundStyle(CKColor.navy)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .textInputAutocapitalization(isSecure ? .never : capitalization)
                .autocorrectionDisabled(isSecure || keyboard == .emailAddress)
                .focused($isFocused)

                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .font(.system(size: 16))
                            .foregroundStyle(CKColor.textSecondary)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: height)
            .background(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius, style: .continuous).fill(Color.white))
            .overlay(
                RoundedRectangle(cornerRadius: CKMetrics.fieldRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: isFocused ? 1.4 : 1)
            )
            .contentShape(Rectangle())
            .onTapGesture { isFocused = true }

            if let errorMessage {
                CKErrorText(message: errorMessage)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return CKColor.danger }
        return isFocused ? CKColor.primary : CKColor.fieldBorder
    }
}

struct CKTextArea: View {
    let icon: String?
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 64

    init(icon: String? = nil, placeholder: String, text: Binding<String>, minHeight: CGFloat = 64) {
        self.icon = icon
        self.placeholder = placeholder
        self._text = text
        self.minHeight = minHeight
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(CKColor.textSecondary)
                    .frame(width: 22)
                    .padding(.top, 2)
            }
            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(size: 14))
                .foregroundStyle(CKColor.navy)
                .lineLimit(2...6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius, style: .continuous).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius, style: .continuous).stroke(CKColor.fieldBorder, lineWidth: 1))
    }
}

/// Field styled like a dropdown that opens a native Menu.
struct CKPickerField<Option: Hashable>: View {
    let icon: String?
    let placeholder: String
    let options: [Option]
    @Binding var selection: Option?
    let title: (Option) -> String
    var errorMessage: String?

    init(icon: String? = nil, placeholder: String, options: [Option], selection: Binding<Option?>,
         title: @escaping (Option) -> String, errorMessage: String? = nil) {
        self.icon = icon
        self.placeholder = placeholder
        self.options = options
        self._selection = selection
        self.title = title
        self.errorMessage = errorMessage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        if selection == option {
                            Label(title(option), systemImage: "checkmark")
                        } else {
                            Text(title(option))
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 16))
                            .foregroundStyle(CKColor.textSecondary)
                            .frame(width: 22)
                    }
                    Text(selection.map(title) ?? placeholder)
                        .font(.system(size: 15))
                        .foregroundStyle(selection == nil ? CKColor.textTertiary : CKColor.navy)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CKColor.navy)
                }
                .padding(.horizontal, 14)
                .frame(height: CKMetrics.fieldHeight)
                .background(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius, style: .continuous).fill(Color.white))
                .overlay(
                    RoundedRectangle(cornerRadius: CKMetrics.fieldRadius, style: .continuous)
                        .stroke(errorMessage == nil ? CKColor.fieldBorder : CKColor.danger, lineWidth: 1)
                )
                .contentShape(Rectangle())
            }
            if let errorMessage {
                CKErrorText(message: errorMessage)
            }
        }
    }
}

/// Numeric input box with a trailing unit segment ("20 | pcs").
struct CKSuffixField<Suffix: View>: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType
    var hasError: Bool
    var fieldWidth: CGFloat
    @ViewBuilder var suffix: () -> Suffix

    init(placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .decimalPad, hasError: Bool = false,
         fieldWidth: CGFloat = 58, @ViewBuilder suffix: @escaping () -> Suffix) {
        self.placeholder = placeholder
        self._text = text
        self.keyboard = keyboard
        self.hasError = hasError
        self.fieldWidth = fieldWidth
        self.suffix = suffix
    }

    var body: some View {
        HStack(spacing: 0) {
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .font(.system(size: 14))
                .foregroundStyle(CKColor.navy)
                .padding(.horizontal, 10)
                .frame(width: fieldWidth)
            Rectangle().fill(CKColor.border).frame(width: 1)
            suffix()
                .frame(minWidth: 44)
        }
        .frame(height: 38)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(hasError ? CKColor.danger : CKColor.fieldBorder, lineWidth: 1)
        )
    }
}

struct CKSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(CKColor.navy)
            TextField(placeholder, text: $text)
                .font(.system(size: 14))
                .foregroundStyle(CKColor.navy)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(.search)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(CKColor.textTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius, style: .continuous).fill(CKColor.fieldFill))
        .overlay(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius, style: .continuous).stroke(CKColor.border, lineWidth: 1))
    }
}

/// Square filter button next to search fields; opens a sort menu.
struct CKFilterMenu<Content: View>: View {
    var isActive: Bool
    @ViewBuilder var content: () -> Content

    init(isActive: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.isActive = isActive
        self.content = content
    }

    var body: some View {
        Menu {
            content()
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isActive ? Color.white : CKColor.navy)
                .frame(width: 42, height: 42)
                .background(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius, style: .continuous)
                    .fill(isActive ? CKColor.primary : CKColor.fieldFill))
                .overlay(RoundedRectangle(cornerRadius: CKMetrics.fieldRadius, style: .continuous)
                    .stroke(CKColor.border, lineWidth: 1))
        }
        .accessibilityLabel("Sort and filter")
    }
}

struct CKCheckbox: View {
    let isOn: Bool
    var size: CGFloat = 26

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isOn ? CKColor.primary : Color.white)
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(isOn ? CKColor.primary : CKColor.fieldBorder, lineWidth: 1.4)
            if isOn {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
    }
}
