import Foundation
import UIKit
import BitmovinPlayer
import s2s_sdk_ios

@available(iOS 14.0, *)
class VoDAdsBitmovinExtensionViewController: BaseViewController {
    private let configUrl = "https://demo-config.sensic.net/s2s-ios.json"
    private let vodUrl = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
    private var player: Player!
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private var playerExtension: BitmovinPlayerExtension?
    
    let adTagVastSkippable = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dskippablelinear&correlator="
    let adTagVast1 = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
    let adTagVast2 = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpostonly&cmsid=496&vid=short_onecue&correlator="
    
    deinit {
        player?.destroy()
        self.playerExtension = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        // Define needed resources
        guard let streamUrl = URL(string: vodUrl),
              let posterUrl = URL(string: "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/poster.jpg") else {
            return
        }
        
        let config = PlayerConfig()
        
        let uiConfig = BitmovinUserInterfaceConfig()
        uiConfig.hideFirstFrame = true
        config.styleConfig.userInterfaceConfig = uiConfig

        // Create Advertising configuration
        let adSource1 = AdSource(tag: urlWithCorrelator(adTag: adTagVastSkippable), ofType: .ima)
        let adSource2 = AdSource(tag: urlWithCorrelator(adTag: adTagVast1), ofType: .ima)
        let adSource3 = AdSource(tag: urlWithCorrelator(adTag: adTagVast2), ofType: .ima)
        
        let preRoll = AdItem(adSources: [adSource1], atPosition: "pre")
        let midRoll = AdItem(adSources: [adSource2], atPosition: "20%")
        let postRoll = AdItem(adSources: [adSource3], atPosition: "post")
        
        let adConfig = AdvertisingConfig(schedule: [preRoll, midRoll, postRoll])
        config.advertisingConfig = adConfig
        
        // Create player based on player configuration
        player = PlayerFactory.create(playerConfig: config)
        
        // Create player view and pass the player instance to it
        let playerView = PlayerView(player: player, frame: .zero)
        
        
        let s2sConfig = S2SConfig(mediaId: mediaId, url: configUrl, optIn: optIn)
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
