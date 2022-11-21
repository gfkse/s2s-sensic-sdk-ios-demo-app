import Foundation
import UIKit
import s2s_sdk_ios
import AVKit
import AVFoundation
import GoogleInteractiveMediaAds

class VODIMAViewController: BaseVODIMAViewController {
    
    private let urlString = "https://demo-config-preproduction.sensic.net/video/video3.mp4"
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private let configUrl = "https://demo-config-preproduction.sensic.net/s2s-ios.json"
    private let contentIdDefault = "default"
    private let contentIdAd = "ad"
    
    private var muteObservation: NSKeyValueObservation?
    
    private var agent: S2SAgent?
    private var adAgent: S2SAgent?
    
    @IBOutlet private weak var playerView: UIView!
    
    @IBAction func showChangeSpeedOptionView(_ sender: UIButton) {
        showChangeSpeedAlert()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        vodPlayerView = playerView
        
        registerDidBecomeActiveObserver()
        registerDidEnterBackgroundObserver()
        
        setupVideoPlayer(with: urlString)
        setupAgent()
        setupAdAgent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if (self.isMovingFromParent) {
            
            player.removeObserver(self, forKeyPath: "rate")
            player.removeObserver(self, forKeyPath: "volume")
            
            AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Setup Content Agent
    func setupAgent() {
        let streamPositionCallback: StreamPositionCallback = { [weak self] in
            guard let self = self else {
                return Int64(0)
            }
            print("Time callback: \(self.player.currentTime().seconds)")
            return Int64(self.player.currentTime().seconds * 1000) // we need to return milliseconds
        }
        do {
            agent = try S2SAgent(configUrl: configUrl, mediaId: mediaId, streamPositionCallback: streamPositionCallback)
            registerObservers()
        } catch let error {
            print(error)
        }
    }
    
    //MARK: - Setup AdAgent
    func setupAdAgent() {
        let adPositionCallback: StreamPositionCallback = { [weak self] in
            guard let self = self else {
                return Int64(0)
            }
            print("Time callback: \(self.adCurrentPosition)")
            return self.adCurrentPosition
        }
        do {
            adAgent = try S2SAgent(configUrl: configUrl, mediaId: mediaId, streamPositionCallback: adPositionCallback)
        } catch let error {
            print(error)
        }
    }
    
    override func setUpAdsLoader() {
        super.setUpAdsLoader()
        adsLoader.delegate = self
    }
    
    func registerFlushStorageObserver() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(flushStorage), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc func flushStorage() {
        adAgent?.flushStorageQueue()
        agent?.flushStorageQueue()
    }
    
    func registerObservers() {
        player.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: nil)
        player.addObserver(self, forKeyPath: "volume", options: NSKeyValueObservingOptions.new, context: nil)
        
        registerFlushStorageObserver()
        registerVolumeObserver()
    }
    
    private func registerVolumeObserver() {
        playerVolume = Int(AVAudioSession.sharedInstance().outputVolume * 100)
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
                self?.agent?.volume(volume: "0")
            } else {
                self?.agent?.volume(volume: "\( self?.playerVolume ?? 0)")
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "rate" {
            let rate = change![NSKeyValueChangeKey.newKey] as! Float
            if rate == 0 {
                if player.currentTime().seconds != 0.0  && !isPostRollPlayed {
                    agent?.stop()
                }
            } else {
                if player.timeControlStatus == .playing {
                    agent?.stop()
                }
                
                isPostRollPlayed = player.currentTime().seconds == player.currentItem?.duration.seconds
                if !isPostRollPlayed {
                    agent?.playStreamOnDemand(contentId: contentIdDefault,
                                              streamId: urlString,
                                              options: ["volume": "\(playerVolume ?? 0)", "speed": "\(player.rate)"],
                                              customParams: [:])
                }
            }
        }
        
        if keyPath == "outputVolume" {
            if let volume = change![NSKeyValueChangeKey.newKey] as? Float {
                if !player.isMuted {
                    playerVolume = Int(volume * 100)
                    agent?.volume(volume: "\(playerVolume ?? 0)")
                }
            }
        }
    }
}

extension VODIMAViewController: IMAAdsManagerDelegate {
    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        // Play each ad once it has been loaded
        if event.type == IMAAdEventType.LOADED {
            adCurrentPosition = 0
            adsManager.start()
        }
        
        if event.type == IMAAdEventType.RESUME {
            adAgent?.playStreamOnDemand(contentId: contentIdAd, streamId: urlString + "ads", options: [:], customParams: [:])
        }
        
        if event.type == IMAAdEventType.PAUSE {
            adAgent?.stop()
        }
    }
    
    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        // Fall back to playing content
        print("AdsManager error: " + (error.message ?? ""))
        resumeVideoPlayer() // Call your method, which resumes and shows your video player
    }
    
    func adsManager(_ adsManager: IMAAdsManager, adDidProgressToTime mediaTime: TimeInterval, totalTime: TimeInterval) {
        adCurrentPosition = Int64(mediaTime * 1000)
    }
    
    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        // Pause the content for the SDK to play ads.
        pauseVideoPlayer() // Call your method, which pauses and hides your video player
        adAgent?.playStreamOnDemand(contentId: contentIdAd, streamId: urlString + "ads", options: [:], customParams: [:])
    }
    
    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
        // Resume the content since the SDK is done playing ads (at least for now).
        resumeVideoPlayer() // Call your method, which resumes and shows your video player
        adAgent?.stop()
    }
}

extension VODIMAViewController: IMAAdsLoaderDelegate {
    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        adsManager = adsLoadedData.adsManager
        adsManager.delegate = self
        adsManager.initialize(with: nil)
    }
    
    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        print("Error loading ads: " + (adErrorData.adError.message ?? ""))
        resumeVideoPlayer()  // Call your method, which resumes and shows your video player
    }
}
