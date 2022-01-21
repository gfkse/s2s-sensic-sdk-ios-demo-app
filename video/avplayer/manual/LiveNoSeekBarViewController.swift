import UIKit
import s2s_sdk_ios
import AVKit
import AVFoundation

class LiveNoSeekBarViewController: BaseViewController {

    @IBOutlet private weak var playerView: UIView!
    
    private let url = "https://d2e1asnsl7br7b.cloudfront.net/7782e205e72f43aeb4a48ec97f66ebbe/index_1.m3u8"
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private var muteObservation: NSKeyValueObservation?
    
    private var playerVolume: Int?
    private var player: AVPlayer!
    private var playerViewController: AVPlayerViewController!
    
    private var s2sAgent: S2SAgent?
    
    @IBAction func showChangeSpeedOptionView(_ sender: UIButton) {
        showChangeSpeedAlert()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBarTitle(title: "Live No Seek")
        delegate = self
        
        setupVideoPlayer() // setup the Video Player as you want
        setupAgent()
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
        do {
            s2sAgent = try S2SAgent(configUrl: "https://demo-config-preproduction.sensic.net/s2s-ios.json", mediaId: mediaId)
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
                s2sAgent?.stop()
            } else {
                if player.timeControlStatus == .playing {
                    s2sAgent?.stop()
                }
                s2sAgent?.playStreamLive(contentId: mediaId,
                                         streamStart: "",
                                         streamOffset: 0,
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

extension LiveNoSeekBarViewController: BaseViewControllerDelegate {
    func setPlayerRate(with value: Float?) {
        player.rate = value ?? 1.0
    }
}
