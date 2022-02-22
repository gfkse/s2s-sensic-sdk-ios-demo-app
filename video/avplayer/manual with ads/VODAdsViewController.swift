import Foundation
import UIKit
import s2s_sdk_ios
import AVKit
import AVFoundation
import GoogleInteractiveMediaAds

class VODAdsViewController: BaseViewController {
    
    private var adsLoader: IMAAdsLoader!
    private var adsManager: IMAAdsManager!
    private var adOpener: IMALinkOpenerDelegate?
    private var contentPlayhead: IMAAVPlayerContentPlayhead?
    
    private let adTagURLString = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpremidpost&cmsid=496&vid=short_onecue&correlator="
    
    private let url = "https://demo-config-preproduction.sensic.net/video/video3.mp4"
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private let contentId = "default"
    private let adId = "ad"
    
    private var muteObservation: NSKeyValueObservation?
    
    private var playerVolume: Int?
    private var player: AVPlayer!
    private var playerViewController: AVPlayerViewController!
    
    private var s2sAgent: S2SAgent?
    private var adAgent: S2SAgent?
    
    private var interval: Int64 = 0
    private var isPlayingAd: Bool = false
    
    private var isPostRollPlayed: Bool = false
    
    @IBOutlet private weak var playerView: UIView!
    @IBAction func showChangeSpeedOptionView(_ sender: UIButton) {
        showChangeSpeedAlert()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBarTitle(title: "Video on Demand with ads")
        delegate = self
        
        setupVideoPlayer() // setup the Video Player as you want
        setupAgent()
        setupAdAgent()
        
        setUpContentPlayer()
        setUpAdsLoader()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        self.requestAds()
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
    
    func setUpAdsLoader() {
        adsLoader = IMAAdsLoader(settings: nil)
        adsLoader.delegate = self
    }
    
    func requestAds() {
        // Create ad display container for ad rendering.
        
        let adDisplayContainer = IMAAdDisplayContainer(adContainer: self.playerView, viewController: self)
        // Create an ad request with our ad tag, display container, and optional user context.
        let request = IMAAdsRequest(
            adTagUrl: self.adTagURLString,
            adDisplayContainer: adDisplayContainer,
            contentPlayhead: contentPlayhead,
            userContext: nil)
        
        adsLoader.requestAds(with: request)
    }
    
    @objc func contentDidFinishPlaying(_ notification: Notification) {
        adsLoader.contentComplete()
    }
    
    func showContentPlayer() {
        self.addChild(playerViewController)
        playerViewController.view.frame = playerView.bounds
        playerView.insertSubview(playerViewController.view, at: 0)
        playerViewController.didMove(toParent:self)
    }
    
    func hideContentPlayer() {
        // The whole controller needs to be detached so that it doesn't capture  events from the remote.
        playerViewController.willMove(toParent:nil)
        playerViewController.view.removeFromSuperview()
        playerViewController.removeFromParent()
    }
    
    //MARK: - Video Player
    func setupVideoPlayer() {
        player = AVPlayer(url: URL(string: url)!)
        playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.view.frame = playerView.bounds
        playerViewController.player?.pause()
        playerView.addSubview(playerViewController.view)
        playerViewController.view.backgroundColor = UIColor.clear
    }
    
    //MARK: - Setup Agent
    
    func setupAgent() {
        let streamPositionCallback: StreamPositionCallback = { [unowned self] in
            print("Time callback: \(self.player.currentTime().seconds)")
            return Int64(self.player.currentTime().seconds * 1000) // we need to return milliseconds
        }
        do {
            s2sAgent = try S2SAgent(configUrl: "https://demo-config-preproduction.sensic.net/s2s-ios.json", mediaId: mediaId, streamPositionCallback: streamPositionCallback)
            registerObserver()
            registerDidBecomeActiveObserver()
            registerDidEnterBackgroundObserver()
            playerVolume = Int(AVAudioSession.sharedInstance().outputVolume * 100)
        } catch let error {
            print(error)
        }
    }
    
    //MARK: - Setup AdAgent
    
    func setupAdAgent() {
        let streamPositionCallback: StreamPositionCallback = { [unowned self] in
            print("Time callback: \(interval)")
            return interval
        }
        do {
            adAgent = try S2SAgent(configUrl: "https://demo-config-preproduction.sensic.net/s2s-ios.json", mediaId: mediaId, streamPositionCallback: streamPositionCallback)
        } catch let error {
            print(error)
        }
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
                adsManager.resume()
            } else {
                playerViewController.player?.play()
            }
        }
    }
    
    @objc func appDidEnterBackground() {
        if isPlayingAd {
            adsManager.pause()
        }
        s2sAgent?.flushStorageQueue()
    }
    
    fileprivate func registerObserver() {
        player.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
        player.addObserver(self, forKeyPath: "volume", options: NSKeyValueObservingOptions.new, context: nil)
        
        registerVolumeObserver()
    }
    
    private func registerVolumeObserver() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true)
        } catch {
            print("An error occured from audioSession")
        }
        
        audioSession.addObserver(self, forKeyPath: "outputVolume", options: NSKeyValueObservingOptions.new, context: nil)
        muteObservation = player?.observe(\.isMuted) { [weak self] player, _ in
            if player.timeControlStatus != .playing {
                return
            }
            
            if player.isMuted {
                self?.s2sAgent?.volume(volume: "0")
            } else {
                self?.s2sAgent?.volume(volume: "\( self?.playerVolume ?? 0)")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if player.timeControlStatus == .playing {
            player.pause()
        }
        
        adsManager.destroy()
        
        if (self.isMovingFromParent) {
            playerViewController.view.removeFromSuperview()
            playerViewController.removeFromParent()
            
            player.removeObserver(self, forKeyPath: "rate")
            player.removeObserver(self, forKeyPath: "volume")
            
            AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "rate" {
            let rate = change![NSKeyValueChangeKey.newKey] as! Float
            if rate == 0 {
                if player.currentTime().seconds != 0.0  && !isPostRollPlayed {
                    s2sAgent?.stop()
                }
            } else {
                if player.timeControlStatus == .playing {
                    s2sAgent?.stop()
                }
                
                isPostRollPlayed = player.currentTime().seconds == player.currentItem?.duration.seconds
                if !isPostRollPlayed {
                    s2sAgent?.playStreamOnDemand(contentId: contentId,
                                                 streamId: url,
                                                 options: ["volume": "\(playerVolume ?? 0)", "speed": "\(player.rate)"],
                                                 customParams: [:])
                }
            }
        }
        
        if keyPath == "outputVolume" {
            if let volume = change![NSKeyValueChangeKey.newKey] as? Float {
                if !player.isMuted {
                    playerVolume = Int(volume * 100)
                    s2sAgent?.volume(volume: "\(playerVolume ?? 0)")
                }
            }
        }
    }
}

extension VODAdsViewController: BaseViewControllerDelegate {
    func setPlayerRate(with value: Float?) {
        player.rate = value ?? 1.0
    }
}

extension VODAdsViewController: IMAAdsLoaderDelegate {
    func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        adsManager = adsLoadedData.adsManager
        adsManager.delegate = self
        adsManager.initialize(with: nil)
    }
    
    func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        print("Error loading ads: " + adErrorData.adError.message)
        showContentPlayer()
        playerViewController.player?.play()
    }
}

extension VODAdsViewController: IMAAdsManagerDelegate {
    func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        // Play each ad once it has been loaded
        if event.type == IMAAdEventType.LOADED {
            interval = 0
            adsManager.start()
        }
        
        if event.type == IMAAdEventType.RESUME {
            adAgent?.playStreamOnDemand(contentId: adId,
                                        streamId: url + "ads",
                                        options: ["volume": "\(playerVolume ?? 0)", "speed": "\(1.0)"],
                                        customParams: [:])
        }
        
        if event.type == IMAAdEventType.PAUSE {
            adAgent?.stop()
        }
    }
    
    func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        // Fall back to playing content
        print("AdsManager error: " + error.message)
        showContentPlayer()
        playerViewController.player?.play()
    }
    
    func adsManager(_ adsManager: IMAAdsManager, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval) {
        interval = Int64(mediaTime * 1000)
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        // Pause the content for the SDK to play ads.
        playerViewController.player?.pause()
        isPlayingAd = true
        hideContentPlayer()
        
        
        adAgent?.playStreamOnDemand(contentId: adId,
                                    streamId: url + "ads",
                                    options: ["volume": "\(playerVolume ?? 0)", "speed": "\(1.0)"],
                                    customParams: [:])
        
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        // Resume the content since the SDK is done playing ads (at least for now).
        showContentPlayer()
        isPlayingAd = false
        playerViewController.player?.play()
        adAgent?.stop()
    }
}
