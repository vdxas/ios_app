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
        cfg.allowsAirPlayForMediaPlayback = true
        cfg.websiteDataStore = .default() // cookies/sesijos

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

        // Leisti tik app.invoicer.lt
        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let host = navigationAction.request.url?.host else {
                decisionHandler(.cancel); return
            }
            decisionHandler(host == allowedHost ? .allow : .cancel)
        }

        // window.alert(...)
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            UIApplication.shared.topMostViewController()?.present(alert, animated: true)
        }
    }
}

// Naudingas pagalbininkas alert'ams pateikti
private extension UIApplication {
    func topMostViewController(base: UIViewController? = {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else { return nil }
        return root
    }()) -> UIViewController? {
        if let nav = base as? UINavigationController { return topMostViewController(base: nav.visibleViewController) }
        if let tab = base as? UITabBarController { return topMostViewController(base: tab.selectedViewController) }
        if let presented = base?.presentedViewController { return topMostViewController(base: presented) }
        return base
    }
}
