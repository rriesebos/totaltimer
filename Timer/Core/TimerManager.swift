////  TimerManager.swift
//  Timer
//
//  Created by R Riesebos on 28/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData
import Combine
import AVFoundation
import os.log

class TimerManager: ObservableObject, Identifiable, Hashable {
    
    let id = UUID()
    var timerData: TimerData? = nil
    
    @Published var label: String = ""
    @Published var totalSeconds = 0
    @Published var color: UIColor
    @Published var alarmSoundName: String
    
    @Published var timerLengthInSeconds = 0
    @Published var seconds = 0
    
    @Published var progress: Double = 0
    @Published var isPlaying = false
    
    @Published var isActive = true
    
    private var timer: Timer.TimerPublisher?
    private var cancellable: Cancellable? = nil
    
    private var notificationManager = NotificationManager()
    
    
    init(label: String, totalSeconds: Int, color: UIColor, alarmSoundName: String = "alarm") {
        self.label = label
        self.totalSeconds = totalSeconds
        
        self.timerLengthInSeconds = totalSeconds
        self.seconds = totalSeconds
        
        self.color = color
        self.alarmSoundName = alarmSoundName
    }
    
    init(timerData: TimerData) {
        self.timerData = timerData
        
        self.label = timerData.label ?? ""
        self.totalSeconds = Int(timerData.totalSeconds)
        
        self.timerLengthInSeconds = Int(timerData.totalSeconds)
        self.seconds = Int(timerData.totalSeconds)
        
        self.color = timerData.color as! UIColor
        self.alarmSoundName = timerData.alarmSoundName ?? Sound.defaultAlarmSound.name
    }
    
    func set(seconds: Int) {
        self.totalSeconds = seconds
        
        self.timerLengthInSeconds = seconds
        self.seconds = seconds
        
        self.progress = 0
    }
    
    func save(managedObjectContext: NSManagedObjectContext) {
        managedObjectContext.perform {
            self.timerData?.label = self.label
            self.timerData?.totalSeconds = Int64(self.totalSeconds)
            self.timerData?.color = self.color
            self.timerData?.alarmSoundName = self.alarmSoundName

            do {
                try managedObjectContext.save()
            } catch {
                os_log("%@", type: .error, error.localizedDescription)
            }
        }
    }
    
    func reset() {
        self.stopTimer()
        
        self.notificationManager.reset()
        
        self.timerLengthInSeconds = self.totalSeconds
        self.seconds = self.totalSeconds
        
        self.progress = 0
        
        self.updateTimer()
    }
    
    func setTime(seconds: Int) {
        self.seconds = max(min(seconds, TimeHelper.maxSeconds), TimeHelper.minSeconds)
        
        self.updateTimer()
    }
    
    func addTime(seconds: Int) {
        self.timerLengthInSeconds = min(self.timerLengthInSeconds + seconds, TimeHelper.maxSeconds)
        self.seconds = min(self.seconds + seconds, TimeHelper.maxSeconds)
        
        self.notificationManager.setNotification(timerManager: self)
        
        self.updateProgress()
    }
    
    func subtractTime(seconds: Int) {
        self.timerLengthInSeconds = max(self.timerLengthInSeconds - seconds, TimeHelper.minSeconds)
        self.seconds = max(self.seconds - seconds, TimeHelper.minSeconds)
        
        if self.seconds > 0 {
            self.notificationManager.setNotification(timerManager: self)
        } else {
            self.notificationManager.playSound(resourceName: self.alarmSoundName)
        }
        
        self.updateProgress()
    }
    
    func decrement() {
        self.seconds -= 1
    }
    
    func startTimer() {
        guard self.totalSeconds > 0 else {
            return
        }
        
        if self.seconds == 0 {
            self.reset()
        }
        
        self.timer = Timer.publish(every: 1, tolerance: 0.1, on: .main, in: .common)
        self.cancellable = self.timer?.autoconnect().sink { _ in
            self.updateTimer()
        }
        
        self.notificationManager.setNotification(timerManager: self)
        
        self.isPlaying = true
    }
    
    func stopTimer() {
        guard self.totalSeconds > 0 else {
            return
        }
        
        self.cancellable?.cancel()
        
        // Remove notification (and alarm timer) if timer is paused
        if self.seconds > 0 {
            self.notificationManager.removeNotification()
        }
        
        self.isPlaying = false
    }
    
    func updateTimer() {
        guard self.isActive else {
            return
        }
        
        guard self.totalSeconds > 0 else {
            self.progress = 0
            return
        }
        
        if self.seconds <= 0 {
            self.stopTimer()
        }
        
        if self.isPlaying {
            self.decrement()
        }
        
        self.updateProgress()
    }
    
    private func updateProgress() {
        guard self.timerLengthInSeconds > 0 else {
            self.progress = 1.0
            return
        }
            
        self.progress = 1.0 - Double(self.seconds) / Double(self.timerLengthInSeconds)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    static func == (lhs: TimerManager, rhs: TimerManager) -> Bool {
        return lhs.id == rhs.id
    }
}
