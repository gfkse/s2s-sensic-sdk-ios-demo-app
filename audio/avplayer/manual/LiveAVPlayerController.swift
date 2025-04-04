import UIKit
import s2s_sdk_ios
import AVKit
import AVFoundation

class LiveAVPlayerController: AudioPlayerViewController {
    
    private let url = "https://npr-ice.streamguys1.com/live.mp3"
    private let configUrl = "https://demo-config.sensic.net/s2s-ios.json"
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private let contentIdDefault = "default"
    private var muteObservation: NSKeyValueObservation?
    var timeObserver: Any?
    
    private var playerVolume: Int?
    
    private var s2sAgent: S2SAgent?
    
    
    @IBAction func showChangeSpeedOptionView(_ sender: UIButton) {
        showChangeSpeedAlert()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBarTitle(title: "Live Audio")
        
        delegate = self
        
        setupAudioPlayer(from: url) // setup the Audio Player as you want
        setupButtonUI()
        setupAgent()
        
    }
    
    //MARK: - Setup Agent
    
    func setupAgent() {
        do {
            let config = S2SConfig(mediaId: mediaId, url: configUrl, optIn: optIn, crashReporting: true)
            s2sAgent = try S2SAgent(config: config)
            registerObserver()
            registerDidEnterBackgroundObserver()
            playerVolume = Int(AVAudioSession.sharedInstance().outputVolume * 100)
        } catch let error {
            print(error)
        }
    }
    
    func registerDidEnterBackgroundObserver() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc func appDidEnterBackground() {
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
        
        if (self.isMovingFromParent) {
            
            player.removeObserver(self, forKeyPath: "rate")
            player.removeObserver(self, forKeyPath: "volume")
            
            AVAudioSession.sharedInstance().removeObserver(self, forKeyPath: "outputVolume")
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "rate" {
            let rate = change![NSKeyValueChangeKey.newKey] as! Float
            if rate == 0 {
                s2sAgent?.stop()
            } else {
                if player.timeControlStatus == .playing {
                    s2sAgent?.stop()
                }
                let offset = player?.getOffset() ?? 0
                s2sAgent?.playStreamLive(contentId: contentIdDefault,
                                         streamStart: getStreamStart(),
                                         streamOffset: offset,
                                         streamId: url,
                                         options: ["volume": "\(playerVolume ?? 0)", "speed": "\(player.rate)"],
                                         customParams: [:])
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

extension LiveAVPlayerController: BaseViewControllerDelegate {
    func setPlayerRate(with value: Float?) {
        player.rate = value ?? 1.0
    }
}
