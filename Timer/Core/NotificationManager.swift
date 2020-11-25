////  NotificationManager.swift
//  Timer
//
//  Created by R Riesebos on 30/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import Foundation
import UserNotifications
import AVFoundation
import SwiftUI
import os.log

var audioPlayer: AVAudioPlayer?

class NotificationManager {
    
    // MARK: Properties
    private var notificationID: String = UUID().uuidString
    private var alarmTimer: Timer?
    
    private var bgTaskID: UIBackgroundTaskIdentifier?
    
    // Max time a background task is allowed to run in seconds
    private let maxBackgroundTime = 30
    
    
    // MARK: Methods
    func removeNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.notificationID])
        
        self.stopAlarmTimer()
    }

    func setNotification(timer: TimerData) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                os_log("%@", type: .error, error.localizedDescription)
            }
        }
        
        // Remove previous notification if it is overwritten
        self.removeNotification()
        
        let content = UNMutableNotificationContent()
        content.title = "\(timer.label) is ready!"
        content.userInfo = ["TIMER_MANAGER_ID": timer.id.uuidString]
        content.categoryIdentifier = "ALARM"
        
        // Attach sound to notification if a background task is not possible
        if timer.seconds >= self.maxBackgroundTime {
            content.sound = UNNotificationSound(named: UNNotificationSoundName("\(timer.alarmSoundName).mp3"))
        }

        // Do not set notification if the timer has already ended
        if timer.seconds <= 0 {
            return
        }
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timer.seconds), repeats: false)

        self.notificationID = UUID().uuidString
        let request = UNNotificationRequest(identifier: self.notificationID, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
        
        self.startAlarmTimer(timer: timer)
    }
    
    private func stopAlarmTimer() {
        self.alarmTimer?.invalidate()
        self.alarmTimer = nil
        
        self.endBackgroundTask()
    }
    
    private func startAlarmTimer(timer: TimerData) {
        guard self.alarmTimer == nil else { return }
        
        self.endBackgroundTask()
        
        // Start background task if it is finished in time
        if timer.seconds < self.maxBackgroundTime {
            self.bgTaskID = UIApplication.shared.beginBackgroundTask(expirationHandler: {
                self.endBackgroundTask()
            })
        }
        
        self.alarmTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timer.seconds), repeats: false) { _ in
            self.playSound(resourceName: timer.alarmSoundName)
        }
    }
    
    private func stopSound() {
        audioPlayer?.stop()
    }
    
    func playSound(resourceName: String) {
        let path = Bundle.main.path(forResource: resourceName, ofType: "mp3")!
        let url = URL(fileURLWithPath: path)
        
        // Start playing sound on a background queue
        DispatchQueue.global(qos: .background).async {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                
                audioPlayer?.numberOfLoops = -1
                audioPlayer?.play()
            } catch {
                os_log("%@", type: .error, error.localizedDescription)
            }
        }
    }
    
    func reset() {
        self.removeNotification()
        self.stopSound()
    }
    
    private func endBackgroundTask() {
        if let bgTaskID = self.bgTaskID {
            UIApplication.shared.endBackgroundTask(bgTaskID)
        }
        
        self.bgTaskID = nil
    }
}
