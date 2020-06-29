////  Time.swift
//  Timer
//
//  Created by R Riesebos on 26/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import Foundation

class Time: NSObject, ObservableObject {
    
    // MARK: Properties
    @Published var seconds = 0
    
    static let minSeconds = 0
    static let maxSeconds = 359999
    
    var hour: Int {
        return seconds / 3600
    }
    
    var minute: Int {
        return seconds / 60 % 60
    }
    
    var second: Int {
        return seconds % 60
    }
    
    
    // MARK: Initializers
    convenience init(seconds: Int) {
        self.init()
        
        self.seconds = min(seconds, Time.maxSeconds)
    }
    
    convenience init(time: Time) {
        self.init()
        
        self.seconds = time.seconds
    }
    
    // MARK: Methods
    static func timeToSeconds(hour: Int, minute: Int, second: Int) -> Int {
        var seconds = 0
        seconds += hour * 3600
        seconds += minute * 60
        seconds += second
        
        return seconds
    }
    
    static func timeToSeconds(hour: String, minute: String, second: String) -> Int {
        return Time.timeToSeconds(hour: Int(hour) ?? 0, minute: Int(minute) ?? 0, second: Int(second) ?? 0)
    }
    
    static func timeToSeconds(time: Time) -> Int {
        return Time.timeToSeconds(hour: time.hour, minute: time.minute, second: time.second)
    }
    
    func set(seconds: Int) {
        self.seconds = max(min(seconds, Time.maxSeconds), Time.minSeconds)
    }
    
    func set(seconds: Double) {
        // Introduces max .5 seconds tolerance
        self.set(seconds: lround(seconds))
    }
    
    func set(hour: String, minute: String, second: String) {
        self.set(seconds: Time.timeToSeconds(hour: hour, minute: minute, second: second))
    }
    
    func set(time: Time) {
        self.set(seconds: Time.timeToSeconds(time: time))
    }
    
    func decrement() {
        self.seconds = max(self.seconds - 1, Time.minSeconds)
    }
    
    func reset() {
        self.seconds = 0
    }
    
    func add(seconds: Int) {
        self.seconds = min(self.seconds + seconds, Time.maxSeconds)
    }
    
    func subtract(seconds: Int) {
        self.seconds = max(self.seconds - seconds, Time.minSeconds)
    }
    
    public override var description: String {
        return String(format: "%02i:%02i:%02i", hour, minute, second)
    }
}
