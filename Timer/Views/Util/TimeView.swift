////  TimeView.swift
//  Timer
//
//  Created by R Riesebos on 26/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import SwiftUI

struct TimeView: View {
    
    // MARK: Properties
    private var hour = ""
    private var minute = ""
    private var second = ""
    
    private var selectable = false
    @Binding var selectedTimeLabel: TimeLabelType
    @Binding var position: Int
    
    
    // MARK: Initializers
    init(seconds: Int) {
        let (hour, minute, second) = TimeHelper.secondsToTime(seconds: seconds)
        self.hour = String(hour)
        self.minute = String(minute)
        self.second = String(second)
        
        self._selectedTimeLabel = .constant(TimeLabelType.second)
        self._position = .constant(0)
    }

    init(hour: String, minute: String, second: String, selectedTimeLabel: Binding<TimeLabelType>, position: Binding<Int>) {
        self.hour = hour
        self.minute = minute
        self.second = second
        
        self.selectable = true
        self._selectedTimeLabel = selectedTimeLabel
        self._position = position
    }
    
    // MARK: View
    var body: some View {
        HStack(alignment: .midColonAndTime) {
            TimeLabel(type: TimeLabelType.hour, text: self.hour, selectable: self.selectable, selected: self.$selectedTimeLabel, pos: self.$position)
            Spacer()
            Text(":")
                .font(.system(size: 32))
                .alignmentGuide(.midColonAndTime) { d in d[.bottom] / 2 }
            Spacer()
            TimeLabel(type: TimeLabelType.minute, text: self.minute, selectable: self.selectable, selected: self.$selectedTimeLabel, pos: self.$position)
            Spacer()
            Text(":")
                .font(.system(size: 32))
                .alignmentGuide(.midColonAndTime) { d in d[.bottom] / 2 }
            Spacer()
            TimeLabel(type: TimeLabelType.second, text: self.second, selectable: self.selectable, selected: self.$selectedTimeLabel, pos: self.$position)
        }
    }
}

struct TimeView_Previews: PreviewProvider {
    static var previews: some View {
        TimeView(hour: "", minute: "", second: "", selectedTimeLabel: .constant(TimeLabelType.second), position: .constant(0))
    }
}

extension VerticalAlignment {
    private enum MidColonAndTime: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[.bottom]
        }
    }
    
    static let midColonAndTime = VerticalAlignment(MidColonAndTime.self)
}

enum TimeLabelType: String {
    
    case hour = "Hour"
    case minute = "Minute"
    case second = "Second"
    
    var next: TimeLabelType {
        switch self {
        case .hour:
            return TimeLabelType.minute
        case .minute:
            return TimeLabelType.second
        case .second:
            return TimeLabelType.second
        }
    }
    
    var previous: TimeLabelType {
        switch self {
        case .hour:
            return TimeLabelType.hour
        case .minute:
            return TimeLabelType.hour
        case .second:
            return TimeLabelType.minute
        }
    }
}

// MARK: View - TimeLabel
struct TimeLabel: View {
    
    // MARK: Properties
    let type: TimeLabelType
    var text: String
    
    var selectable = false
    @Binding var selected: TimeLabelType
    @Binding var pos: Int
    
    
    // MARK: Methods
    private func padTimeText(_ text: String) -> String {
        if text.count < 2 {
            return String(repeating: "0", count: 2 - text.count) + text
        }
        
        return text
    }
    
    // MARK: View
    var body: some View {
        VStack {
            if self.selectable {
                SelectableTimeText(type: self.type, text: self.padTimeText(self.text), selected: self.$selected, pos: self.$pos)
            } else {
                TimeText(type: self.type, text: self.padTimeText(self.text))
            }
            
            Text(type.rawValue)
                .foregroundColor(Color.secondary)
                .font(.footnote)
        }
        .frame(minWidth: 64, maxWidth: 96)
    }
}

struct TimeText: View {
    
    var type: TimeLabelType
    var text: String
    
    
    var body: some View {
        Text(self.text)
            .alignmentGuide(.midColonAndTime) { d in d[.bottom] / 2 }
            .font(.system(size: 50))
            .foregroundColor(Color.primary)
    }
}

struct SelectableTimeText: View {
    
    var type: TimeLabelType
    var text: String
    
    @Binding var selected: TimeLabelType
    @Binding var pos: Int
    
    
    var body: some View {
        Text(self.text)
            .alignmentGuide(.midColonAndTime) { d in d[.bottom] / 2 }
            .font(.system(size: 50))
            .foregroundColor(self.selected == self.type ? Color.accentColor : Color.primary)
            .onTapGesture {
                self.selected = self.type
                
                // Reset position in the time label
                self.pos = 0
        }
    }
}
