import UIKit

class MainViewController: BaseViewController {

    
    @IBOutlet weak var vodButton: UIButton!
    @IBOutlet weak var liveButton: UIButton!
    @IBOutlet weak var liveNoSeekButton: UIButton!
    @IBOutlet weak var vodExtensionButton: UIButton!
    @IBOutlet weak var liveExtensionButton: UIButton!
    @IBOutlet weak var liveNoSeekExtensionButton: UIButton!
    @IBOutlet weak var contentButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var webSdkButton: UIButton!
    @IBOutlet weak var vodAdsButton: UIButton!
    @IBOutlet weak var liveAdsButton: UIButton!
    @IBOutlet weak var liveAdsExtensionButton: UIButton!
    
    @IBOutlet weak var vodIMAExtensionButton: UIButton!
    
    @IBOutlet weak var manualStackView: UIStackView!
    @IBOutlet weak var extensionStackView: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()
        styleUI()
    }
    
    private func styleUI() {
        setNavigationBarTitle(title: "S2S Demo App for iOS")
        vodButton.setUpLayer(button: vodButton, title: "Video on Demand")
        liveButton.setUpLayer(button: liveButton, title: "LIVE")
        liveNoSeekButton.setUpLayer(button: liveNoSeekButton, title: "LIVE (No Seek)")
        
        vodAdsButton.setUpLayer(button: vodAdsButton, title: "VoD IMA")
        liveAdsButton.setUpLayer(button: liveAdsButton, title: "LIVE IMA")
        liveAdsExtensionButton.setUpLayer(button: liveAdsExtensionButton, title: "LIVE IMA")
        vodIMAExtensionButton.setUpLayer(button: vodIMAExtensionButton, title: "VoD IMA ")
        vodExtensionButton.setUpLayer(button: vodExtensionButton, title: "Video on Demand")
        liveExtensionButton.setUpLayer(button: liveExtensionButton, title: "LIVE")
        liveNoSeekExtensionButton.setUpLayer(button: liveNoSeekExtensionButton, title: "LIVE (No Seek)")
        
        contentButton.setUpLayer(button: contentButton, title: "Content")
        settingsButton.setUpLayer(button: settingsButton, title: "Settings")
        webSdkButton.setUpLayer(button: webSdkButton, title: "Web Sdk")
    }
    
    @IBAction func showManualImplementaion(_ sender: Any) {
        manualStackView.isHidden = !manualStackView.isHidden
    }
    @IBAction func showExtensionImplementation(_ sender: Any) {
        extensionStackView.isHidden = !extensionStackView.isHidden
    }
}
