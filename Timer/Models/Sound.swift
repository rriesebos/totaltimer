////  Sound.swift
//  Timer
//
//  Created by R Riesebos on 07/07/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import Foundation
import AVFoundation
import os.log

class Sound: Hashable {
    
    // MARK: Properties
    // Array of all available sounds
    static let alarmSounds = [Sound(name: "alarm", displayName: "Default"),
                              Sound(name: "alarm2")]
    
    var audioPlayer: AVAudioPlayer?
    
    // Name has to equal the file name
    var name: String
    var displayName: String
    
    
    // MARK: Initializer
    init(name: String, displayName: String? = nil) {
        self.name = name
        
        // Set the display name to the file name with the first letter capitalized if no displayName is provided
        if let displayName = displayName {
            self.displayName = displayName
        } else {
            self.displayName = name.prefix(1).capitalized + name.dropFirst()
        }
        
        guard let path = Bundle.main.path(forResource: self.name, ofType: "mp3") else { return }
        let url = URL(fileURLWithPath: path)

        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
        } catch {
            os_log("%@", type: .error, error.localizedDescription)
        }
    }
    
    // MARK: Methods
    func play() {
        audioPlayer?.numberOfLoops = -1
        audioPlayer?.play()
    }
    
    func stop() {
        self.audioPlayer?.stop()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.name)
    }
    
    static func == (lhs: Sound, rhs: Sound) -> Bool {
        return lhs.name == rhs.name && lhs.audioPlayer == rhs.audioPlayer
    }
}
