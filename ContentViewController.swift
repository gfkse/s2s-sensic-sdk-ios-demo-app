import UIKit
import WebKit
import s2s_sdk_ios

class ContentViewController: UIViewController {

    @IBOutlet private weak var containerView: UIView!
    private var webView: WKWebView!
    
    private let mediaId = "s2sdemomediaid_sst_ios"
    private let stringUrl = "https://sensic.net"
    private let configUrl = "https://demo-config-preproduction.sensic.net/s2s-ios.json"
    // Tracking Agent
    var s2sAgent: S2SAgent?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        guard let url = URL(string: stringUrl) else { return }
        do {
            let config = S2SConfig(mediaId: mediaId, url: configUrl, crashReporting: true)
            s2sAgent = try S2SAgent(config: config)
        } catch let error {
            print(error)
        }
        s2sAgent?.impression(contentId: "default")
        
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    override func loadView() {
        super.loadView()
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: containerView.bounds, configuration: webConfiguration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        self.containerView.addSubview(webView)
    }
}

extension ContentViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard (webView.url?.absoluteString) != nil else { return }
        
        /** Please use your country-specific custom params https://confluence-docu.gfk.com/display/SENSIC/Client+specific+customizations  */
        let customParams: [String: String] = [:]
        
        ///Example custom params for Singapore
        //customParams.put("subscriber", "1");
        
        
        ///Example custom params for Spain
        //customParams.put("cp1", "appsBundleID");
        
        s2sAgent?.impression(contentId: "default", customParams: ["":""])
    }
}
