import UIKit
import s2s_sdk_ios
import AVKit
import AVFoundation

class AudioOnDemandExtensionAVPlayerController: AudioPlayerViewController {
    
    private let url = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
    private let configUrl = "https://demo-config.sensic.net/s2s-ios.json"
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    
    private var playerExtension: AVPlayerVODExtension?
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNavigationBarTitle(title: "Audio on Demand")
        delegate = self
        setupAudioPlayer(from: url)
        setupButtonUI()
        setupSliderUI()
        
        let config = S2SConfig(mediaId: mediaId, url: configUrl, optIn: optIn, crashReporting: true)
        let contentMetadata = ContentMetadata(customParams: ["cp1": "<your new cp1 value here>", "cp2": "<your new cp2 value here>"])
        self.playerExtension = AVPlayerVODExtension(avPlayer: player, config: config, contentMetadata: contentMetadata)
      
        //call setParameters() as soon as your player is switching over to different content. Otherwise, new content will be reported with parameters of the video played before.
        //playerExtension?.setParameters(contentMetadata)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

extension AudioOnDemandExtensionAVPlayerController: BaseViewControllerDelegate {
    func setPlayerRate(with value: Float?) {
        player.rate = value ?? 1.0
    }
}
