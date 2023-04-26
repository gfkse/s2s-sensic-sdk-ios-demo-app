import Foundation
import UIKit
import s2s_sdk_ios
import AVKit
import AVFoundation
import GoogleInteractiveMediaAds

class LiveIMAViewController: BaseLiveIMAViewController {
    
    private let urlString = "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private let configUrl = "https://demo-config.sensic.net/s2s-ios.json"
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
        
        setUpAdsLoader()
        
        registerDidBecomeActiveObserver()
        registerDidEnterBackgroundObserver()
        
        setupVideoPlayer(with: urlString)
        setupAgent()
        setupAdAgent()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if player.timeControlStatus == .playing {
            player.pause()
            
            if isPlayingAd {
                adAgent?.stop()
            }
        }
        
        
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
        do {
            agent = try S2SAgent(configUrl: configUrl, mediaId: mediaId, optIn: optIn)
            registerObservers()
            agent?.playStreamLive(contentId: contentIdDefault,
                                  streamStart: "",
                                  streamOffset: 0,
                                  streamId: urlString,
                                  options: ["volume": "\(playerVolume ?? 0)", "speed": "\(player.rate)"],
                                  customParams: [:])
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
            adAgent = try S2SAgent(configUrl: configUrl, mediaId: mediaId, optIn: optIn, streamPositionCallback: adPositionCallback)
        } catch let error {
            print(error)
        }
    }
    
    @objc override func didBecomeActive() {
        super.didBecomeActive()
        if isPlayingAd {
            adAgent?.playStreamOnDemand(contentId: contentIdAd, streamId: urlString + "ads", customParams: [:])
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
                if player.currentTime().seconds != 0.0  && !isPlayingAd {
                    agent?.stop()
                }
            } else {
                if player.timeControlStatus == .playing {
                    agent?.stop()
                }
                if !isPlayingAd {
                    agent?.playStreamLive(contentId: contentIdDefault,
                                          streamStart: "",
                                          streamOffset: 0,
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

extension LiveIMAViewController: IMAAdsLoaderDelegate {
    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        streamManager = adsLoadedData.streamManager
        if let streamManager = streamManager {
            streamManager.delegate = self
            streamManager.initialize(with: nil)
        }
    }
    
    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        print("Error loading ads: " + (adErrorData.adError.message ?? ""))
    }
}

extension LiveIMAViewController: IMAStreamManagerDelegate {
    func streamManager(_ streamManager: IMAStreamManager, didReceive event: IMAAdEvent) {
        
        if event.type == IMAAdEventType.AD_PERIOD_STARTED {
            isPlayingAd = true
            agent?.stop()
            adAgent?.playStreamOnDemand(contentId: contentIdAd, streamId: urlString + "ads", customParams: [:])
        }
        
        if event.type == IMAAdEventType.AD_PERIOD_ENDED {
            agent?.playStreamLive(contentId: contentIdDefault,
                                  streamStart: "",
                                  streamOffset: 0,
                                  streamId: urlString,
                                  options: ["volume": "\(playerVolume ?? 0)", "speed": "\(player.rate)"],
                                  customParams: [:])
            isPlayingAd = false
        }
        
        if event.type == IMAAdEventType.PAUSE {
            adAgent?.stop()
        }
        
        if event.type == IMAAdEventType.COMPLETE {
            adAgent?.stop()
            adCurrentPosition = 0
        }
        
        // IMAAdEventType.STARTED
        if event.type.rawValue == 19 {
            adAgent?.playStreamOnDemand(contentId: contentIdAd, streamId: urlString + "ads", customParams: [:])
            isPlayingAd = true
        }
        
    }
    
    func streamManager(_ streamManager: IMAStreamManager, didReceive error: IMAAdError) {
        print("StreamManager error: \(error.message)")
    }
    
    func streamManager(_ streamManager: IMAStreamManager, adDidProgressToTime time: TimeInterval, adDuration: TimeInterval, adPosition: Int, totalAds: Int, adBreakDuration: TimeInterval, adPeriodDuration: TimeInterval) {
        adCurrentPosition = Int64(time * 1000)
    }
}
