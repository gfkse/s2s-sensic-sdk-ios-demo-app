import UIKit
import s2s_sdk_ios
import AVKit
import AVFoundation

class LiveTimeShiftedExtensionViewController: BaseViewController {
    private let configUrl = "https://demo-config.sensic.net/s2s-ios.json"
    private let liveUrl = "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet weak var textField: UITextField!
    
    private var player: AVPlayer!
    private var playerViewController: AVPlayerViewController!
    private var playerExtension: AVPlayerLiveExtension?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBarTitle(title: "Live Video")
        createDatePicker(for: textField)
        
        delegate = self
        dateDelegate = self
        
        setupVideoPlayer()
        
        
        let config = S2SConfig(mediaId: mediaId, url: configUrl, optIn: optIn)
        
        let contentMetadata = ContentMetadata(customParams: [String: String]())
        contentMetadata.setStreamStart(streamStart: getStreamStart())
    
        playerExtension = AVPlayerLiveExtension(avPlayerController: self.playerViewController, config: config, contentMetadata: contentMetadata)
        
        //call setParameters() as soon as your player is switching over to different content. Otherwise, new content will be reported with parameters of the video played before.
        //playerExtension?.setParameters(contentMetadata)
        
    }
    
    //MARK: Videoplayer
    
    private func setupVideoPlayer() {
        player = AVPlayer(url: URL(string: liveUrl)!)
        playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.view.frame = playerView.bounds
        addChild(playerViewController)
        playerView.addSubview(playerViewController.view)
        playerViewController.view.backgroundColor = UIColor.clear
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
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

extension LiveTimeShiftedExtensionViewController: BaseViewControllerDelegate, BaseViewControllerDelegateDate {
    func setDate(with dateString: String) {
        textField.text = dateString
        let contentMetadata = ContentMetadata(customParams: [String: String]())
        contentMetadata.setStreamStart(streamStart: getStreamStart())
        playerExtension?.setParameters(contentMetadata: contentMetadata)
    }
    
    func setPlayerRate(with value: Float?) {
        player.rate = value ?? 1.0
    }
}
