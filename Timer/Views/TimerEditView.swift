////  TimerEditView.swift
//  Timer
//
//  Created by R Riesebos on 01/07/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import SwiftUI

struct TimerEditView: View {
    
    // MARK: Properties
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var timerManager: TimerManager
    
    @State private var label: String
    @State private var totalSeconds: Int
    @State private var color: UIColor
    @State private var customColor = Color.clear
    @State private var alarmSound: Sound
    
    @State private var showTimePicker = false
    @State private var showColorPicker = false
    
    
    // MARK: Initializer
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
        
        self._label = State(initialValue: timerManager.label)
        self._totalSeconds = State(initialValue: timerManager.totalSeconds)
        self._color = State(initialValue: timerManager.color)
        self._alarmSound = State(initialValue: Sound.alarmSounds.first(where: { $0.name == timerManager.alarmSoundName }) ?? Sound.defaultAlarmSound)
    }
    
    // MARK: Methods
    private func save() {
        self.timerManager.label = self.label
        
        self.timerManager.set(seconds: self.totalSeconds)
        
        self.timerManager.color = self.color
        self.timerManager.alarmSoundName = self.alarmSound.name
        
        self.timerManager.save(managedObjectContext: self.managedObjectContext)
        self.presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: View
    var body: some View {
        Form {
            Section(header: Text("LABEL")) {
                TextField(self.label, text: self.$label)
                    .padding(.vertical, 4)
            }
            Section(header: Text("TIME")) {
                HStack {
                    Text(TimeHelper.secondsToTimeString(seconds: self.totalSeconds))
                        .padding(.vertical, 4)
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    self.showTimePicker = true
                }
                .sheet(isPresented: self.$showTimePicker) {
                    TimePicker() { seconds in
                        self.totalSeconds = seconds
                    }
                }
            }
            Section(header: Text("COLOR")) {
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(self.color))
                        .frame(height: 36)
                        .padding(.vertical, 8)
                        .onTapGesture {
                            self.showColorPicker = true
                        }
                        .sheet(isPresented: self.$showColorPicker) {
                            TimerColorPicker() { color in
                                self.color = color
                                self.customColor = .clear
                            }
                        }
                    if #available(iOS 14.0, *) {
                        ColorPicker("", selection: self.$customColor)
                            .frame(width: 32)
                            .onChange(of: self.customColor, perform: { _ in
                                if self.customColor == .clear {
                                    return
                                }
                                
                                self.color = UIColor(self.customColor)
                            })
                    }
                }
            }
            Section(header: Text("ALARM SOUND")) {
                SoundPicker(sounds: Sound.alarmSounds, sound: self.$alarmSound)
            }
        }
        .font(.system(size: 20))
        .navigationBarTitle("Edit timer")
        .navigationBarItems(trailing: Button(action: self.save) {
            Text("Save")
        })
    }
}

struct TimerEditView_Previews: PreviewProvider {
    static var previews: some View {
        TimerEditView(timerManager: TimerManager(label: "Label", totalSeconds: 10, color: UIColor.blue))
    }
}
