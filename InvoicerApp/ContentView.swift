import SwiftUI
import WebKit

@main
struct InvoicerApp: App {
    var body: some Scene {
        WindowGroup {
            WebContainerView(urlString: "https://app.invoicer.lt/index.html")
                .ignoresSafeArea()
        }
    }
}

struct WebContainerView: UIViewRepresentable {
    let urlString: String
    func makeCoordinator() -> Coordinator { Coordinator(allowedHost: "app.invoicer.lt") }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        cfg.allowsInlineMediaPlayback = true
        cfg.websiteDataStore = .default()

        let wv = WKWebView(frame: .zero, configuration: cfg)
        wv.navigationDelegate = context.coordinator
        wv.uiDelegate = context.coordinator
        wv.scrollView.bounces = false
        if let url = URL(string: urlString) {
            wv.load(URLRequest(url: url))
        }
        return wv
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private let allowedHost: String
        init(allowedHost: String) { self.allowedHost = allowedHost }

        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let host = action.request.url?.host else { decisionHandler(.cancel); return }
            decisionHandler(host == allowedHost ? .allow : .cancel)
        }

        func webView(_ webView: WKWebView,
                     runOpenPanelWith parameters: WKOpenPanelParameters,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping ([URL]?) -> Void) {
            completionHandler(nil) // <input type="file"> + kamera – sisteminis pickeris
        }
    }
}
