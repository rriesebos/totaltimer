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
    ) var timersData: FetchedResults<TimerData>
    
    @State private var timerManagers: [TimerManager] = []
    @State private var firstFetch = true
    
    @State private var showTimePicker = false
    @State private var timerCount = UserDefaults.standard.integer(forKey: "TimerCount")
    
    @State private var showActive = false
    
    @State private var isSelecting = false
    @State private var selection = Set<TimerManager>()
    
    
    // MARK: Methods
    private func addTimer(seconds: Int) {
        let timerData = TimerData(context: self.managedObjectContext)
        timerData.label = "Timer \(self.timerCount + 1)"
        timerData.totalSeconds = Int64(seconds)
        timerData.color = UIColor.timerColors[self.timerCount % UIColor.timerColors.count]
        timerData.dateAdded = Date()
        
        let timerManager = TimerManager(timerData: timerData)
        self.timerManagers.append(timerManager)
        
        // Start timer after adding
        timerManager.startTimer()
        
        // Save core data object
        do {
            try self.managedObjectContext.save()
        } catch {
            os_log("%@", type: .error, error.localizedDescription)
        }

        // Increment and save timer counter
        self.timerCount += 1
        UserDefaults.standard.set(self.timerCount, forKey: "TimerCount")
    }
    
    private func deleteTimers(timerManagers: [TimerManager], offsets: IndexSet) {
        for index in offsets {
            let timerManager = timerManagers[index]
            
            // Delete core data object
            if let timerData = timerManager.timerData {
                self.managedObjectContext.delete(timerData)
            }
            
            // Delete timerManager from (filtered) list
            if let firstIndex = self.timerManagers.firstIndex(where: { $0.id == timerManager.id }) {
                self.timerManagers.remove(at: firstIndex)
                
                // Decrement timer counter if firstIndex of the filtered list is the last timer
                if self.showActive && firstIndex == self.timerManagers.count {
                    self.timerCount -= 1
                }
            }
        }
        
        // Decrement timerCount if last timer is deleted
        if offsets.contains(self.timerManagers.count) && !self.showActive {
            self.timerCount -= 1
        }
        
        // Reset timerCount if all timers are deleted
        if self.timerManagers.isEmpty {
            self.timerCount = 0
        }
        
        UserDefaults.standard.set(self.timerCount, forKey: "TimerCount")

        do {
            try self.managedObjectContext.save()
        } catch {
            os_log("%@", type: .error, error.localizedDescription)
        }
    }
    
    // MARK: View
    var body: some View {
        let timerManagers = self.timerManagers.filter { !self.showActive || $0.isPlaying }
        
        return GeometryReader { geometry in
            NavigationView {
                List(selection: self.$selection) {
                    ForEach(timerManagers, id: \.self) { timerManager in
                        TimerRow(timerManager: timerManager)
                    }
                    .onDelete { offsets in
                        self.deleteTimers(timerManagers: timerManagers, offsets: offsets)
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
                    .frame(width: 64, alignment: .leading),
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
                
                self.timerManagers = self.timersData.map {
                    TimerManager(timerData: $0)
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
    
    @ObservedObject var timerManager: TimerManager
    @State private var exitTime = Date()
    
    
    var body: some View {
        NavigationLink(destination: TimerDetailView(timerManager: self.timerManager)) {
            HStack(alignment: .center, spacing: 24) {
                ZStack {
                    ProgressCircle(color: Color(self.timerManager.color), progress: self.timerManager.progress, defaultLineWidth: 4, progressLineWidth: 4)
                            .frame(width: 44, height: 44)
                    
                    Button(action: { self.timerManager.isPlaying ? self.timerManager.stopTimer() :
                        self.timerManager.seconds == 0 ? self.timerManager.reset() : self.timerManager.startTimer() }) {
                        Image(systemName: self.timerManager.isPlaying ? "pause.circle.fill" :
                            self.timerManager.seconds == 0 ? "arrow.counterclockwise.circle.fill" : "play.circle.fill")
                            .font(.system(size: 42))
                    }
                    .disabled(self.timerManager.totalSeconds == 0)
                    .foregroundColor(self.timerManager.totalSeconds == 0 ? Color.gray : Color(self.timerManager.color))
                    .buttonStyle(PlainButtonStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.timerManager.label)
                        .lineLimit(1)
                        .padding(.trailing, 8)
                    Text(TimeHelper.secondsToTimeString(seconds: self.timerManager.seconds))
                        .foregroundColor(Color.secondary)
                }
                .font(.system(size: 20))
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                self.timerManager.isActive = false
                
                if self.timerManager.isPlaying {
                    self.exitTime = Date()
                    
                    // Re-set notification in case the time is less than the allowed background time
                    self.timerManager.setNotification()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                if self.timerManager.isPlaying {
                    // Update time using elapsed time when returning from background
                    let elapsedSeconds: Double = -self.exitTime.timeIntervalSinceNow
                    self.timerManager.setTime(seconds: lround(Double(self.timerManager.seconds) - elapsedSeconds))
                }
                
                self.timerManager.isActive = true
            }
        }
    }
}
