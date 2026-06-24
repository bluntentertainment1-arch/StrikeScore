import SwiftUI
import WebKit

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
            Color(.systemBackground)
                .frame(height: safeAreaTopInset)
                .ignoresSafeArea(edges: .top)
            
            HStack {
                Button(action: { storage.webView?.goBack() }) {
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
        if let existingView = storage.webView, storage.lastLoadedURL == url {
            return existingView
        }
        
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.bounces = false
        
        storage.webView = webView
        storage.lastLoadedURL = url
        
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: SecureWebEngineRepresentable
        init(_ parent: SecureWebEngineRepresentable) { self.parent = parent }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.canGoBack = webView.canGoBack }
        }
        func webView(_ webView: WKWebView, didCommit navigation: UIViewNavigation!) {
            DispatchQueue.main.async { self.parent.canGoBack = webView.canGoBack }
        }
    }
}
