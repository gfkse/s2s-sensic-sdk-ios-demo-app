
import UIKit
import BitmovinPlayer
import s2s_sdk_ios_bitmovin

@available(iOS 14.0, *)
class VoDAdsBitmovinViewController: BaseViewController {
    
    private var player: Player!
    private var s2sAgent: S2SAgent?
    private var adAgent: S2SAgent?
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private let configUrl = "https://demo-config.sensic.net/s2s-ios.json"
    private var isFirstPlay = true
    private var lastAdPosition: Int64 = 0
    private var lastContentPosition: Int64 = 0
    
    let adTagVastSkippable = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dskippablelinear&correlator="
    let adTagVast1 = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dlinear&correlator="
    let adTagVast2 = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/ad_rule_samples&ciu_szs=300x250&ad_rule=1&impl=s&gdfp_req=1&env=vp&output=vmap&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ar%3Dpostonly&cmsid=496&vid=short_onecue&correlator="
    
    deinit {
        if player.isAd {
            adAgent?.stop(streamPosition: Int64(self.player.currentTime * 1000))
        } else {
            s2sAgent?.stop(streamPosition: Int64(self.player.currentTime * 1000))
        }
        player?.destroy()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        // Define needed resources
        guard let streamUrl = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"),
            let posterUrl = URL(string: "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/poster.jpg") else {
                return
        }

        // Create player configuration
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
        player = PlayerFactory.createPlayer(playerConfig: config)

        // Create player view and pass the player instance to it
        let playerView = PlayerView(player: player, frame: .zero)

        // Listen to player events
        player.add(listener: self)

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
        
        setupAgent()
        setupAdAgent()
    }
    
    func setupAgent() {
        let streamPositionCallback: StreamPositionCallback = { [weak self] in
            guard let self = self else {
                return Int64(0)
            }
            print("Time callback: \(self.player.currentTime * 1000)")
            return Int64(self.player.currentTime * 1000) // we need to return milliseconds
        }
        do {
            let config = S2SConfig(mediaId: mediaId, url: configUrl, optIn: optIn, crashReporting: true)
            s2sAgent = try S2SAgent(config: config, streamPositionCallback: streamPositionCallback)
        } catch let error {
            print(error)
        }
    }
    
    func setupAdAgent() {
        let adPositionCallback: StreamPositionCallback = { [weak self] in
            guard let self = self else {
                return Int64(0)
            }
            print("Time callback: \(self.player.currentTime * 1000)")
            return Int64(self.player.currentTime * 1000) // we need to return milliseconds
        }
        do {
            let config = S2SConfig(mediaId: mediaId, url: configUrl, optIn: optIn, crashReporting: true)
            adAgent = try S2SAgent(config: config, streamPositionCallback: adPositionCallback)
        } catch let error {
            print(error)
        }
    }

    
    func urlWithCorrelator(adTag: String) -> URL {
        return URL(string: String(format: "%@%d", adTag, Int(arc4random_uniform(100000))))!
    }
}

@available(iOS 14.0, *)
extension VoDAdsBitmovinViewController: PlayerListener {
    func onEvent(_ event: Event, player: Player) {
        //dump(event, name: "[Player Event]", maxDepth: 1)
    }
    
    func onAdSkipped(_ event: AdSkippedEvent, player: Player) {
        adAgent?.stop(streamPosition: lastAdPosition)
    }
    
    func onAdStarted(_ event: AdStartedEvent, player: Player) {
        adAgent?.playStreamOnDemand(contentId: "ad", streamId: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8" + "ads" , options: ["":""], customParams: ["":""])
    }
    
    func onAdFinished(_ event: AdFinishedEvent, player: Player) {
        adAgent?.stop(streamPosition: lastAdPosition)
    }
    
    func onPaused(_ event: PausedEvent, player: Player) {
        if !isFirstPlay {
            s2sAgent?.stop(streamPosition: lastContentPosition)
        }
    }
    func onPlaying(_ event: PlayingEvent, player: Player) {
        if isFirstPlay != true {
            s2sAgent?.playStreamOnDemand(contentId: mediaId,
                                         streamId: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8",
                                         customParams: [:])
        }
        isFirstPlay = false
    }

    
    func onPlaybackFinished(_ event: PlaybackFinishedEvent, player: Player) {
        s2sAgent?.stop(streamPosition: lastContentPosition)
    }
    func onMuted(_ event: MutedEvent, player: Player) {
        s2sAgent?.volume(volume: "0")
    }
    func onUnmuted(_ event: UnmutedEvent, player: Player) {
        s2sAgent?.volume(volume: "\(player.volume)")
    }
    
    func onTimeChanged(_ event: TimeChangedEvent, player: Player) {
        if player.isAd {
            lastAdPosition = Int64(self.player.currentTime * 1000)
        } else {
            lastContentPosition = Int64(self.player.currentTime * 1000)
        }
    }
}
