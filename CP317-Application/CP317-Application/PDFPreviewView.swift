//
//  PDFPreviewView.swift
//  CP317-Application
//

import SwiftUI
import PDFKit

struct PDFPreviewView: View {
    let schedule: MedicationSchedule
    @Environment(\.dismiss) var dismiss
    @State private var pdfDocument: PDFDocument?
    @State private var isGenerating = false
    @State private var showShareSheet = false
    @State private var pdfURL: URL?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let pdfDocument = pdfDocument {
                    PDFKitView(document: pdfDocument)
                } else if isGenerating {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Generating PDF...")
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Failed to generate PDF")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Medication Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if pdfDocument != nil {
                        Button(action: { showShareSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ShareSheet(items: [url])
                }
            }
        }
        .task {
            await generatePDF()
        }
    }
    
    private func generatePDF() async {
        isGenerating = true
        
        let generator = MedicationPDFGenerator()
        if let (document, url) = generator.generatePDF(for: schedule) {
            await MainActor.run {
                self.pdfDocument = document
                self.pdfURL = url
                self.isGenerating = false
            }
        } else {
            await MainActor.run {
                self.isGenerating = false
            }
        }
    }
}

// MARK: - PDFKit View Wrapper

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {}
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - PDF Generator

class MedicationPDFGenerator {
    func generatePDF(for schedule: MedicationSchedule) -> (PDFDocument, URL)? {
        let pdfMetaData = [
            kCGPDFContextCreator: "MediVision",
            kCGPDFContextAuthor: "Health Wellness App",
            kCGPDFContextTitle: "Medication Schedule"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // A4 size
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11.0 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let margin: CGFloat = 40
            var yPosition: CGFloat = margin
            
            // Title
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24),
                .foregroundColor: UIColor.label
            ]
            let title = "Daily Medication Schedule"
            title.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let dateString = "Generated on \(dateFormatter.string(from: Date()))"
            dateString.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateAttributes)
            yPosition += 40
            
            // Time slots
            let headerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.label
            ]
            let medNameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.label
            ]
            let medDetailsAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            for slot in schedule.timeSlots {
                // Check if we need a new page
                if yPosition > pageHeight - 150 {
                    context.beginPage()
                    yPosition = margin
                }
                
                // Time slot header
                let slotHeader = "\(slot.name) (\(slot.time))"
                slotHeader.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttributes)
                yPosition += 30
                
                // Draw separator line
                let linePath = UIBezierPath()
                linePath.move(to: CGPoint(x: margin, y: yPosition))
                linePath.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition))
                UIColor.separator.setStroke()
                linePath.lineWidth = 1
                linePath.stroke()
                yPosition += 15
                
                // Medications
                for med in slot.medications {
                    // Check if we need a new page
                    if yPosition > pageHeight - 100 {
                        context.beginPage()
                        yPosition = margin
                    }
                    
                    // Bullet point
                    let bullet = "•"
                    bullet.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: medNameAttributes)
                    
                    // Medication name
                    med.name.draw(at: CGPoint(x: margin + 30, y: yPosition), withAttributes: medNameAttributes)
                    yPosition += 20
                    
                    // Dosage
                    let dosageText = "Dosage: \(med.dosage)"
                    dosageText.draw(at: CGPoint(x: margin + 30, y: yPosition), withAttributes: medDetailsAttributes)
                    yPosition += 18
                    
                    // Instructions
                    if let instructions = med.instructions {
                        let instructionsText = "Instructions: \(instructions)"
                        instructionsText.draw(at: CGPoint(x: margin + 30, y: yPosition), withAttributes: medDetailsAttributes)
                        yPosition += 18
                    }
                    
                    yPosition += 10 // Space between medications
                }
                
                yPosition += 20 // Space between time slots
            }
            
            // Warnings section
            if let warnings = schedule.warnings, !warnings.isEmpty {
                // Check if we need a new page
                if yPosition > pageHeight - 200 {
                    context.beginPage()
                    yPosition = margin
                }
                
                yPosition += 20
                
                let warningTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.systemOrange
                ]
                "⚠️ Important Notes".draw(at: CGPoint(x: margin, y: yPosition), withAttributes: warningTitleAttributes)
                yPosition += 30
                
                let warningAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.label
                ]
                
                for warning in warnings {
                    if yPosition > pageHeight - 100 {
                        context.beginPage()
                        yPosition = margin
                    }
                    
                    let bullet = "•"
                    bullet.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: warningAttributes)
                    
                    let maxWidth = pageWidth - (margin * 2) - 30
                    let warningRect = CGRect(x: margin + 30, y: yPosition, width: maxWidth, height: 200)
                    warning.draw(in: warningRect, withAttributes: warningAttributes)
                    
                    let textHeight = warning.boundingRect(
                        with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                        options: .usesLineFragmentOrigin,
                        attributes: warningAttributes,
                        context: nil
                    ).height
                    
                    yPosition += textHeight + 15
                }
            }
            
            // Footer
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 10),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let footer = "Consult your healthcare provider before making any changes to your medication regimen."
            let footerY = pageHeight - margin - 20
            footer.draw(at: CGPoint(x: margin, y: footerY), withAttributes: footerAttributes)
        }
        
        // Save to temporary directory
        let fileName = "MedicationSchedule_\(Date().timeIntervalSince1970).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: url)
            if let document = PDFDocument(url: url) {
                return (document, url)
            }
        } catch {
            print("Error saving PDF: \(error)")
        }
        
        return nil
    }
}
