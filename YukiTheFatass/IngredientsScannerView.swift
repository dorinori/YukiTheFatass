import SwiftUI
import AVFoundation
import Vision

// MARK: - Main Scanner View
struct IngredientsScannerView: View {
    @Binding var foundIngredients: String
    @Environment(\.presentationMode) var presentationMode
    @State private var isScanning = true // ← NEW
    
    var body: some View {
        ZStack {
            CameraTextView(foundText: $foundIngredients, isScanning: $isScanning)
            
            ScannerOverlayView()
            
            VStack {
                HStack {
                    Spacer()
                    CloseButton()
                }
                Spacer()
                ScanButton() // ← NEW
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func ScanButton() -> some View {
        Button(action: {
            isScanning.toggle()
        }) {
            Text(isScanning ? "Pause Scan" : "Resume Scan")
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
        }
        .padding(.bottom, 40)
    }
    
    
    // MARK: - Subviews
    private func ScannerOverlayView() -> some View {
        Rectangle()
            .stroke(Color.green, lineWidth: 2)
            .frame(width: 300, height: 200)
            .overlay(
                Text("Point at ingredients list")
                    .foregroundColor(.white)
                    .padding(5)
                    .background(Color.black.opacity(0.7))
                    .offset(y: 110)
            )
    }
    
    private func CloseButton() -> some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "xmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.white)
                .padding(20)
        }
    }
}

// MARK: - Camera + Text Recognition
struct CameraTextView: UIViewControllerRepresentable {
    @Binding var foundText: String
    @Binding var isScanning: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> CameraTextViewController {
        let controller = CameraTextViewController(foundText: $foundText, isScanning: $isScanning)
        context.coordinator.controller = controller
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraTextViewController, context: Context) {
        if isScanning {
            uiViewController.startSession()
        } else {
            uiViewController.stopSession()
        }
    }

    class Coordinator {
        var parent: CameraTextView
        weak var controller: CameraTextViewController?

        init(_ parent: CameraTextView) {
            self.parent = parent
        }
    }
}


class CameraTextViewController: UIViewController {
    @Binding var foundText: String
    @Binding var isScanning: Bool
    private let captureSession = AVCaptureSession()
    private let textRecognizer = TextRecognizer()
    
    init(foundText: Binding<String>, isScanning: Binding<Bool>) {
        self._foundText = foundText
        self._isScanning = isScanning
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }
    
    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        captureSession.addInput(input)
        captureSession.addOutput(output)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func startSession() {
        if !captureSession.isRunning {
            captureSession.startRunning()
        }
    }

    func stopSession() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

}

// MARK: - Text Recognition
extension CameraTextViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isScanning,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        textRecognizer.recognizeText(using: requestHandler) { text in
            DispatchQueue.main.async {
                self.foundText = self.cleanDetectedText(text)
            }
        }
    }


    
    private func cleanDetectedText(_ text: String) -> String {
        let prefixes = ["ingredients", "contains", "ingrédients"]
        var cleaned = text.lowercased()
        
        // Extract text after ingredients header
        for prefix in prefixes {
            if let range = cleaned.range(of: prefix) {
                cleaned = String(cleaned[range.upperBound...])
                break
            }
        }
        
        // Remove common noise
        return cleaned
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "•", with: ",")
            .capitalized
    }
}

// MARK: - Text Recognizer
class TextRecognizer {
    private let request: VNRecognizeTextRequest
    
    init() {
        request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = ["en", "fr", "es", "de"]
    }
    
    func recognizeText(using handler: VNImageRequestHandler, completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([self.request])
                let results = self.request.results ?? []
                let text = results
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                completion(text)
            } catch {
                print("Text recognition error: \(error)")
                completion("")
            }
        }
    }
}

