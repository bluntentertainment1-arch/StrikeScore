import SwiftUI
import WebKit

struct CleanStreamWebView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    
    // Core web view state instance to support the native back button
    @State private var webView: WKWebView? = nil
    @State private var canGoBack = false

    var body: some View {
        VStack(spacing: 0) {
            // 1. Sleek Custom Header Bar with ONLY Back and Close Actions
            HStack {
                Button(action: {
                    webView?.goBack()
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
                
                // Centered Minimalist Stream Label (No website URL visible)
                Text("Live Stream Player")
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
            
            // 2. The Custom Anti-Popup Secure Browser Core
            SecureWebEngineRepresentable(url: url, webViewRef: $webView, canGoBack: $canGoBack)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

// MARK: - Safe Web Kit Engine Infrastructure
struct SecureWebEngineRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var webViewRef: WKWebView?
    @Binding var canGoBack: Bool
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Optimize for content sizing
        let preferences = WKPreferences()
        preferences.minimumFontSize = 10
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator // Dynamic multi-window interceptor
        
        // Strip away standard bouncing mechanics
        webView.scrollView.bounces = false
        
        webViewRef = webView
        
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
        
        // Monitor item timeline states to unlock/lock back buttons smoothly
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
        
        // ✅ ANTI-POPUP SHIELD: Destroys any attempts to pop open new tabs, ads, or redirect frames
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            
            // If the site tries to launch an ad via a blank target link or popup script, catch it here
            if navigationAction.targetFrame == nil {
                // Return nil to completely kill the popup script request execution thread
                return nil
            }
            return nil
        }
    }
}
