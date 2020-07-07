////  NotificationManager.swift
//  Timer
//
//  Created by R Riesebos on 30/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import Foundation
import UserNotifications
import AVFoundation
import os.log

var audioPlayer: AVAudioPlayer?

class NotificationManager {
    
    // MARK: Properties
    private var notificationID: String = UUID().uuidString
    private var alarmTimer: Timer?
    
    
    // MARK: Methods
    func removeNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.notificationID])
        
        self.stopAlarmTimer()
    }

    func setNotification(timerManager: TimerManager) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                os_log("%@", type: .error, error.localizedDescription)
            }
        }
        
        // Remove previous notification if it is overwritten
        self.removeNotification()
        
        let content = UNMutableNotificationContent()
        content.title = "\(timerManager.label) is ready!"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timerManager.seconds), repeats: false)

        self.notificationID = UUID().uuidString
        let request = UNNotificationRequest(identifier: self.notificationID, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
        
        self.startAlarmTimer(timerManager: timerManager)
    }
    
    private func stopAlarmTimer() {
        self.alarmTimer?.invalidate()
        self.alarmTimer = nil
    }
    
    private func startAlarmTimer(timerManager: TimerManager) {
        guard self.alarmTimer == nil else { return }
        
        self.alarmTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timerManager.seconds), repeats: false) { _ in
            self.playSound(resourceName: timerManager.alarmSoundName)
        }
    }
    
    private func stopSound() {
        audioPlayer?.stop()
    }
    
    func playSound(resourceName: String) {
        let path = Bundle.main.path(forResource: resourceName, ofType: "mp3")!
        let url = URL(fileURLWithPath: path)

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
        } catch {
            os_log("%@", type: .error, error.localizedDescription)
        }
    }
    
    func reset() {
        self.removeNotification()
        self.stopSound()
    }
}
