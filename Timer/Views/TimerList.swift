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
    
    @FetchRequest(
        entity: TimerData.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \TimerData.label, ascending: true)
        ]
    ) var timersData: FetchedResults<TimerData>
    
    @State private var timerManagers: [TimerManager] = []
    @State private var firstFetch = true
    
    
    // MARK: Methods
    private func addTimer() {
        // TODO: implement
        
        let timerData = TimerData(context: self.managedObjectContext)
        timerData.label = "Timer label"
        timerData.totalSeconds = 0
        
        self.timerManagers.append(TimerManager(timerData: timerData))
        
        do {
            try self.managedObjectContext.save()
        } catch {
            os_log("%@", type: .error, error.localizedDescription)
        }
    }
    
    // MARK: View
    var body: some View {
        NavigationView {
            List(self.timerManagers, id: \.id) { timerManager in
                TimerRow(timerManager: timerManager)
            }
            .navigationBarTitle("Timers")
            .navigationBarItems(
                trailing: Button(action: self.addTimer) {
                    Image(systemName: "plus")
                }
            )
            .font(.system(size: 24))
            .padding()
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

struct TimerList_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        return TimerList().environment(\.managedObjectContext, context)
    }
}

// MARK: View - TimerRow
struct TimerRow: View {
    
    @ObservedObject var timerManager: TimerManager
    @State private var exitTime = Date()
    
    
    var body: some View {
        NavigationLink(destination: TimerView(timerManager: self.timerManager)) {
            HStack(alignment: .center, spacing: 24) {
                ZStack {
                    ProgressCircle(color: Color(self.timerManager.color), progress: self.timerManager.progress, defaultLineWidth: 4, progressLineWidth: 4)
                            .frame(width: 54, height: 54)
                    
                    Button(action: { self.timerManager.isPlaying ? self.timerManager.stopTimer() : self.timerManager.startTimer() }) {
                        Image(systemName: self.timerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
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
