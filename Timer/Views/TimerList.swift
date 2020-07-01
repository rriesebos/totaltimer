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
            NSSortDescriptor(keyPath: \TimerData.label, ascending: true)
        ]
    ) var timersData: FetchedResults<TimerData>
    
    @State private var timerManagers: [TimerManager] = []
    @State private var firstFetch = true
    
    @State private var showTimePicker = false
    @State private var timerCount = UserDefaults.standard.integer(forKey: "TimerCount")
    
    
    // MARK: Methods
    private func addTimer(seconds: Int) {
        let timerData = TimerData(context: self.managedObjectContext)
        timerData.label = "Timer \(self.timerCount + 1)"
        timerData.totalSeconds = Int64(seconds)
        timerData.color = UIColor.timerColors[self.timerCount % UIColor.timerColors.count]
        
        let timerManager = TimerManager(timerData: timerData)
        self.timerManagers.append(timerManager)
        
        timerManager.startTimer()
        
        do {
            try self.managedObjectContext.save()
        } catch {
            os_log("%@", type: .error, error.localizedDescription)
        }

        self.timerCount += 1
        self.updateTimerCounter()
    }
    
    private func updateTimerCounter(offsets: IndexSet = IndexSet()) {
        // Decrement timerCount if last timer is deleted
        if offsets.contains(self.timerManagers.count) {
            self.timerCount -= 1
        }
        
        // Reset timerCount if all timers are deleted
        if self.timerManagers.isEmpty {
            self.timerCount = 0
        }
        
        UserDefaults.standard.set(self.timerCount, forKey: "TimerCount")
    }
    
    // MARK: View
    var body: some View {
        NavigationView {
            List {
                ForEach(self.timerManagers, id: \.id) { timerManager in
                    TimerRow(timerManager: timerManager)
                }
                .onDelete { offsets in
                    for index in offsets {
                        let timerManager = self.timerManagers[index]
                        
                        if let timerData = timerManager.timerData {
                            self.managedObjectContext.delete(timerData)
                        }
                    }
                    
                    self.timerManagers.remove(atOffsets: offsets)
                    
                    self.updateTimerCounter(offsets: offsets)

                    do {
                        try self.managedObjectContext.save()
                    } catch {
                        os_log("%@", type: .error, error.localizedDescription)
                    }
                }
            }
            .navigationBarTitle("Timers")
            .navigationBarItems(
                leading: EditButton(),
                trailing: Button(action: { self.showTimePicker = true }) {
                    Text("Add")
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
            
            // Sort timerManagers by label length (alphabetically if equal)
            self.timerManagers.sort {
                return $0.label.count < $1.label.count
            }
            
            self.updateTimerCounter()
            
            self.firstFetch = false
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
                            .frame(width: 46, height: 45)
                    
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
