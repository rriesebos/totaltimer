////  TimerData+CoreDataClass.swift
//  Timer
//
//  Created by R Riesebos on 25/11/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//
//

import Foundation
import SwiftUI
import CoreData
import Combine
import AVFoundation
import os.log

@objc(TimerData)
public class TimerData: NSManagedObject, Identifiable {

    // MARK: Properties
    public let id = UUID()
    
    @Published var timerLengthInSeconds = 0
    @Published var seconds = 0
    
    @Published var progress: Double = 0
    @Published var isPlaying = false
    
    @Published var isActive = true
    
    private var timer: Timer.TimerPublisher?
    private var cancellable: Cancellable? = nil
    
    private var notificationManager = NotificationManager()
    
    
    // MARK: Initializer
    override public init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
        
        self.timerLengthInSeconds = Int(totalSeconds)
        self.seconds = Int(totalSeconds)
    }
    
    // MARK: Methods
    func set(seconds: Int) {
        self.totalSeconds = Int64(seconds)
        
        self.timerLengthInSeconds = seconds
        self.seconds = seconds
        
        self.progress = 0
        
        self.objectWillChange.send()
    }
    
    func save(managedObjectContext: NSManagedObjectContext) {
        managedObjectContext.perform {
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
        
        self.timerLengthInSeconds = Int(self.totalSeconds)
        self.seconds = Int(self.totalSeconds)
        
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

        self.notificationManager.setNotification(timer: self)

        self.updateProgress()
    }

    func subtractTime(seconds: Int) {
        self.timerLengthInSeconds = max(self.timerLengthInSeconds - seconds, TimeHelper.minSeconds)
        self.seconds = max(self.seconds - seconds, TimeHelper.minSeconds)

        if self.seconds > 0 {
            self.notificationManager.setNotification(timer: self)
        } else {
            // Remove pending notification and play sound
            self.notificationManager.removeNotification()
            self.notificationManager.playSound(resourceName: self.alarmSoundName)
        }

        self.updateProgress()
    }

    func decrement() {
        self.seconds -= 1
        self.objectWillChange.send()
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

        self.notificationManager.setNotification(timer: self)

        self.isPlaying = true
        
        self.objectWillChange.send()
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
        
        self.objectWillChange.send()
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
        self.objectWillChange.send()
        
        guard self.timerLengthInSeconds > 0 else {
            self.progress = 1.0
            return
        }
            
        self.progress = 1.0 - Double(self.seconds) / Double(self.timerLengthInSeconds)
    }
    
    func setNotification() {
        self.notificationManager.setNotification(timer: self)
    }
    
    func removeNotification() {
        self.notificationManager.removeNotification()
    }
    
    static func == (lhs: TimerData, rhs: TimerData) -> Bool {
        return lhs.id == rhs.id
    }
}
