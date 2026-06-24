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
            // Dynamic Status Bar Spacer matching platform appearance
            Color(.systemBackground)
                .frame(height: safeAreaTopInset)
                .ignoresSafeArea(edges: .top)
            
            // Top Navigation Control Bar
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
                
                Text("Content View")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { 
                    dismiss() 
                }) {
                    Text("Close")
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            Divider()
            
            // Re-usable persistent rendering core
            SecureWebEngineRepresentable(url: url, storage: storage, canGoBack: $canGoBack)
                .ignoresSafeArea(edges: .bottom)
        }
        .background(Color(.systemBackground))
    }
    
    /// Fallback computation logic for safe-area insets across variable screen dimensions
    private var safeAreaTopInset: CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let topInset = windowScene.windows.first?.safeAreaInsets.top else { return 20 }
        return topInset
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
