////  UIColors.swift
//  Timer
//
//  Created by R Riesebos on 01/07/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import Foundation
import SwiftUI

extension UIColor {
    
    static let darkYellow = UIColor.init(named: "darkYellow")!
    static let jungleGreen = UIColor.init(named: "jungleGreen")!
    static let skyBlue = UIColor.init(named: "skyBlue")!
    static let lapisBlue = UIColor.init(named: "lapisBlue")!
    static let lightPurple = UIColor.init(named: "lightPurple")!
    static let hotPink = UIColor.init(named: "hotPink")!
    
    static let timerColors = [UIColor.red, UIColor.orange, UIColor.darkYellow, UIColor.jungleGreen, UIColor.skyBlue, UIColor.lapisBlue, UIColor.lightPurple, UIColor.hotPink]
    
    static var random: UIColor {
        return UIColor(red: .random(in: 0...1),
                       green: .random(in: 0...1),
                       blue: .random(in: 0...1),
                       alpha: 1.0)
    }
}
