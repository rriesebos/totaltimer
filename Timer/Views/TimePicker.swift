////  TimePicker.swift
//  Timer
//
//  Created by R Riesebos on 25/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import SwiftUI

struct TimePicker: View {
    
    // MARK: Properties
    @Environment(\.presentationMode) var presentationMode
    
    let completion: (Int) -> Void
    
    @State private var seconds = 0
    
    @State private var hour = ""
    @State private var minute = ""
    @State private var second = ""
    
    @State private var selectedTimeLabel = TimeLabelType.second
    
    
    // MARK: Initializer
    init(completion: @escaping (Int) -> Void) {
        self.completion = completion
    }
    
    // MARK: Methods
    private func keyPressed(key: Key) {
        switch key {
        case let Key.numerical(value):
            if Int(self.selectedTextBinding(type: self.selectedTimeLabel).wrappedValue) ?? 0 > 9 && self.fillableNextLabelExists(type: self.selectedTimeLabel) {
                self.selectedTimeLabel = selectedTimeLabel.next
            }
            
            self.add(selectedTextBinding: self.selectedTextBinding(type: self.selectedTimeLabel), value: value)
        case Key.delete:
            self.delete(selectedTextBinding: self.selectedTextBinding(type: self.selectedTimeLabel))
        case Key.clear:
            self.clear(selectedTextBinding: self.selectedTextBinding(type: self.selectedTimeLabel))
        }
        
        self.seconds = TimeHelper.timeToSeconds(hour: self.hour, minute: self.minute, second: self.second)
    }
    
    private func fillableNextLabelExists(type: TimeLabelType) -> Bool {
        return Int(self.selectedTextBinding(type: type.next).wrappedValue) ?? 0 < 10
            || Int(self.selectedTextBinding(type: type.next.next).wrappedValue) ?? 0 < 10
    }
    
    private func selectedTextBinding(type: TimeLabelType) -> Binding<String> {
        switch type {
        case TimeLabelType.hour:
            return self.$hour
        case TimeLabelType.minute:
            return self.$minute
        case TimeLabelType.second:
            return self.$second
        }
    }
    
    private func add(selectedTextBinding: Binding<String>, value: Int) {
        if selectedTextBinding.wrappedValue.count < 2 && Int(selectedTextBinding.wrappedValue + String(value)) != 0 {
            selectedTextBinding.wrappedValue += String(value)
        }
    }
    
    private func delete(selectedTextBinding: Binding<String>) {
        if selectedTextBinding.wrappedValue.isEmpty {
            if Int(self.selectedTextBinding(type: self.selectedTimeLabel.next).wrappedValue) ?? 0 != 0 {
                self.selectedTimeLabel = self.selectedTimeLabel.next
            }

            return
        }
        
        selectedTextBinding.wrappedValue.removeLast()
    }
    
    private func clear(selectedTextBinding: Binding<String>) {
        self.hour = ""
        self.minute = ""
        self.second = ""
        
        self.selectedTimeLabel = TimeLabelType.second
    }
    
    private func pickTime() {
        self.completion(self.seconds)
        self.presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: View
    var body: some View {
        VStack(alignment: .center, spacing: 40) {
            Spacer()
            TimeView(hour: self.hour, minute: self.minute, second: self.second, selectedTimeLabel: self.$selectedTimeLabel)
            KeyPad(action: self.keyPressed)
                .padding(4)
            Button(action: { self.pickTime() }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 64))
            }
            .padding(.top, 32)
            .disabled(self.seconds <= 0)
            Spacer()
        }
        .padding(.horizontal, 72)
    }
}

struct TimePicker_Previews: PreviewProvider {
    static var previews: some View {
        TimePicker() { _ in }
    }
}
