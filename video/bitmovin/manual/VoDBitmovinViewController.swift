import UIKit
import BitmovinPlayer
import s2s_sdk_ios_bitmovin

@available(iOS 14.0, *)
class VoDBitmovinViewController: BaseViewController {
    
    private var player: Player!
    private var s2sAgent: S2SAgent?
    private let mediaId = "s2sdemomediaid_ssa_ios_new"
    private let configUrl = "https://demo-config.sensic.net/s2s-ios.json"
    
    deinit {
        s2sAgent?.stop(streamPosition: Int64(self.player.currentTime * 1000))
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
}

@available(iOS 14.0, *)
extension VoDBitmovinViewController: PlayerListener {
    func onEvent(_ event: Event, player: Player) {
        //dump(event, name: "[Player Event]", maxDepth: 1)
    }
    
    func onPaused(_ event: PausedEvent, player: Player) {
        s2sAgent?.stop()
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
    
    func onPlaying(_ event: PlayingEvent, player: Player) {
        s2sAgent?.playStreamOnDemand(contentId: mediaId,
                                     streamId: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8",
                                     customParams: [:])
    }
}
