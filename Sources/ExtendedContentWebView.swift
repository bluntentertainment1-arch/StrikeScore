import SwiftUI
import WebKit

class WebContentStorage: ObservableObject {
    var webView: WKWebView?
    var lastLoadedURL: URL?
}

struct ExtendedContentWebView: View {
    let url: URL
    var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storage = WebContentStorage()
    @State private var canGoBack = false
    @State private var isLandscape = false

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

                // FIX #2: Use dedicated close interstitial, then dismiss
                Button(action: {
                    AdMobManager.shared.showCloseInterstitialIfAllowed {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.onDismiss?()
                        }
                    }
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

            SecureWebEngineRepresentable(url: url, storage: storage, canGoBack: $canGoBack)
                .ignoresSafeArea(edges: .bottom)
        }
        .background(Color(.systemBackground))
        .onAppear {
            unlockOrientationForVideo()
        }
        .onDisappear {
            lockOrientationToPortrait()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let orientation = UIDevice.current.orientation
            isLandscape = orientation.isLandscape
        }
    }

    private func unlockOrientationForVideo() {
        // WKWebView handles video orientation via allowsInlineMediaPlayback
    }

    private func lockOrientationToPortrait() {
        if #available(iOS 16.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UINavigationController.attemptRotationToDeviceOrientation()
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

        webView.scrollView.contentMode = .scaleToFill
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0

        let viewportScript = """
        var meta = document.querySelector('meta[name="viewport"]');
        if (!meta) {
            meta = document.createElement('meta');
            meta.name = 'viewport';
            document.getElementsByTagName('head')[0].appendChild(meta);
        }
        meta.content = 'width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no';
        """
        let userScript = WKUserScript(source: viewportScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)

        storage.webView = webView
        storage.lastLoadedURL = url

        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url?.absoluteString != url.absoluteString {
            uiView.load(URLRequest(url: url))
        }
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

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}
