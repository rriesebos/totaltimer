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
    
    @ObservedObject var timer: TimerData
    
    @State private var label: String
    @State private var totalSeconds: Int
    @State private var color: UIColor
    @State private var customColor = Color.clear
    @State private var alarmSound: Sound
    
    @State private var showTimePicker = false
    @State private var showColorPicker = false
    
    
    // MARK: Initializer
    init(timer: TimerData) {
        self.timer = timer
        
        self._label = State(initialValue: timer.label)
        self._totalSeconds = State(initialValue: Int(timer.totalSeconds))
        self._color = State(initialValue: timer.color as! UIColor)
        self._alarmSound = State(initialValue: Sound.alarmSounds.first(where: { $0.name == timer.alarmSoundName }) ?? Sound.defaultAlarmSound)
    }
    
    // MARK: Methods
    private func save() {
        self.timer.label = self.label
        
        self.timer.set(seconds: self.totalSeconds)
        
        self.timer.color = self.color
        self.timer.alarmSoundName = self.alarmSound.name
        
        self.timer.save(managedObjectContext: self.managedObjectContext)
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
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let timer = TimerData.init(context: context)
        timer.label = "Label"
        timer.totalSeconds = 10
        timer.color = UIColor.blue

        return TimerEditView(timer: timer)
            .environment(\.managedObjectContext, context)
    }
}
