import SwiftUI
import WebKit
import Combine

class WebContentStorage: ObservableObject {
    var webView: WKWebView?
    var lastLoadedURL: URL?
}

struct ExtendedContentWebView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = WebContentStorage()
    @State private var canGoBack = false
    @State private var orientation = UIDeviceOrientation.unknown

    // Detect iPad
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

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
            
            SecureWebEngineRepresentable(url: url, storage: storage, canGoBack: $canGoBack, orientation: $orientation)
                .ignoresSafeArea(edges: .bottom)
        }
        .background(Color(.systemBackground))
        // iPad: present as sheet with fixed width instead of full screen cover
        .frame(maxWidth: isPad ? 800 : .infinity)
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            // Track orientation changes to handle WebView reloads
            orientation = UIDevice.current.orientation
        }
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
    @Binding var orientation: UIDeviceOrientation

    func makeUIView(context: Context) -> WKWebView {
        if let existingView = storage.webView, storage.lastLoadedURL == url {
            // Don't recreate webview on rotation, reuse existing one
            return existingView
        }
        
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // JavaScript is enabled by default; no need to set deprecated property
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // Disable bounces but allow proper zoom/scale handling
        webView.scrollView.bounces = false
        webView.scrollView.contentMode = .scaleToFill
        
        // Handle auto-layout for rotation properly
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Inject viewport meta tag to prevent zoom issues on rotation
        let viewportScript = """
        var meta = document.querySelector('meta[name="viewport"]');
        if (!meta) {
            meta = document.createElement('meta');
            meta.name = 'viewport';
            document.head.appendChild(meta);
        }
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        """
        let userScript = WKUserScript(source: viewportScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(userScript)

        storage.webView = webView
        storage.lastLoadedURL = url
        
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // On orientation change, only update frame bounds, don't reload
        // The binding change triggers updateUIView but we don't reload content
        if uiView.url == nil || uiView.url?.absoluteString != url.absoluteString {
            uiView.load(URLRequest(url: url))
        }
        
        // Force layout update without reload to fix zoom issues
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: SecureWebEngineRepresentable
        init(_ parent: SecureWebEngineRepresentable) { self.parent = parent }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.canGoBack = webView.canGoBack }
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.canGoBack = webView.canGoBack }
        }
        
        // Handle new window requests (prevents some stream refreshes)
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}
