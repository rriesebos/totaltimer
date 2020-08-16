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
    
    @State private var selectedTimeLabel = TimeLabelType.hour
    // Current position in the time label
    @State private var position = 0
    
    
    // MARK: Initializer
    init(completion: @escaping (Int) -> Void) {
        self.completion = completion
    }
    
    // MARK: Methods
    private func keyPressed(key: Key) {
        switch key {
        case let Key.numerical(value):
            self.add(selectedTextBinding: self.selectedTextBinding(type: self.selectedTimeLabel), value: value)
            
            if self.position == 1 {
                self.selectedTimeLabel = selectedTimeLabel.next
                self.position = 0
            } else {
                self.position += 1
            }
        case Key.delete:
            self.position = max(self.position - 1, 0)
            self.delete(selectedTextBinding: self.selectedTextBinding(type: self.selectedTimeLabel))
        case Key.clear:
            self.position = 0
            self.clear(selectedTextBinding: self.selectedTextBinding(type: self.selectedTimeLabel))
        }
        
        self.seconds = TimeHelper.timeToSeconds(hour: self.hour, minute: self.minute, second: self.second)
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
            self.selectedTimeLabel = self.selectedTimeLabel.previous
            return
        }
        
        selectedTextBinding.wrappedValue.removeLast()
    }
    
    private func clear(selectedTextBinding: Binding<String>) {
        self.hour = ""
        self.minute = ""
        self.second = ""
        
        self.selectedTimeLabel = TimeLabelType.hour
    }
    
    private func pickTime() {
        self.completion(self.seconds)
        self.presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: View
    var body: some View {
        VStack(alignment: .center, spacing: 40) {
            Spacer()
            TimeView(hour: self.hour, minute: self.minute, second: self.second, selectedTimeLabel: self.$selectedTimeLabel, position: self.$position)
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
