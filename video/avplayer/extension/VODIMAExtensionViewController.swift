import UIKit
import s2s_sdk_ios
import AVKit
import AVFoundation
import S2S_GoogleIMA

class VODIMAExtensionViewController: BaseVODIMAViewController {
    
    private let configUrl = "https://demo-config-preproduction.sensic.net/s2s-ios.json"
    private let vodUrl = "https://demo-config-preproduction.sensic.net/video/video3.mp4"
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    
    @IBOutlet weak var playerView: UIView!

    private var playerExtension: AVPlayerVODAdExtension?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        vodPlayerView = playerView
        setupVideoPlayer(with: vodUrl)
        
        let config = S2SConfig(mediaId: mediaId, url: configUrl)
        playerExtension = AVPlayerVODAdExtension(avPlayerController: playerViewController,config: config, contentId: "contentId", customParams: ["":""])
        
        //call setParameters() as soon as your player is switching over to different content. Otherwise, new content will be reported with parameters of the video played before.
        //playerExtension?.setParameters(contentId: "", customParams: ["":""])
        
        setUpAdsLoader()
    }
    override func setUpAdsLoader() {
        super.setUpAdsLoader()
        adsLoader.delegate = self
    }
    
    @IBAction func showChangeSpeedOptionView(_ sender: UIButton) {
        showChangeSpeedAlert()
    }
}

extension VODIMAExtensionViewController: IMAAdsManagerDelegate {
    func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        // Play each ad once it has been loaded
        if event.type == IMAAdEventType.LOADED {
            adsManager.start()
        }
    }
    
    func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        // Fall back to playing content
        print("AdsManager error: " + error.message)
        resumeVideoPlayer()
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        // Pause the content for the SDK to play ads.
        pauseVideoPlayer()
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        // Resume the content since the SDK is done playing ads (at least for now).
        resumeVideoPlayer()
    }
}

extension VODIMAExtensionViewController: IMAAdsLoaderDelegate {
    func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        adsManager = adsLoadedData.adsManager
        adsManager.delegate = self
        // To track ads via Sensic Agent, please add the following line in the score of this method
        playerExtension?.activateGoogleIMASupport(adsManager: adsManager)
        adsManager.initialize(with: nil)
    }
    
    func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        print("Error loading ads: " + adErrorData.adError.message)
        resumeVideoPlayer()
    }
}
