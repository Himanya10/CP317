//
//  MediVisionPDFGenerator.swift
//  CP317-Application
//

import Foundation
import UIKit
import PDFKit

class MediVisionPDFGenerator {
    
    func generatePDF(
        schedule: DailySchedule,
        medications: [Medication],
        warnings: [MedicationWarning]?,
        scheduleName: String,
        labels: UILabels?,
        fileName: String
    ) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "MediVision",
            kCGPDFContextAuthor: "Health Wellness App",
            kCGPDFContextTitle: "Medication Schedule - \(scheduleName)"
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
            
            // Helper function to check page break
            func checkPageBreak(requiredSpace: CGFloat) {
                if yPosition + requiredSpace > pageHeight - margin {
                    context.beginPage()
                    yPosition = margin
                }
            }
            
            // Title
            let titleText = labels?.reportTitle ?? "Medication Schedule"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor.label
            ]
            titleText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: titleAttributes)
            yPosition += 40
            
            // Schedule Name
            let nameAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.label
            ]
            scheduleName.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: nameAttributes)
            yPosition += 30
            
            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateText = "\(labels?.dateLabel ?? "Date"): \(dateFormatter.string(from: Date()))"
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ]
            dateText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateAttributes)
            yPosition += 40
            
            // Warnings Section
            if let warnings = warnings, !warnings.isEmpty {
                checkPageBreak(requiredSpace: 150)
                
                let warningTitleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: UIColor.systemRed
                ]
                let warningTitle = labels?.clinicalAlertsTitle ?? "Clinical Alerts"
                warningTitle.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: warningTitleAttributes)
                yPosition += 30
                
                let warningAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12),
                    .foregroundColor: UIColor.label
                ]
                
                for warning in warnings {
                    checkPageBreak(requiredSpace: 60)
                    
                    let bullet = "• "
                    bullet.draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: warningAttributes)
                    
                    let maxWidth = pageWidth - (margin * 2) - 30
                    let warningRect = CGRect(x: margin + 30, y: yPosition, width: maxWidth, height: 200)
                    warning.description.draw(in: warningRect, withAttributes: warningAttributes)
                    
                    let textHeight = warning.description.boundingRect(
                        with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                        options: .usesLineFragmentOrigin,
                        attributes: warningAttributes,
                        context: nil
                    ).height
                    
                    yPosition += textHeight + 15
                }
                
                yPosition += 20
            }
            
            // Time Slots
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
            
            for slot in TimeSlot.allCases {
                checkPageBreak(requiredSpace: 100)
                
                // Time slot header
                let slotName = getSlotName(slot, labels: labels)
                let slotHeader = "\(slotName) (\(slot.time))"
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
                let medIds = schedule[slot]
                
                if medIds.isEmpty {
                    "No medications".draw(
                        at: CGPoint(x: margin + 30, y: yPosition),
                        withAttributes: medDetailsAttributes
                    )
                    yPosition += 20
                } else {
                    for medId in medIds {
                        guard let med = medications.first(where: { $0.id == medId }) else { continue }
                        
                        checkPageBreak(requiredSpace: 80)
                        
                        // Bullet point
                        "• ".draw(at: CGPoint(x: margin + 10, y: yPosition), withAttributes: medNameAttributes)
                        
                        // Medication name
                        med.name.draw(at: CGPoint(x: margin + 30, y: yPosition), withAttributes: medNameAttributes)
                        yPosition += 20
                        
                        // Dosage
                        let dosageText = "\(labels?.tableMedication ?? "Dosage"): \(med.dosage)"
                        dosageText.draw(at: CGPoint(x: margin + 30, y: yPosition), withAttributes: medDetailsAttributes)
                        yPosition += 18
                        
                        // Instructions
                        if !med.instructions.isEmpty {
                            let instructionsText = "\(labels?.tableInstructions ?? "Instructions"): \(med.instructions)"
                            let maxWidth = pageWidth - (margin * 2) - 30
                            let instructionsRect = CGRect(x: margin + 30, y: yPosition, width: maxWidth, height: 100)
                            instructionsText.draw(in: instructionsRect, withAttributes: medDetailsAttributes)
                            
                            let textHeight = instructionsText.boundingRect(
                                with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                                options: .usesLineFragmentOrigin,
                                attributes: medDetailsAttributes,
                                context: nil
                            ).height
                            
                            yPosition += textHeight + 5
                        }
                        
                        // Category
                        let categoryLabel = med.category == .prescription
                            ? (labels?.labelRx ?? "Rx")
                            : (labels?.labelOTC ?? "OTC")
                        let categoryText = "\(labels?.tableType ?? "Type"): \(categoryLabel)"
                        categoryText.draw(at: CGPoint(x: margin + 30, y: yPosition), withAttributes: medDetailsAttributes)
                        yPosition += 18
                        
                        yPosition += 10 // Space between medications
                    }
                }
                
                yPosition += 20 // Space between time slots
            }
            
            // Disclaimer
            checkPageBreak(requiredSpace: 80)
            yPosition += 20
            
            let disclaimerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 10),
                .foregroundColor: UIColor.secondaryLabel
            ]
            
            let disclaimer = labels?.disclaimer ?? "This schedule was generated by AI. Always consult your healthcare provider before making changes to your medications."
            let maxWidth = pageWidth - (margin * 2)
            let disclaimerRect = CGRect(x: margin, y: yPosition, width: maxWidth, height: 100)
            disclaimer.draw(in: disclaimerRect, withAttributes: disclaimerAttributes)
            
            let disclaimerHeight = disclaimer.boundingRect(
                with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                options: .usesLineFragmentOrigin,
                attributes: disclaimerAttributes,
                context: nil
            ).height
            
            yPosition += disclaimerHeight + 30
            
            // Signature line
            checkPageBreak(requiredSpace: 60)
            
            let signatureLine = UIBezierPath()
            signatureLine.move(to: CGPoint(x: margin, y: yPosition + 20))
            signatureLine.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition + 20))
            UIColor.separator.setStroke()
            signatureLine.lineWidth = 1
            signatureLine.stroke()
            
            let signatureText = labels?.signature ?? "Patient/Caregiver Signature"
            signatureText.draw(
                at: CGPoint(x: margin, y: yPosition + 25),
                withAttributes: dateAttributes
            )
        }
        
        // Save to temporary directory
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Error saving PDF: \(error)")
            return nil
        }
    }
    
    private func getSlotName(_ slot: TimeSlot, labels: UILabels?) -> String {
        guard let labels = labels else { return slot.displayName }
        
        switch slot {
        case .morning: return labels.morning
        case .noon: return labels.noon
        case .evening: return labels.evening
        case .bedtime: return labels.night
        }
    }
}
