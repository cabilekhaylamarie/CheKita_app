import UIKit

enum PDFReportService {
    enum PDFError: LocalizedError {
        case writeFailed
        var errorDescription: String? { "The PDF couldn't be created. Please try again." }
    }

    /// Renders an A4 recipe/costing report and returns a temporary file URL for sharing or saving.
    static func makeRecipeReport(record: ProductionRecord, businessName: String, preparedBy: String) throws -> URL {
        let page = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        let margin: CGFloat = 40
        let contentWidth = page.width - margin * 2

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Recipe Report – \(record.productName)",
            kCGPDFContextCreator as String: "CheKita"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: page, format: format)

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin

            // Header
            if let logo = UIImage(named: "chekitaapp_logo") {
                logo.draw(in: CGRect(x: margin, y: y, width: 60, height: 60))
            }
            draw("Recipe Report", in: CGRect(x: margin + 72, y: y + 6, width: contentWidth - 72, height: 30),
                 font: .systemFont(ofSize: 22, weight: .bold), color: CKColor.uiNavy)
            draw("CheKita · Small Business Costing and Profit Analyzer",
                 in: CGRect(x: margin + 72, y: y + 36, width: contentWidth - 72, height: 16),
                 font: .systemFont(ofSize: 10), color: CKColor.uiSecondary)
            y += 76
            fill(CGRect(x: margin, y: y, width: contentWidth, height: 2), color: CKColor.uiPrimary)
            y += 18

            // Product block
            draw(record.productName, in: CGRect(x: margin, y: y, width: contentWidth, height: 26),
                 font: .systemFont(ofSize: 18, weight: .bold), color: CKColor.uiNavy)
            y += 30
            let info: [(String, String)] = [
                ("Category", record.productCategory.rawValue),
                ("Production Date", Fmt.longDate(record.date)),
                ("Yield", record.yieldLabel),
                ("Desired Profit", Fmt.percent(record.desiredProfitPercent)),
                ("Business", businessName.trimmed.isEmpty ? "—" : businessName),
                ("Prepared by", preparedBy)
            ]
            for (index, item) in info.enumerated() {
                let column = CGFloat(index % 2)
                let row = CGFloat(index / 2)
                let x = margin + column * (contentWidth / 2)
                let rowY = y + row * 20
                draw(item.0, in: CGRect(x: x, y: rowY, width: 100, height: 16),
                     font: .systemFont(ofSize: 10), color: CKColor.uiSecondary)
                draw(item.1, in: CGRect(x: x + 100, y: rowY, width: contentWidth / 2 - 104, height: 16),
                     font: .systemFont(ofSize: 10, weight: .semibold), color: CKColor.uiNavy)
            }
            y += CGFloat((info.count + 1) / 2) * 20 + 14

            // Table
            let columns: [(String, CGFloat, NSTextAlignment)] = [
                ("Ingredient", contentWidth * 0.42, .left),
                ("Qty", contentWidth * 0.18, .right),
                ("Unit Cost", contentWidth * 0.2, .right),
                ("Total", contentWidth * 0.2, .right)
            ]
            func drawRow(_ values: [String], at rowY: CGFloat, height: CGFloat, bold: Bool, color: UIColor) {
                var x = margin
                for (index, column) in columns.enumerated() {
                    let inset: CGFloat = 10
                    draw(values[index],
                         in: CGRect(x: x + inset, y: rowY + (height - 14) / 2, width: column.1 - inset * 2, height: 16),
                         font: .systemFont(ofSize: 10, weight: bold ? .semibold : .regular),
                         color: color, alignment: column.2)
                    x += column.1
                }
            }

            let headerHeight: CGFloat = 26
            fill(CGRect(x: margin, y: y, width: contentWidth, height: headerHeight), color: CKColor.uiAqua)
            drawRow(columns.map { $0.0 }, at: y, height: headerHeight, bold: true, color: CKColor.uiNavy)
            y += headerHeight

            let rowHeight: CGFloat = 24
            for (index, line) in record.lines.enumerated() {
                if y + rowHeight > page.height - 170 {
                    context.beginPage()
                    y = margin
                }
                if index % 2 == 1 {
                    fill(CGRect(x: margin, y: y, width: contentWidth, height: rowHeight),
                         color: UIColor(white: 0.975, alpha: 1))
                }
                drawRow(["\(line.emoji)  \(line.name)", line.quantityLabel, Fmt.unitCost(line.unitCost), Fmt.peso(line.total)],
                        at: y, height: rowHeight, bold: false, color: CKColor.uiNavy)
                y += rowHeight
            }
            fill(CGRect(x: margin, y: y, width: contentWidth, height: 1), color: CKColor.uiBorder)
            y += 8
            drawRow(["Total Ingredient Cost", "", "", Fmt.peso(record.ingredientCost)],
                    at: y, height: 20, bold: true, color: CKColor.uiNavy)
            y += 26

            // Labor and other costs
            if !record.overheadList.isEmpty {
                if y + CGFloat(record.overheadList.count + 3) * 24 > page.height - 170 {
                    context.beginPage()
                    y = margin
                }
                draw("Labor and Other Costs", in: CGRect(x: margin, y: y, width: contentWidth, height: 16),
                     font: .systemFont(ofSize: 12, weight: .bold), color: CKColor.uiNavy)
                y += 22
                fill(CGRect(x: margin, y: y, width: contentWidth, height: headerHeight), color: CKColor.uiAqua)
                drawRow(["Cost", "Basis", "Rate", "Total"], at: y, height: headerHeight, bold: true, color: CKColor.uiNavy)
                y += headerHeight
                for (index, line) in record.overheadList.enumerated() {
                    if index % 2 == 1 {
                        fill(CGRect(x: margin, y: y, width: contentWidth, height: rowHeight),
                             color: UIColor(white: 0.975, alpha: 1))
                    }
                    drawRow([line.name, line.basis.rawValue, Fmt.peso(line.amount), Fmt.peso(line.total)],
                            at: y, height: rowHeight, bold: false, color: CKColor.uiNavy)
                    y += rowHeight
                }
                fill(CGRect(x: margin, y: y, width: contentWidth, height: 1), color: CKColor.uiBorder)
                y += 8
                drawRow(["Total Labor and Other Costs", "", "", Fmt.peso(record.overheadCost)],
                        at: y, height: 20, bold: true, color: CKColor.uiNavy)
                y += 26
            }

            // Summary
            if y + 130 > page.height - margin {
                context.beginPage()
                y = margin
            }
            let summaryRect = CGRect(x: margin, y: y, width: contentWidth, height: 116)
            let path = UIBezierPath(roundedRect: summaryRect, cornerRadius: 10)
            CKColor.uiAqua.setFill()
            path.fill()
            let summary: [(String, String)] = [
                ("Total Cost (ingredients + other costs)", Fmt.peso(record.totalCost)),
                ("Cost per Piece", Fmt.peso(record.costPerPiece)),
                ("Suggested SRP", Fmt.peso(record.suggestedSRP)),
                ("Estimated Profit", Fmt.peso(record.estimatedProfit))
            ]
            for (index, item) in summary.enumerated() {
                let rowY = y + 12 + CGFloat(index) * 24
                draw(item.0, in: CGRect(x: margin + 16, y: rowY + 3, width: 200, height: 18),
                     font: .systemFont(ofSize: 12), color: CKColor.uiNavy)
                draw(item.1, in: CGRect(x: margin + contentWidth / 2, y: rowY, width: contentWidth / 2 - 16, height: 22),
                     font: .systemFont(ofSize: 16, weight: .bold), color: CKColor.uiPrimary, alignment: .right)
            }
            y += 132

            if !record.notes.isEmpty {
                draw("Notes", in: CGRect(x: margin, y: y, width: contentWidth, height: 16),
                     font: .systemFont(ofSize: 11, weight: .semibold), color: CKColor.uiNavy)
                draw(record.notes, in: CGRect(x: margin, y: y + 18, width: contentWidth, height: 60),
                     font: .systemFont(ofSize: 10), color: CKColor.uiSecondary)
            }

            draw("Generated by CheKita on \(Fmt.longDate(Date())). Costs are based on ingredient prices at the time of production.",
                 in: CGRect(x: margin, y: page.height - margin - 14, width: contentWidth, height: 14),
                 font: .systemFont(ofSize: 8), color: CKColor.uiSecondary, alignment: .center)
        }

        let safeName = record.productName
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("CheKita-Recipe-Report-\(safeName)-\(Fmt.fileDate(record.date)).pdf")
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            throw PDFError.writeFailed
        }
        return url
    }

    private static func draw(_ text: String, in rect: CGRect, font: UIFont, color: UIColor,
                             alignment: NSTextAlignment = .left) {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        style.lineBreakMode = .byTruncatingTail
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: style]
        (text as NSString).draw(in: rect, withAttributes: attributes)
    }

    private static func fill(_ rect: CGRect, color: UIColor) {
        color.setFill()
        UIRectFill(rect)
    }
}
