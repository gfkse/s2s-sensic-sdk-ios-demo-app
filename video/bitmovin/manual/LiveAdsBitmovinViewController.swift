import UIKit
import s2s_sdk_ios_bitmovin
import BitmovinPlayer

@available(iOS 14.0, *)
class LiveAdsBitmovinViewController: BaseViewController {
    
    private var player: Player!
    private var s2sAgent: S2SAgent?
    private var adAgent: S2SAgent?
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private let configUrl = "https://demo-config.sensic.net/s2s-ios.json"
    private var lastAdPosition: Int64 = 0
    private var isFirstPlay: Bool = true
    let adTagVastSkippable = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dskippablelinear&correlator="
    
    private var isSeeking = false
    
    deinit {
        if player.isAd {
            adAgent?.stop(streamPosition: Int64(self.player.currentTime * 1000))
        } else {
            s2sAgent?.stop()
        }
        player?.destroy()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        // Define needed resources
        guard let streamUrl = URL(string: "https://ireplay.tv/test/blender.m3u8"),
              let posterUrl = URL(string: "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/poster.jpg") else {
            return
        }
        
        // Create player configuration
        let config = PlayerConfig()
        
        // Create Advertising configuration
        let adSource1 = AdSource(tag: urlWithCorrelator(adTag: adTagVastSkippable), ofType: .ima)
        
        let preRoll = AdItem(adSources: [adSource1], atPosition: "pre")
        
        
        let adConfig = AdvertisingConfig(schedule: [preRoll])
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
        do {
            let config = S2SConfig(mediaId: mediaId, url: configUrl, optIn: optIn, crashReporting: true)
            s2sAgent = try S2SAgent(config: config)
        } catch let error {
            print(error)
        }
    }
    
    func setupAdAgent() {
        let adPositionCallback: StreamPositionCallback = { [weak self] in
            guard let self = self else {
                return Int64(0)
            }
            print("Time callback: \(lastAdPosition)")
            return lastAdPosition // we need to return milliseconds
        }
        do {
            let config = S2SConfig(mediaId: mediaId, url: configUrl, optIn: optIn, crashReporting: true)
            adAgent = try S2SAgent(config: config, streamPositionCallback: adPositionCallback)
        } catch let error {
            print(error)
        }
    }
    
    private func getOffset() -> Int{
        return abs(Int(floor(player.timeShift * 1000)))
    }
    
    func urlWithCorrelator(adTag: String) -> URL {
        return URL(string: String(format: "%@%d", adTag, Int(arc4random_uniform(100000))))!
    }
}

@available(iOS 14.0, *)
extension LiveAdsBitmovinViewController: PlayerListener {
    func onEvent(_ event: Event, player: Player) {
        //dump(event, name: "[Player Event]", maxDepth: 1)
    }
    func onTimeChanged(_ event: TimeChangedEvent, player: Player) {
        if player.isAd {
            self.lastAdPosition = Int64(event.currentTime * 1000)
        }
    }
    func onAdSkipped(_ event: AdSkippedEvent, player: Player) {
        adAgent?.stop(streamPosition: lastAdPosition)
    }
    
    
    func onAdStarted(_ event: AdStartedEvent, player: Player) {
        adAgent?.playStreamOnDemand(contentId: "ad", streamId: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8" + "ads", options: ["":""], customParams: ["":""])
    }
    
    func onAdFinished(_ event: AdFinishedEvent, player: Player) {
        adAgent?.stop(streamPosition: lastAdPosition)
    }
    
    func onPaused(_ event: PausedEvent, player: Player) {
        if !isFirstPlay && !isSeeking {
            s2sAgent?.stop()
        }
    }
    func onPlaying(_ event: PlayingEvent, player: Player) {
        if !isFirstPlay && !isSeeking {
            s2sAgent?.playStreamLive(contentId: mediaId, streamStart: "", streamOffset: getOffset(),
                                     streamId: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8",
                                     customParams: [:])
        }
        isFirstPlay = false
    }
    
    func onPlaybackFinished(_ event: PlaybackFinishedEvent, player: Player) {
        s2sAgent?.stop()
    }
    func onMuted(_ event: MutedEvent, player: Player) {
        s2sAgent?.volume(volume: "0")
    }
    func onUnmuted(_ event: UnmutedEvent, player: Player) {
        s2sAgent?.volume(volume: "\(player.volume)")
    }
    
    func onTimeShift(_ event: TimeShiftEvent, player: Player) {
        if player.isPlaying && !isSeeking {
            isSeeking = true
            s2sAgent?.stop()
        }
    }
    
    func onTimeShifted(_ event: TimeShiftedEvent, player: Player) {
        if isSeeking {
            s2sAgent?.playStreamLive(contentId: mediaId, streamStart: "", streamOffset: getOffset(),
                                         streamId: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8",
                                         customParams: [:])
            isSeeking = false
        }
    }
}
