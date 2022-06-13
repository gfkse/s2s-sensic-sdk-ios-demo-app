import UIKit
import s2s_sdk_ios
import AVKit
import AVFoundation

class LiveExtensionViewController: BaseViewController {
    private let configUrl = "https://demo-config-preproduction.sensic.net/s2s-ios.json"
    private let liveUrl = "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    @IBOutlet weak var playerView: UIView!
    
    private var player: AVPlayer!
    private var playerViewController: AVPlayerViewController!
    private var playerExtension: AVPlayerLiveExtension?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBarTitle(title: "Live Video")
        
        delegate = self
        setupVideoPlayer()
        
        
        let config = S2SConfig(mediaId: mediaId, url: configUrl)
        playerExtension = AVPlayerLiveExtension(avPlayerController: self.playerViewController, config: config, contentId: "contentId", customParams: ["":""])
        
        //call setParameters() as soon as your player is switching over to different content. Otherwise, new content will be reported with parameters of the video played before.
        //playerExtension?.setParameters(contentId: "", customParams: ["":""])
        
    }
    
    //MARK: Videoplayer
    
    private func setupVideoPlayer() {
        player = AVPlayer(url: URL(string: liveUrl)!)
        playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.view.frame = playerView.bounds
        playerView.addSubview(playerViewController.view)
        playerViewController.view.backgroundColor = UIColor.clear
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if player.timeControlStatus == .playing {
            player.pause()
        }
        if self.isMovingFromParent {
            playerViewController.view.removeFromSuperview()
            playerViewController.removeFromParent()
            playerViewController.player = nil
            playerViewController = nil
        }
    }
    
    @IBAction func showChangeSpeedOptionView(_ sender: UIButton) {
        showChangeSpeedAlert()
    }
}

extension LiveExtensionViewController: BaseViewControllerDelegate {
    func setPlayerRate(with value: Float?) {
        player.rate = value ?? 1.0
    }
}
