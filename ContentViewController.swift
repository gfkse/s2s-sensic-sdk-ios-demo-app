import UIKit
import WebKit
import s2s_sdk_ios

class ContentViewController: UIViewController {
    
    private var webView: WKWebView!
    @IBOutlet private weak var webViewContainer: UIView!
    
    private let mediaId = "s2sdemomediaid_sst_android"
    private let videoUrl = "https://www.sensic.net"
    private let configUrl = "https://demo-config.sensic.net/s2s-android.json"
    // Tracking Agent
    var s2sAgent: S2SAgent?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard  let url = URL(string: videoUrl) else { return }
                
        do {
            self.s2sAgent = try S2SAgent(configUrl: self.configUrl, mediaId: self.mediaId)
        } catch let error {
            print(error)
        }
        
        self.webView.load(URLRequest(url: url))
    }
    
    override func loadView() {
        webView = WKWebView()
        webView.navigationDelegate = self
        webViewContainer = webView
    }
}



extension ContentViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        guard let url = webView.url?.absoluteString else { return }
        
        /** Please use your country-specific custom params https://confluence-docu.gfk.com/display/SENSIC/Client+specific+customizations  */
        let customParams: [String: String] = [:]
        
        ///Example custom params for Singapore
        //customParams.put("subscriber", "1");
        
        
        ///Example custom params for Spain
        //customParams.put("cp1", "appsBundleID");
        
        s2sAgent?.impression(contentId: url, customParams: customParams)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
}
