import SwiftUI
import WebKit

// State coordinator to persist the view reference across rotation state transitions
class WebContentStorage: ObservableObject {
    var webView: WKWebView?
}

struct ExtendedContentWebView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var storage = WebContentStorage()
    @State private var canGoBack = false

    var body: some View {
        VStack(spacing: 0) {
            // Safe Area Status Bar Shield Mask
            Color(.systemBackground)
                .frame(height: safeAreaTopInset)
                .ignoresSafeArea(edges: .top)
            
            // Sleek Custom Header Bar
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
                
                Button(action: { dismiss() }) {
                    Text("Close")
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            Divider()
            
            SecureWebEngineRepresentable(url: url, storage: storage, canGoBack: $canGoBack)
                .ignoresSafeArea(edges: .bottom)
        }
        .background(Color(.systemBackground))
    }
    
    // Calculates the device specific top safe area padding layout dynamically
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
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        // If an instance was already built, pass back the exact same reference to prevent reload triggers
        if let existingView = storage.webView {
            return existingView
        }
        
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let preferences = WKPreferences()
        preferences.minimumFontSize = 10
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.bounces = false
        
        storage.webView = webView
        
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
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
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                return nil // Block external popup request contexts instantly
            }
            return nil
        }
    }
}
