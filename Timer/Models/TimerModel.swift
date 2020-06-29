////  TimerModel.swift
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

class TimerModel: ObservableObject {
    
    var timerData: TimerData? = nil
    
    @Published var label: String = ""
    @Published var totalSeconds: Int = 0
    @Published var color: UIColor
    
    @Published var timerLengthInSeconds = 0
    @Published var time = Time()
    
    @Published var timer = Timer.publish(every: 1, on: .main, in: .common)
    private var cancellable: Cancellable? = nil
    
    var seconds: Int {
        return self.time.seconds
    }
    
    
    init(label: String, totalSeconds: Int, color: UIColor) {
        self.label = label
        self.totalSeconds = totalSeconds
        self.color = color
    }
    
    init(timerData: TimerData) {
        self.timerData = timerData
        
        self.label = timerData.label ?? ""
        self.totalSeconds = Int(timerData.totalSeconds)
        
        self.timerLengthInSeconds = Int(timerData.totalSeconds)
        self.time = Time(seconds: Int(timerData.totalSeconds))
        
        // TODO: convert color
        self.color = UIColor.blue
    }
    
    func set(time: Time) {
        self.totalSeconds = time.seconds
        
        self.timerLengthInSeconds = time.seconds
        self.time.set(time: time)
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
        self.timerLengthInSeconds = self.totalSeconds
        self.time.set(seconds: self.timerLengthInSeconds)
    }
    
    func setTime(seconds: Double) {
        self.time.set(seconds: seconds)
    }
    
    func addTime(seconds: Int) {
        self.timerLengthInSeconds = min(self.timerLengthInSeconds + seconds, Time.maxSeconds)
        self.time.add(seconds: seconds)
    }
    
    func subtractTime(seconds: Int) {
        self.timerLengthInSeconds = max(self.timerLengthInSeconds - seconds, Time.minSeconds)
        self.time.subtract(seconds: seconds)
    }
    
    func decrement() {
        self.time.decrement()
    }
    
    func startTimer() {
        self.timer = Timer.publish(every: 1, on: .main, in: .common)
        self.cancellable = self.timer.connect()
    }
    
    func stopTimer() {
        self.timer.connect().cancel()
        self.cancellable = nil
    }
}
