import Foundation
import AVKit
import AVFoundation
import GoogleInteractiveMediaAds

class BaseLiveIMAViewController: BaseViewController {
    
    var adsLoader: IMAAdsLoader!
    var streamManager: IMAStreamManager!
    var adsManager: IMAAdsManager!
    var contentPlayhead: IMAAVPlayerContentPlayhead?
    var vodPlayerView: UIView!
    
    private let adTagURLString = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&correlator="
    
    private var kAssetKey = "sN_IYUG8STe1ZzhIIE_ksA"
    var playerVolume: Int?
    var player: AVPlayer!
    var playerViewController: AVPlayerViewController!
    
    var adCurrentPosition: Int64 = 0
    var isPlayingAd: Bool = false
    var isPostRollPlayed: Bool = false
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBarTitle(title: "Live with ads")
        registerDidBecomeActiveObserver()
        registerDidEnterBackgroundObserver()
        
        delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpContentPlayer()
        setUpAdsLoader()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.requestAds()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (self.isMovingFromParent) {
            playerViewController.view.removeFromSuperview()
            playerViewController.removeFromParent()
            playerViewController.player = nil
            playerViewController = nil
        }
    }
    
    func setupVideoPlayer(with url: String) {
        player = AVPlayer(url: URL(string: url)!)
        playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.view.frame = vodPlayerView.bounds
        playerViewController.player?.pause()
        vodPlayerView.addSubview(playerViewController.view)
        playerViewController.view.backgroundColor = UIColor.clear
    }
    
    func setUpAdsLoader() {
        adsLoader = IMAAdsLoader(settings: nil)
    }
    
    func requestAds() {
        let adDisplayContainer = IMAAdDisplayContainer(adContainer: self.vodPlayerView, viewController: self)
        // Create an ad request with our ad tag, display container, and optional user context.
        let imaVideoDisplay = IMAAVPlayerVideoDisplay(avPlayer: self.player)
        let request = IMALiveStreamRequest(assetKey: kAssetKey, adDisplayContainer: adDisplayContainer, videoDisplay: imaVideoDisplay)
        
        let requestIMA = IMAAdsRequest(
            adTagUrl: self.adTagURLString,
            adDisplayContainer: adDisplayContainer,
            contentPlayhead: contentPlayhead,
            userContext: nil)
        adsLoader.requestAds(with: requestIMA)
        adsLoader.requestStream(with: request)
        
    }
    
    @objc func contentDidFinishPlaying(_ notification: Notification) {
        adsLoader.contentComplete()
    }
    
    func setUpContentPlayer() {
        // Load AVPlayer with path to your content.
        showContentPlayer()
        
        contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: player)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.contentDidFinishPlaying(_:)),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: player.currentItem);
    }
    
    func showContentPlayer() {
        self.addChild(playerViewController)
        playerViewController.view.frame = vodPlayerView.bounds
        vodPlayerView.insertSubview(playerViewController.view, at: 0)
        playerViewController.didMove(toParent:self)
    }
    
    func hideContentPlayer() {
        // The whole controller needs to be detached so that it doesn't capture  events from the remote.
        playerViewController.willMove(toParent:nil)
        playerViewController.view.removeFromSuperview()
        playerViewController.removeFromParent()
    }
    
    
    func registerDidEnterBackgroundObserver() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    func registerDidBecomeActiveObserver() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc func didBecomeActive() {
        if playerViewController.player?.timeControlStatus == .paused {
            if isPlayingAd {
                adsManager?.resume()
            } else {
                playerViewController.player?.play()
            }
        }
    }
    
    @objc func appDidEnterBackground() {
        if isPlayingAd {
            adsManager?.pause()
        }
        player.pause()
    }
    
    func resumeVideoPlayer() {
        showContentPlayer()
        isPlayingAd = false
        player.play()
    }
    
    func pauseVideoPlayer() {
        player.pause()
        isPlayingAd = true
        hideContentPlayer()
    }
}

extension BaseLiveIMAViewController: BaseViewControllerDelegate {
    func setPlayerRate(with value: Float?) {
        player.rate = value ?? 1.0
    }
}

