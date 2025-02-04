import Foundation
import UIKit
import BitmovinPlayer
import s2s_sdk_ios_bitmovin

@available(iOS 14.0, *)
class LiveNoSeekBitmovinExtensionViewController: BaseViewController {
    private let configUrl = "https://demo-config.sensic.net/s2s-ios.json"
    private let liveUrl = "https://live-hls-web-aje.getaj.net/AJE/01.m3u8"
    private var player: Player!
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private var playerExtension: BitmovinPlayerExtension?

    
    deinit {
        player?.destroy()
        self.playerExtension = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        // Define needed resources
        guard let streamUrl = URL(string: liveUrl),
              let posterUrl = URL(string: "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/poster.jpg") else {
            return
        }
        
        let config = PlayerConfig()
        
        let uiConfig = BitmovinUserInterfaceConfig()
        uiConfig.hideFirstFrame = true
        config.styleConfig.userInterfaceConfig = uiConfig
        config.playbackConfig.isTimeShiftEnabled = false

        
        // Create player based on player configuration
        player = PlayerFactory.create(playerConfig: config)
        
        // Create player view and pass the player instance to it
        let playerView = PlayerView(player: player, frame: .zero)
        
        
        let s2sConfig = S2SConfig(mediaId: mediaId, url: configUrl, optIn: optIn, crashReporting: true)
        let contentMetadata = ContentMetadata(customParams: ["cp1": "<your new cp1 value here>", "cp2": "<your new cp2 value here>"])
        
        playerExtension = BitmovinPlayerExtension(player: player, config: s2sConfig, contentMetadata: contentMetadata)

        playerView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        playerView.frame = view.bounds
        
        view.addSubview(playerView)
        view.bringSubviewToFront(playerView)
        
        // Create HLSSource as an HLS stream is provided
        let sourceConfig = SourceConfig(url: streamUrl, type: .hls)
        
        // Set title and poster image
        sourceConfig.title = "Demo Stream"
        sourceConfig.sourceDescription = "Demo Stream"
        sourceConfig.posterSource = posterUrl
        player.load(sourceConfig: sourceConfig)
    }
}
