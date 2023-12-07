import Foundation
import UIKit
import BitmovinPlayer
import s2s_sdk_ios_bitmovin

@available(iOS 14.0, *)
class LiveAdsBitmovinExtensionViewController: BaseViewController {
    private let configUrl = "https://demo-config.sensic.net/s2s-ios.json"
    private let liveUrl = "https://mcdn.daserste.de/daserste/de/master.m3u8"
    private var player: Player!
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private var playerExtension: BitmovinPlayerExtension?
    
    let adTagVastSkippable = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dskippablelinear&correlator="
    
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
        let adSource1 = AdSource(tag: urlWithCorrelator(adTag: adTagVastSkippable), ofType: .ima)
        
        let preRoll = AdItem(adSources: [adSource1], atPosition: "pre")
        
        
        let adConfig = AdvertisingConfig(schedule: [preRoll])
        config.advertisingConfig = adConfig
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
        playerExtension?.activateAdSupport()

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
    
    
    func urlWithCorrelator(adTag: String) -> URL {
        return URL(string: String(format: "%@%d", adTag, Int(arc4random_uniform(100000))))!
    }
}
