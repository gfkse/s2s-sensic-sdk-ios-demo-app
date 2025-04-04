import UIKit
import AppTrackingTransparency
class MainViewController: BaseViewController {

    @IBOutlet weak var vodButton: UIButton!
    @IBOutlet weak var liveButton: UIButton!
    @IBOutlet weak var liveNoSeekButton: UIButton!
    @IBOutlet weak var vodExtensionButton: UIButton!
    @IBOutlet weak var liveExtensionButton: UIButton!
    @IBOutlet weak var liveNoSeekExtensionButton: UIButton!
    @IBOutlet weak var contentButton: UIButton!
    @IBOutlet weak var webSdkButton: UIButton!
    @IBOutlet weak var vodAdsButton: UIButton!
    @IBOutlet weak var liveAdsButton: UIButton!
    @IBOutlet weak var liveAdsExtensionButton: UIButton!
    
    @IBOutlet weak var liveTimeShiftedButton: UIButton!
    @IBOutlet weak var liveTimeShiftedExtensionButton: UIButton!
    
    
    @IBOutlet weak var audioLiveExtensionAVPlayerButton: UIButton!
    @IBOutlet weak var audioExtensionAVPlayerButton: UIButton!
    @IBOutlet weak var audioOnDemandAVPlayerButton: UIButton!
    @IBOutlet weak var audioLiveAVPlayerButton: UIButton!
    
    @IBOutlet weak var liveAdsBitmovinButton: UIButton!
    @IBOutlet weak var vodBitmovinButton: UIButton!
    @IBOutlet weak var liveNoSeekBitmovinButton: UIButton!
    @IBOutlet weak var liveBitmovinButton: UIButton!
    @IBOutlet weak var vodAdsBitmovinButton: UIButton!
    
    @IBOutlet weak var vodBitmovinExtensionButton: UIButton!
    @IBOutlet weak var vodAdsBitmovinExtensionButton: UIButton!
    @IBOutlet weak var liveBitmovinExtensionButton: UIButton!
    @IBOutlet weak var liveNoSeekBitmovinExtensionButton: UIButton!
    @IBOutlet weak var LiveAdsBitmovinExtensionButton: UIButton!
    
    @IBOutlet weak var bitmovinExtensionStackView: UIStackView!
    @IBOutlet weak var bitmovinStackView: UIStackView!

    @IBOutlet weak var idfaButton: UIButton!
    @IBOutlet weak var optInSwitch: UISwitch!
    @IBOutlet weak var vodIMAExtensionButton: UIButton!
    @IBOutlet weak var bitmovinButton: UIButton!
    @IBAction func didTapSwitchButton(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(optInSwitch.isOn, forKey: "optin")
        print(optInSwitch.isOn)
    }
    
    @IBAction func didTapIDFAButton(_ sender: UIButton) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization() { status in
                switch status {
                case .authorized:
                    print("authorized")
                case .notDetermined:
                    break
                case .restricted:
                    break
                case .denied:
                    break
                @unknown default:
                    break
                }
            }
        } else {
            // Fallback on earlier versions
        }
        idfaButton.isHidden = true

    }
    @IBOutlet weak var manualStackView: UIStackView!
    @IBOutlet weak var extensionStackView: UIStackView!
    @IBOutlet weak var avplayerManualStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleUI()
    }

    private func styleUI() {
        setNavigationBarTitle(title: "S2S Demo App for iOS")
        vodButton.setUpLayer(button: vodButton, title: "Video on Demand")
        liveButton.setUpLayer(button: liveButton, title: "LIVE")
        liveNoSeekButton.setUpLayer(button: liveNoSeekButton, title: "LIVE (No Seek)")
        liveTimeShiftedButton.setUpLayer(button: liveTimeShiftedButton, title: "Live TimeShift")

        vodAdsButton.setUpLayer(button: vodAdsButton, title: "VoD IMA")
        liveAdsButton.setUpLayer(button: liveAdsButton, title: "LIVE IMA")
        liveAdsExtensionButton.setUpLayer(button: liveAdsExtensionButton, title: "LIVE IMA")
        vodIMAExtensionButton.setUpLayer(button: vodIMAExtensionButton, title: "VoD IMA ")
        vodExtensionButton.setUpLayer(button: vodExtensionButton, title: "Video on Demand")
        liveTimeShiftedExtensionButton.setUpLayer(button: liveTimeShiftedExtensionButton, title: "Live Timeshifted")
        liveExtensionButton.setUpLayer(button: liveExtensionButton, title: "LIVE")
        liveNoSeekExtensionButton.setUpLayer(button: liveNoSeekExtensionButton, title: "LIVE (No Seek)")

        contentButton.setUpLayer(button: contentButton, title: "Content")
        webSdkButton.setUpLayer(button: webSdkButton, title: "Web Sdk")

        liveAdsBitmovinButton.setUpLayer(button: liveAdsBitmovinButton, title: "Live Ads")
        vodBitmovinButton.setUpLayer(button: vodBitmovinButton, title: "VoD")
        liveNoSeekBitmovinButton.setUpLayer(button: liveNoSeekBitmovinButton, title: "Live No Seek")
        liveBitmovinButton.setUpLayer(button: liveBitmovinButton, title: "Live")
        vodAdsBitmovinButton.setUpLayer(button: vodAdsBitmovinButton, title: "VoD Ads")


        
        vodBitmovinExtensionButton.setUpLayer(button: vodBitmovinExtensionButton, title: "VoD")
        vodAdsBitmovinExtensionButton.setUpLayer(button: vodAdsBitmovinExtensionButton, title: "VoD ads")
        liveBitmovinExtensionButton.setUpLayer(button: liveBitmovinExtensionButton, title: "Live")
        liveNoSeekBitmovinExtensionButton.setUpLayer(button: liveNoSeekBitmovinExtensionButton, title: "Live no seek")
        LiveAdsBitmovinExtensionButton.setUpLayer(button: LiveAdsBitmovinExtensionButton, title: "Live Ads")
        
    
        audioLiveExtensionAVPlayerButton.setUpLayer(button: audioLiveExtensionAVPlayerButton, title: "Extension Live")
        audioLiveAVPlayerButton.setUpLayer(button: audioLiveAVPlayerButton, title: "Live Stream")
        audioExtensionAVPlayerButton.setUpLayer(button: audioExtensionAVPlayerButton, title: "Audio Extension")
        audioOnDemandAVPlayerButton.setUpLayer(button: audioOnDemandAVPlayerButton, title: "Audio On Demand")
        
        let defaults = UserDefaults.standard
        optInSwitch.isOn = defaults.bool(forKey: "optin")

        if #available(iOS 14, *) {
            idfaButton.isHidden = ATTrackingManager.trackingAuthorizationStatus != .notDetermined
        } else {
            // Fallback on earlier versions
        }
    }
    
    @IBAction func showAVPlayerAudioStackView(_ sender: Any) {
        avplayerManualStackView.isHidden = !avplayerManualStackView.isHidden
    }
    
    @IBAction func showBitmovinExtension(_ sender: Any) {
        bitmovinExtensionStackView.isHidden = !bitmovinExtensionStackView.isHidden
    }
    
    @IBAction func showBitmovin(_ sender: Any) {
        bitmovinStackView.isHidden = !bitmovinStackView.isHidden
    }
    @IBAction func showManualImplementaion(_ sender: Any) {
        manualStackView.isHidden = !manualStackView.isHidden
    }
    @IBAction func showExtensionImplementation(_ sender: Any) {
        extensionStackView.isHidden = !extensionStackView.isHidden
    }
}
