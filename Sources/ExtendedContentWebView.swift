import SwiftUI
import WebKit

/// Persistent view engine storage to prevent page resets on orientation changes
class WebContentStorage: ObservableObject {
    var webView: WKWebView?
    var lastLoadedURL: URL?
}

struct ExtendedContentWebView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = WebContentStorage()
    @State private var canGoBack = false

    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Control Bar adapted for full-screen theater immersion
            HStack {
                Button(action: { 
                    storage.webView?.goBack() 
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                        Text("Back")
                    }
                    .foregroundColor(canGoBack ? .green : .secondary)
                }
                .disabled(!canGoBack)
                
                Spacer()
                
                Text("Theater Mode")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Button(action: { 
                    restoreStandardDeviceOrientation()
                    dismiss() 
                }) {
                    Text("Close")
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color.black) // Dark bar background to blend with movie style frames
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            // Re-usable persistent rendering core
            SecureWebEngineRepresentable(url: url, storage: storage, canGoBack: $canGoBack)
                .ignoresSafeArea()
        }
        .background(Color.black) // High contrast base layer prevents light bleed lines
        .toolbar(.hidden, for: .navigationBar) // Strip native navigation wrappers if pushed onto stack
        .onAppear {
            forceLandscapeTheaterOrientation()
        }
        .onDisappear {
            restoreStandardDeviceOrientation()
        }
    }
    
    // --- Dynamic Orientation Controls ---
    
    private func forceLandscapeTheaterOrientation() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        if #available(iOS 16.0, *) {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight)) { error in
                AppLogger.shared.error("Theater Mode rotation request was bypassed: \(error.localizedDescription)")
            }
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }
    }

    private func restoreStandardDeviceOrientation() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        if #available(iOS 16.0, *) {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }
}

struct SecureWebEngineRepresentable: UIViewRepresentable {
    let url: URL
    let storage: WebContentStorage
    @Binding var canGoBack: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        // ✅ CRITICAL FIX: If instance already exists, return it directly to preserve current player execution state during layout rotation loops
        if let existingView = storage.webView, storage.lastLoadedURL == url {
            return existingView
        }
        
        let configuration = WKWebViewConfiguration()
        
        // Inline configuration handles video maximization gracefully, enabling HTML5 theater mode
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Optimizes media delivery behavior to allow fullscreen expansion triggers
        configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        
        // Store instances securely inside the persistent reference container
        storage.webView = webView
        storage.lastLoadedURL = url
        
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // Layout orientation mutations trigger updating cycles safely here without refreshing target loads
    }
    
    func makeCoordinator() -> Coordinator { 
        Coordinator(self) 
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: SecureWebEngineRepresentable
        
        init(_ parent: SecureWebEngineRepresentable) { 
            self.parent = parent 
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { 
                self.parent.canGoBack = webView.canGoBack 
            }
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            DispatchQueue.main.async { 
                self.parent.canGoBack = webView.canGoBack 
            }
        }
    }
}
