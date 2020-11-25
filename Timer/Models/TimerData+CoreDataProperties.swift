////  TimerData+CoreDataProperties.swift
//  Timer
//
//  Created by R Riesebos on 25/11/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//
//

import Foundation
import CoreData


extension TimerData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimerData> {
        return NSFetchRequest<TimerData>(entityName: "TimerData")
    }

    @NSManaged public var alarmSoundName: String
    @NSManaged public var color: NSObject?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var label: String
    @NSManaged public var totalSeconds: Int64

}
