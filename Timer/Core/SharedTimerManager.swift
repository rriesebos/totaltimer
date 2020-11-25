////  SharedTimerManager.swift
//  Timer
//
//  Created by R Riesebos on 16/08/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import Foundation

class SharedTimerManager: ObservableObject {
    
    @Published var timers: [String: TimerData] = [:]
}
