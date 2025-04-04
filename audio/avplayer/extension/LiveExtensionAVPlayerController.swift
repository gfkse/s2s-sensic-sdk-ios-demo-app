import UIKit
import s2s_sdk_ios
import AVKit
import AVFoundation

class LiveExtensionAVPlayerController: AudioPlayerViewController {
    
    private let url = "https://npr-ice.streamguys1.com/live.mp3"
    private let configUrl = "https://demo-config.sensic.net/s2s-ios.json"
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private let contentIdDefault = "default"
    
    private var playerExtension: AVPlayerLiveExtension?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBarTitle(title: "Live Audio Extension")
        
        delegate = self
        
        setupAudioPlayer(from: url) // setup the Audio Player as you want
        setupButtonUI()
        
        let config = S2SConfig(mediaId: mediaId, url: configUrl, optIn: optIn, crashReporting: true)
        
        let contentMetadata = ContentMetadata(customParams: ["cp1": "<your new cp1 value here>", "cp2": "<your new cp2 value here>"])
        contentMetadata.setStreamStart(streamStart: getStreamStart())
    
        playerExtension = AVPlayerLiveExtension(avPlayer: player, config: config, contentMetadata: contentMetadata)
        
        //call setParameters() as soon as your player is switching over to different content. Otherwise, new content will be reported with parameters of the video played before.
        //playerExtension?.setParameters(contentMetadata)
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            player = nil
        }
    }
    
    @IBAction func showChangeSpeedOptionView(_ sender: UIButton) {
        showChangeSpeedAlert()
    }
}

extension LiveExtensionAVPlayerController: BaseViewControllerDelegate {
    func setPlayerRate(with value: Float?) {
        player.rate = value ?? 1.0
    }
}
