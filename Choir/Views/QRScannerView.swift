import SwiftUI
import AVFoundation

struct QRScannerView: UIViewRepresentable {
    @Binding var scannedCode: String
    @Binding var isScanning: Bool
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: QRScannerView
        
        init(parent: QRScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                // Check if it's a valid Sui address (0x followed by 64 hex characters)
                if stringValue.hasPrefix("0x") && stringValue.count == 66 {
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    parent.scannedCode = stringValue
                    parent.isScanning = false
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return view
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            let captureSession = AVCaptureSession()
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            }
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            
            // Add a focus rectangle
            let focusView = UIView(frame: CGRect(x: view.bounds.midX - 100, y: view.bounds.midY - 100, width: 200, height: 200))
            focusView.layer.borderColor = UIColor.white.cgColor
            focusView.layer.borderWidth = 2
            focusView.backgroundColor = UIColor.clear
            view.addSubview(focusView)
            
            // Start capture session
            DispatchQueue.global(qos: .background).async {
                captureSession.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error.localizedDescription)")
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Nothing to update
    }
}

struct QRScannerSheet: View {
    @Binding var isPresented: Bool
    @Binding var scannedAddress: String
    @State private var isScanning = true
    
    var body: some View {
        NavigationView {
            ZStack {
                QRScannerView(scannedCode: $scannedAddress, isScanning: $isScanning)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    Text("Scan a Sui address QR code")
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom, 40)
                }
            }
            .navigationBarTitle("Scan QR Code", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .onChange(of: isScanning) { newValue in
                if !newValue && !scannedAddress.isEmpty {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
    @State var code = ""
    @State var isPresented = true
    
    return QRScannerSheet(isPresented: $isPresented, scannedAddress: $code)
}
