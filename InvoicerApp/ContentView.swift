import SwiftUI
import WebKit

struct ContentView: View {
    var body: some View {
        WebContainerView(urlString: "https://app.invoicer.lt/index.html")
            .ignoresSafeArea()
    }
}

struct WebContainerView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        // Saugykla default – kad veiktų login sesijos, jei jų reikia
        config.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.bounces = false

        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(allowedHost: "app.invoicer.lt")
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private let allowedHost: String
        init(allowedHost: String) { self.allowedHost = allowedHost }

        // Leisti tik app.invoicer.lt (viską kitą atšaukti arba atidaryti išorinėje naršyklėje)
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let host = navigationAction.request.url?.host else {
                decisionHandler(.cancel); return
            }
            if host == allowedHost {
                decisionHandler(.allow)
            } else {
                // Jei norite – atidarykite išorinėje naršyklėje:
                // UIApplication.shared.open(navigationAction.request.url!)
                decisionHandler(.cancel)
            }
        }

        // Failų įkėlimas / kamera iš <input type="file">
        // Nuo iOS 14.5+ WKWebView tai tvarko pats, bet laikome delegatą if needed.
        func webView(_ webView: WKWebView,
                     runOpenPanelWith parameters: WKOpenPanelParameters,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping ([URL]?) -> Void) {
            // Paliekame WKWebView numatytą failų parinkimą (kamera / biblioteka).
            // Jei reikėtų custom picker’io – čia jį iškviestumėte ir grąžintumėte pasirinktą failą kaip laikino failo URL.
            completionHandler(nil)
        }

        // „alert()“ ir pan. iš puslapio
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            UIApplication.shared.keyWindowPresentedController?.present(alert, animated: true)
        }
    }
}

private extension UIApplication {
    var keyWindowPresentedController: UIViewController? {
        self.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController?.presentedOrRoot
    }
}
private extension UIWindowScene {
    var keyWindow: UIWindow? { self.windows.first { $0.isKeyWindow } }
}
private extension UIViewController {
    var presentedOrRoot: UIViewController {
        presentedViewController?.presentedOrRoot ?? self
    }
}
