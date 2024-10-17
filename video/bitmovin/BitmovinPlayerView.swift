//
//  BitmovinPlayerView.swift
//  Demo-App
//
//  Created by Kornazov, Kristiyan (GfK) on 15.10.24.
//

import Foundation
import UIKit
import BitmovinPlayer
class PlayerControlView: UIView {
    // Properties
    var rewindTime: Double = 10
    var forwardTime: Double = 10
    
    var player: Player?
    
    // Buttons
    private let rewindButton = UIButton(type: .system)
    private let fastForwardButton = UIButton(type: .system)
    
    // Initialization
    init(player: Player, frame: CGRect) {
        self.player = player
        super.init(frame: frame)
        setupButtons()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupButtons() {
        // Rewind button
        rewindButton.setTitle("⏪", for: .normal)
        rewindButton.frame = CGRect(x: 20, y: self.frame.height - 50, width: 50, height: 50)
        rewindButton.addTarget(self, action: #selector(rewind), for: .touchUpInside)
        self.addSubview(rewindButton)
        
        // Fast forward button
        fastForwardButton.setTitle("⏩", for: .normal)
        fastForwardButton.frame = CGRect(x: 100, y: self.frame.height - 50, width: 50, height: 50)
        fastForwardButton.addTarget(self, action: #selector(fastForward), for: .touchUpInside)
        self.addSubview(fastForwardButton)
    }
    
    @objc func rewind() {
        if let currentTime = player?.currentTime {
            let newTime = max(currentTime - rewindTime, 0) // Ensure time doesn't go negative
            player?.seek(time: newTime)
        }
    }
    
    @objc func fastForward() {
        if let currentTime = player?.currentTime, let duration = player?.duration {
            let newTime = min(currentTime + forwardTime, duration) // Ensure time doesn't exceed video duration
            player?.seek(time: newTime)
        }
    }
}
