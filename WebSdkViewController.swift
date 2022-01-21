import UIKit
import WebKit

class WebSdkViewController: UIViewController, WKNavigationDelegate {
    
    private var demoSdkUrl = "https://development.sensic-demo.gfk.com/index.html"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "WebSdk"
    
        let webView = WKWebView()
        webView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        webView.navigationDelegate = self
        webView.backgroundColor = UIColor.white
        webView.scrollView.bounces = false
        let webViewUrl = URL(string: self.demoSdkUrl)
        if let webViewUrl = webViewUrl {
            webView.load(URLRequest(url: webViewUrl, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData) as URLRequest)
        }
        
        self.view.addSubview(webView)
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        if (navigationAction.navigationType == .linkActivated || navigationAction.navigationType == .other) {
            if let url = navigationAction.request.url {
                if let url = navigationAction.request.url, url.host != "development.sensic-demo.gfk.com", UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                    decisionHandler(.cancel)
                }
                if (url.scheme == "https") {
                    decisionHandler(.allow)
                    return
                }
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
