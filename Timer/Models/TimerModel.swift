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

class TimerModel: ObservableObject, Identifiable {
    
    let id = UUID()
    
    var timerData: TimerData? = nil
    
    @Published var label: String = ""
    @Published var totalSeconds: Int = 0
    @Published var color: UIColor
    
    @Published var timerLengthInSeconds = 0
    @Published var seconds = 0
    
    @Published var timer = Timer.publish(every: 1, on: .main, in: .common)
    private var cancellable: Cancellable? = nil
    
    
    init(label: String, totalSeconds: Int, color: UIColor) {
        self.label = label
        self.totalSeconds = totalSeconds
        
        self.timerLengthInSeconds = Int(totalSeconds)
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
        self.color = UIColor.blue
    }
    
    func set(seconds: Int) {
        self.totalSeconds = seconds
        
        self.timerLengthInSeconds = seconds
        self.seconds = seconds
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
        self.seconds = self.totalSeconds
    }
    
    func setTime(seconds: Double) {
        self.seconds = lround(seconds)
    }
    
    func addTime(seconds: Int) {
        self.timerLengthInSeconds = min(self.timerLengthInSeconds + seconds, Time.maxSeconds)
        self.seconds = min(self.seconds + seconds, Time.maxSeconds)
    }
    
    func subtractTime(seconds: Int) {
        self.timerLengthInSeconds = max(self.timerLengthInSeconds - seconds, Time.minSeconds)
        self.seconds = max(self.seconds - seconds, Time.minSeconds)
    }
    
    func decrement() {
        self.seconds -= 1
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
