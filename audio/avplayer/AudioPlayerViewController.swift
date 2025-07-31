import UIKit
import AVFoundation
import MediaPlayer

class AudioPlayerViewController: BaseViewController {
    var player: AVPlayer!
    var playButton: UIButton?
    var timer: Any?
    var playbackSlider: UISlider?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupRemoteTransportControls()
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
        }
    }
    
    func setupAudioPlayer(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        timer = player?.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 600), queue: DispatchQueue.main) { [weak self] time in
            guard let self = self, let slider = self.playbackSlider else { return }
            slider.value = Float(CMTimeGetSeconds(time))
        }
    }
    
    func setupButtonUI() {
        playButton = UIButton(type: .system)
        playButton?.frame = CGRect(x: 50, y: 100, width: 150, height: 45)
        playButton?.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        playButton?.backgroundColor = UIColor.lightGray
        playButton?.setTitle("Play", for: .normal)
        playButton?.tintColor = UIColor.black
        playButton?.addTarget(self, action: #selector(playButtonTapped(_:)), for: .touchUpInside)
        view.addSubview(playButton!)
    }
    
    func setupSliderUI() {
        // Add playback slider
        playbackSlider = UISlider(frame: CGRect(x: 10, y: 300, width: 300, height: 20))
        playbackSlider?.center = CGPoint(x: view.bounds.midX, y: view.bounds.midY + 50)
        playbackSlider?.minimumValue = 0
        
        if let duration = player?.currentItem?.asset.duration {
            let seconds = CMTimeGetSeconds(duration)
            playbackSlider?.maximumValue = Float(seconds)
        }
        
        playbackSlider?.isContinuous = true
        playbackSlider?.tintColor = UIColor.green
        
        playbackSlider?.addTarget(self, action: #selector(sliderTouchBegan(_:)), for: .touchDown)
        playbackSlider?.addTarget(self, action: #selector(sliderTouchEnded(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        
        view.addSubview(playbackSlider!)
    }
    
    @objc func sliderTouchBegan(_ sender: UISlider) {
        player?.pause()
    }
    
    // Called when user releases the slider
    @objc func sliderTouchEnded(_ sender: UISlider) {
        let targetTime =  CMTime(seconds: Double(sender.value), preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: targetTime)
        player?.play()
    }
    
    @objc func playbackSliderValueChanged(_ playbackSlider: UISlider) {
        let seconds = Int64(playbackSlider.value)
        let targetTime = CMTimeMake(value: seconds, timescale: 1)
        player?.seek(to: targetTime)
        if player?.rate == 0 {
            player?.play()
        } else {
            player.pause()
        }
    }
    
    @objc func playButtonTapped(_ sender: UIButton) {
        if player?.rate == 0 {
            player?.play()
            playButton?.setTitle("Pause", for: .normal)
        } else {
            player?.pause()
            playButton?.setTitle("Play", for: .normal)
        }
        updateNowPlayingInfo()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let timer = timer {
            player?.removeTimeObserver(timer)
        }
    }
    
    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.player?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.player?.pause()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            guard let player = self?.player else { return .commandFailed }
            player.rate == 0.0 ? player.play() : player.pause()
            return .success
        }
    }
    
    func updateNowPlayingInfo() {
        guard let currentItem = player?.currentItem else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = "Test Audio Stream"
        
        let duration = currentItem.asset.duration.seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player?.currentTime().seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player?.rate
        
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
