import UIKit
import s2s_sdk_ios
import AVKit
import AVFoundation

class LiveNoSeekBarExtensionViewController: BaseViewController {
    
    private let liveUrl = "https://d2e1asnsl7br7b.cloudfront.net/7782e205e72f43aeb4a48ec97f66ebbe/index_1.m3u8"
    
    @IBOutlet weak var playerView: UIView!
    
    private var player: AVPlayer!
    private var playerViewController: AVPlayerViewController!
    private weak var playerExtension: AVPlayerLiveS2SExtension?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBarTitle(title: "Live Video (No SeekBar)")
        
        delegate = self
        setupVideoPlayer()
        
        //Important: Do not hold a strong reference to the extension
        playerExtension = AVPlayerLiveS2SExtension(avPlayerController: self.playerViewController, contentId: "contentId", customParams: ["":""])
        //If you want to change the parameters, please evoke the line below
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
    }
    
    @IBAction func showChangeSpeedOptionView(_ sender: UIButton) {
        showChangeSpeedAlert()
    }
}

extension LiveNoSeekBarExtensionViewController: BaseViewControllerDelegate {
    func setPlayerRate(with value: Float?) {
        player.rate = value ?? 1.0
    }
}
