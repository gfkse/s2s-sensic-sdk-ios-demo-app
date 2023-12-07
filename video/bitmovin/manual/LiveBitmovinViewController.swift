import UIKit
import BitmovinPlayer
import s2s_sdk_ios_bitmovin

@available(iOS 14.0, *)
class LiveBitmovinViewController: BaseViewController {

    private var player: Player!
    private var s2sAgent: S2SAgent?
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private let configUrl = "https://demo-config.sensic.net/s2s-ios.json"
    private var isSeeking = false
    
    deinit {
        s2sAgent?.stop()
        player?.destroy()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        // Define needed resources
        guard let streamUrl = URL(string: "https://mcdn.daserste.de/daserste/de/master.m3u8"),
            let posterUrl = URL(string: "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/poster.jpg") else {
                return
        }

        // Create player configuration
        let config = PlayerConfig()
        
        // Create player based on player configuration
        player = PlayerFactory.create(playerConfig: config)

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
    }
    
    func setupAgent() {
        do {
            let config = S2SConfig(mediaId: mediaId, url: configUrl, optIn: optIn, crashReporting: true)
            s2sAgent = try S2SAgent(config: config)
        } catch let error {
            print(error)
        }
    }
    
    private func getOffset() -> Int{
        return abs(Int(floor(player.timeShift * 1000)))
    }
}

@available(iOS 14.0, *)
extension LiveBitmovinViewController: PlayerListener {
    func onEvent(_ event: Event, player: Player) {
        //dump(event, name: "[Player Event]", maxDepth: 1)
    }
    
    func onPaused(_ event: PausedEvent, player: Player) {
        if !isSeeking {
            s2sAgent?.stop()
        }
    }
    
    func onPlaying(_ event: PlayingEvent, player: Player) {
        if !isSeeking {
            s2sAgent?.playStreamLive(contentId: mediaId, streamStart: "", streamOffset: getOffset(),
                                     streamId: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8",
                                     customParams: [:])
        }
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
