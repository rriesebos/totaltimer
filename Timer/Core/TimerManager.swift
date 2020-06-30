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
import os.log

class TimerManager: ObservableObject, Identifiable {
    
    let id = UUID()
    var timerData: TimerData? = nil
    
    @Published var label: String = ""
    @Published var totalSeconds = 0
    @Published var color: UIColor
    
    @Published var timerLengthInSeconds = 0
    @Published var seconds = 0
    
    @Published var progress: Double = 0
    @Published var isPlaying = false
    
    @Published var isActive = true
    
    private var timer: Timer.TimerPublisher?
    private var cancellable: Cancellable? = nil
    
    private var notificationManager = NotificationManager()
    
    
    init(label: String, totalSeconds: Int, color: UIColor) {
        self.label = label
        self.totalSeconds = totalSeconds
        
        self.timerLengthInSeconds = totalSeconds
        self.seconds = totalSeconds
        
        self.color = color
    }
    
    init(timerData: TimerData) {
        self.timerData = timerData
        
        self.label = timerData.label ?? ""
        self.totalSeconds = Int(timerData.totalSeconds)
        
        self.timerLengthInSeconds = Int(timerData.totalSeconds)
        self.seconds = Int(timerData.totalSeconds)
        
        // TODO: convert color
        self.color = UIColor.random
    }
    
    func set(seconds: Int) {
        self.totalSeconds = seconds
        
        self.timerLengthInSeconds = seconds
        self.seconds = seconds
        
        self.progress = 0
    }
    
    func save(managedObjectContext: NSManagedObjectContext) {
        managedObjectContext.perform {
            self.timerData?.totalSeconds = Int64(self.totalSeconds)

            do {
                try managedObjectContext.save()
            } catch {
                os_log("%@", type: .error, error.localizedDescription)
            }
        }
    }
    
    func reset() {
        self.stopTimer()
        
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
        
        self.updateTimer()
    }
    
    func subtractTime(seconds: Int) {
        self.timerLengthInSeconds = max(self.timerLengthInSeconds - seconds, TimeHelper.minSeconds)
        self.seconds = max(self.seconds - seconds, TimeHelper.minSeconds)
        
        if self.seconds > 0 {
            self.notificationManager.setNotification(timerManager: self)
        }
        
        self.updateTimer()
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
        
        self.timer = Timer.publish(every: 1, tolerance: 0.1, on: .current, in: .common)
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
        
        self.notificationManager.removeNotification()
        
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
            // TODO: trigger alarm
            self.stopTimer()
        }
        
        if self.isPlaying {
            self.decrement()
        }
        
        guard self.timerLengthInSeconds > 0 else {
            self.progress = 1.0
            return
        }
            
        self.progress = 1.0 - Double(self.seconds) / Double(self.timerLengthInSeconds)
    }
}

// TODO: Remove
extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}