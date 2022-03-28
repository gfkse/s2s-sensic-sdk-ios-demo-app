import UIKit
import s2s_sdk_ios
import AVKit
import AVFoundation
import GoogleInteractiveMediaAds

class LiveIMAExtensionViewController: BaseLiveIMAViewController {
    
    private let configUrl = "https://demo-config-preproduction.sensic.net/s2s-ios.json"
    private let liveUrl = "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    
    @IBOutlet weak var playerView: UIView!
    
    private var playerExtension: AVPlayerLiveExtension?
    private var lastPosition: Int64 = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        vodPlayerView = playerView
        setupVideoPlayer(with: liveUrl)
        
        let config = S2SConfig(mediaId: mediaId, url: configUrl)
        playerExtension = AVPlayerLiveExtension(avPlayerController: playerViewController, config: config, contentId: "contentId", customParams: ["":""])
        
        //If you want to change the parameters, please evoke the line below
        //playerExtension?.setParameters(contentId: "", customParams: ["":""])
        
        setUpAdsLoader()
        
    }
    
    override func setUpAdsLoader() {
        super.setUpAdsLoader()
        adsLoader.delegate = self
    }
    
    //MARK: Videoplayer
    
    @IBAction func showChangeSpeedOptionView(_ sender: UIButton) {
        showChangeSpeedAlert()
    }
}

extension LiveIMAExtensionViewController: IMAAdsLoaderDelegate {
    func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        streamManager = adsLoadedData.streamManager
        streamManager.delegate = self
        streamManager.initialize(with: nil)
    }
    
    func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        print("Error loading ads: " + adErrorData.adError.message)
    }
}

extension LiveIMAExtensionViewController: IMAStreamManagerDelegate {
    func streamManager(_ streamManager: IMAStreamManager!, didReceive event: IMAAdEvent!) {
        playerExtension?.activateGoogleIMASupport(from: event, with: lastPosition)
    }
    
    func streamManager(_ streamManager: IMAStreamManager!, didReceive error: IMAAdError!) {
        print("Stream Manager error: " + error.message)
    }
    
    func streamManager(_ streamManager: IMAStreamManager!, adDidProgressToTime time: TimeInterval, adDuration: TimeInterval, adPosition: Int, totalAds: Int, adBreakDuration: TimeInterval, adPeriodDuration: TimeInterval) {
        lastPosition = Int64(time * 1000)
    }
}
