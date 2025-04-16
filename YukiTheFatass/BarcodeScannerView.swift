//
//  BarcodeScannerView.swift
//  YukiTheFatass
//
//  Created by Doris Wei on 4/14/25.
//

import SwiftUI
import VisionKit
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .accurate,
            isHighlightingEnabled: true
        )

        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(scannerView: self)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var scannerView: BarcodeScannerView

        init(scannerView: BarcodeScannerView) {
            self.scannerView = scannerView
        }

        func dataScanner(_ scanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .barcode(let barcode):
                if let code = barcode.payloadStringValue {
                    scannerView.scannedCode = code
                    scanner.stopScanning()
                }
            default:
                break
            }
        }
    }
}

