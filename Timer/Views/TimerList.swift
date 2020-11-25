////  TimerList.swift
//  Timer
//
//  Created by R Riesebos on 28/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import SwiftUI
import os.log

struct TimerList: View {
    
    // MARK: Properties
    @Environment(\.managedObjectContext) var managedObjectContext
    
    // Added to prevent navigation bar not working after sheet is dismissed
    @Environment(\.presentationMode) var presentationMode
    
    @FetchRequest(
        entity: TimerData.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \TimerData.dateAdded, ascending: true),
            NSSortDescriptor(keyPath: \TimerData.label, ascending: true),
            NSSortDescriptor(keyPath: \TimerData.totalSeconds, ascending: true)
        ]
    ) var timers: FetchedResults<TimerData>
    
    @EnvironmentObject var sharedTimerManager: SharedTimerManager
    
    @State private var firstFetch = true
    
    @State private var showTimePicker = false
    @State private var timerCount = 0
    
    @State private var showActive = false
    
    @State private var isSelecting = false
    @State private var selection = Set<TimerData>()
    
    
    // MARK: Methods
    private func addTimer(seconds: Int) {
        self.updateTimerCount()
        
        let timerData = TimerData(context: self.managedObjectContext)
        timerData.label = "Timer \(self.timerCount + 1)"
        timerData.totalSeconds = Int64(seconds)
        timerData.color = UIColor.timerColors[self.timerCount % UIColor.timerColors.count]
        timerData.dateAdded = Date()
        
        // Add timer to timerManager list and sharedTimerManager
        self.sharedTimerManager.timers[timerData.id.uuidString] = timerData
        
        // Start timer after adding
        timerData.startTimer()
        
        // Save core data object
        do {
            try self.managedObjectContext.save()
        } catch {
            os_log("%@", type: .error, error.localizedDescription)
        }
    }
    
    private func deleteTimers(timers: [TimerData], offsets: IndexSet) {
        for index in offsets {
            let timer = timers[index]
            
            // Remove pending notification
            timer.removeNotification()
            
            // Stop alarm
            timer.reset()
            
            self.sharedTimerManager.timers.removeValue(forKey: timer.id.uuidString)
            
            // Delete core data object
            self.managedObjectContext.delete(timer)
        }

        do {
            try self.managedObjectContext.save()
        } catch {
            os_log("%@", type: .error, error.localizedDescription)
        }
    }
    
    private func updateTimerCount() {
        if self.timers.isEmpty {
            self.timerCount = 0
            return
        }
        
        // Set current count to the count (+ 1) of the previous timer
        let previousCount = Int(self.timers.last!.label.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
        self.timerCount = previousCount ?? 0
    }
    
    // MARK: View
    var body: some View {
        let timers = self.timers.filter { !self.showActive || $0.isPlaying }
        
        return GeometryReader { geometry in
            NavigationView {
                List(selection: self.$selection) {
                    ForEach(timers, id: \.self) { timer in
                        TimerRow(timer: timer)
                            .disabled(self.isSelecting)
                    }
                    .onDelete { offsets in
                        self.deleteTimers(timers: timers, offsets: offsets)
                    }
                }
                .environment(\.editMode, self.isSelecting ? .constant(.active) : .constant(.inactive))
                .navigationBarTitle("Timers")
                .navigationBarItems(
                    leading: Button(action: {
                        withAnimation {
                            self.isSelecting.toggle()
                        }
                    }) {
                        Text(self.isSelecting ? "Cancel" : "Select")
                    }
                    .frame(width: 64, alignment: .leading)
                    .disabled(self.timers.isEmpty),
                    trailing: HStack(spacing: 0) {
                        Picker(selection: self.$showActive, label: Text("Toggle between all and active")) {
                            Text("All").tag(false)
                            Text("Active").tag(true)
                        }
                        .frame(width: 115)
                        .pickerStyle(SegmentedPickerStyle())
                        
                        // Spacer to center picker, the width is
                        // half the screen width - half the picker width -
                        // add button width (64) - right side padding (16)
                        Spacer()
                            .frame(width: (geometry.size.width - 115) / 2 - 80)
                        
                        Button(action: {
                            if self.isSelecting {
                                withAnimation {
                                    self.isSelecting = false
                                }
                                
                                if self.showActive {
                                    // Stop selected timers
                                    for timerManager in self.selection {
                                        timerManager.stopTimer()
                                    }
                                } else {
                                    // Play selected timers
                                    for timerManager in self.selection {
                                        timerManager.startTimer()
                                    }
                                }
                                
                                self.selection.removeAll()
                            } else {
                                self.showTimePicker = true
                            }
                        }) {
                            if self.isSelecting {
                                if self.showActive {
                                    Text("Pause")
                                } else {
                                    Text("Play")
                                }
                            } else {
                                Text("Add")
                            }
                        }
                        .frame(width: 64, alignment: .trailing)
                        .disabled(self.selection.isEmpty && self.isSelecting)
                    }
                )
            }
            .sheet(isPresented: self.$showTimePicker) {
                TimePicker() { seconds in
                    self.addTimer(seconds: seconds)
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear {
                guard self.firstFetch else { return }
                
                // Add timers to the sharedTimerManager
                for timer in self.timers {
                    self.sharedTimerManager.timers[timer.id.uuidString] = timer
                }
                
                self.firstFetch = false
            }
        }
    }
}

struct TimerList_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        let timerData = TimerData(context: context)
        timerData.label = "Timer label"
        timerData.totalSeconds = 10
        timerData.color = UIColor.random
        
        return TimerList().environment(\.managedObjectContext, context)
    }
}

// MARK: View - TimerRow
struct TimerRow: View {
    
    @ObservedObject var timer: TimerData
    @State private var exitTime = Date()
    
    
    var body: some View {
        return NavigationLink(destination: TimerDetailView(timer: self.timer)) {
            HStack(alignment: .center, spacing: 24) {
                ZStack {
                    // Optional casting of color to UIColor to account for delay in removing core data object
                    // during this delay the color property is set to nil
                    ProgressCircle(color: Color(self.timer.color as? UIColor ?? UIColor.blue), progress: self.timer.progress, defaultLineWidth: 4, progressLineWidth: 4)
                            .frame(width: 44, height: 44)
                    
                    Button(action: { self.timer.isPlaying ? self.timer.stopTimer() :
                        self.timer.seconds == 0 ? self.timer.reset() : self.timer.startTimer() }) {
                        Image(systemName: self.timer.isPlaying ? "pause.circle.fill" :
                            self.timer.seconds == 0 ? "arrow.counterclockwise.circle.fill" : "play.circle.fill")
                            .font(.system(size: 42))
                    }
                    .disabled(self.timer.totalSeconds == 0)
                    .foregroundColor(self.timer.totalSeconds == 0 ? Color.gray : Color(self.timer.color as! UIColor))
                    .buttonStyle(PlainButtonStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.timer.label)
                        .lineLimit(1)
                        .padding(.trailing, 8)
                    Text(TimeHelper.secondsToTimeString(seconds: self.timer.seconds))
                        .foregroundColor(Color.secondary)
                }
                .font(.system(size: 20))
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                self.timer.isActive = false
                
                if self.timer.isPlaying {
                    self.exitTime = Date()
                    
                    // Re-set notification in case the time is less than the allowed background time
                    self.timer.setNotification()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                if self.timer.isPlaying {
                    // Update time using elapsed time when returning from background
                    let elapsedSeconds: Double = -self.exitTime.timeIntervalSinceNow
                    self.timer.setTime(seconds: lround(Double(self.timer.seconds) - elapsedSeconds))
                }
                
                self.timer.isActive = true
            }
        }
    }
}
