import SwiftUI
import AVFoundation

struct BarcodeScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.delegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, ScannerViewControllerDelegate {
        let parent: BarcodeScannerView
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        func didFind(code: String) {
            parent.scannedCode = code
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct BarcodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        BarcodeScannerView(scannedCode: .constant(nil))
    }
} 
