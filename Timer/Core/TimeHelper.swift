////  TimeHelper.swift
//  Timer
//
//  Created by R Riesebos on 26/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import Foundation

class TimeHelper {
    
    // MARK: Properties
    static let minSeconds = 0
    static let maxSeconds = 359999
    
    
    // MARK: Methods
    static func timeToSeconds(hour: Int, minute: Int, second: Int) -> Int {
        var seconds = 0
        seconds += hour * 3600
        seconds += minute * 60
        seconds += second
        
        return max(min(seconds, TimeHelper.maxSeconds), TimeHelper.minSeconds)
    }
    
    static func timeToSeconds(hour: String, minute: String, second: String) -> Int {
        return TimeHelper.timeToSeconds(hour: Int(hour) ?? 0, minute: Int(minute) ?? 0, second: Int(second) ?? 0)
    }
    
    static func secondsToTime(seconds: Int) -> (hour: Int, minute: Int, second: Int) {
        let hour = seconds / 3600
        let minute = seconds / 60 % 60
        let second = seconds % 60
        
        return (hour, minute, second)
    }
    
    static func secondsToTimeString(seconds: Int) -> String {
        let (hour, minute, second) = TimeHelper.secondsToTime(seconds: seconds)
        
        return String(format: "%02i:%02i:%02i", hour, minute, second)
    }
}
