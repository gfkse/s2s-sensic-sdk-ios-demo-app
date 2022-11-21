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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        vodPlayerView = playerView
        setupVideoPlayer(with: liveUrl)
        
        let config = S2SConfig(mediaId: mediaId, url: configUrl)
        playerExtension = AVPlayerLiveExtension(avPlayerController: playerViewController, config: config, contentId: "contentId", customParams: ["":""])
        
        //call setParameters() as soon as your player is switching over to different content. Otherwise, new content will be reported with parameters of the video played before.
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
    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        streamManager = adsLoadedData.streamManager
        adsManager = adsLoadedData.adsManager
        
        if let adsManager = adsManager {
            adsManager.delegate = self
            playerExtension?.activateGoogleIMASupport(adsManager: adsManager)
            adsManager.initialize(with: nil)
        }
        
        if let streamManager = streamManager {
            streamManager.delegate = self
            streamManager.initialize(with: nil)
        }
    }
    
    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        print("Error loading ads: " + (adErrorData.adError.message ?? ""))
    }
}

extension LiveIMAExtensionViewController: IMAStreamManagerDelegate {
    func streamManager(_ streamManager: IMAStreamManager, didReceive event: IMAAdEvent) {
        playerExtension?.activateGoogleIMASupport(from: event)
    }
    
    func streamManager(_ streamManager: IMAStreamManager, didReceive error: IMAAdError) {
        print("Stream Manager error: " + (error.message ?? ""))
    }
    
    func streamManager(_ streamManager: IMAStreamManager, adDidProgressToTime time: TimeInterval, adDuration: TimeInterval, adPosition: Int, totalAds: Int, adBreakDuration: TimeInterval, adPeriodDuration: TimeInterval) {
        let position = Int64(time * 1000)
        playerExtension?.trackAdPosition(position: position)
    }
}

// MARK: - LIVE IMA

extension LiveIMAExtensionViewController: IMAAdsManagerDelegate {
    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        // Play each ad once it has been loaded
        
        if event.type == IMAAdEventType.LOADED {
            adsManager.start()
        }
    }
    
    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        // Fall back to playing content
        print("AdsManager error: " + (error.message ?? ""))
        resumeVideoPlayer()
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        // Pause the content for the SDK to play ads.
        pauseVideoPlayer()
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        // Resume the content since the SDK is done playing ads (at least for now).
        resumeVideoPlayer()
    }
}
