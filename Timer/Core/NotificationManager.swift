////  NotificationManager.swift
//  Timer
//
//  Created by R Riesebos on 30/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import Foundation
import SwiftUI
import UserNotifications
import os.log

struct NotificationManager {
    
    @State private var notificationID: String = UUID().uuidString

    func removeNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.notificationID])
    }

    func setNotification(timerManager: TimerManager) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                os_log("%@", type: .error, error.localizedDescription)
            }
        }
        
        self.removeNotification()
        
        let content = UNMutableNotificationContent()
        content.title = timerManager.label
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timerManager.seconds), repeats: false)

        self.notificationID = UUID().uuidString
        let request = UNNotificationRequest(identifier: self.notificationID, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
