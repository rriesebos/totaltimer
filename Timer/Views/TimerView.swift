//
//  TimerView.swift
//  Timer
//
//  Created by R Riesebos on 25/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import SwiftUI
import Combine
import UserNotifications
import os.log

struct TimerView: View {
    
    // MARK: Properties
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var timerModel: TimerModel
    
    @State private var showTimePicker = false
    
    @State private var exitTime = Date()
    
    @State private var notificationID = UUID().uuidString
    
    
    // MARK: Initializer
    init(timerModel: TimerModel) {
        self.timerModel = timerModel
    }
    
    // MARK: Methods
    private func setTimer(seconds: Int) {
        self.timerModel.set(seconds: seconds)
        self.timerModel.save(managedObjectContext: self.managedObjectContext)
    }
    
    private func addTime(seconds: Int) {
        self.timerModel.addTime(seconds: seconds)
        self.setNotification()
    }
    
    private func subtractTime(seconds: Int) {
        self.timerModel.subtractTime(seconds: seconds)
        
        if self.timerModel.seconds > 0 {
            self.setNotification()
        }
    }
    
    private func startTimer() {
        self.timerModel.startTimer()
        self.setNotification()
    }
    
    private func stopTimer() {
        self.timerModel.stopTimer()
        self.removeNotification()
    }
    
    private func resetTimer() {
        self.timerModel.reset()
    }
    
    private func removeNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [self.notificationID])
    }
    
    private func setNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                os_log("%@", type: .error, error.localizedDescription)
            }
        }
        
        self.removeNotification()
        
        let content = UNMutableNotificationContent()
        content.title = self.timerModel.label
        content.subtitle = "subtitle"
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(self.timerModel.seconds), repeats: false)

        self.notificationID = UUID().uuidString
        let request = UNNotificationRequest(identifier: self.notificationID, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: View
    // TODO: extract subviews, refactor
    var body: some View {
        VStack(spacing: 64) {
            Text(self.timerModel.label)
                .font(.largeTitle)
            ZStack {
                ProgressCircle(color: Color(self.timerModel.color), progress: self.timerModel.progress)
                
                VStack(alignment: .center, spacing: 16) {
                    TimeView(seconds: self.timerModel.seconds)
                        .onTapGesture {
                            self.showTimePicker = true
                            self.resetTimer()
                        }
                        .padding()
                        .scaledToFit()
                    HStack(spacing: 24) {
                        Button(action: { self.subtractTime(seconds: 30) }) {
                            Text("- 30")
                        }
                        .opacity(self.timerModel.isPlaying ? 1 : 0)
                        .animation(.linear(duration: 0.1))
                        Button(action: self.resetTimer) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 54))
                        }
                        Button(action: { self.addTime(seconds: 30) }) {
                            Text("+ 30")
                        }
                        .opacity(self.timerModel.isPlaying ? 1 : 0)
                        .animation(.linear(duration: 0.1))
                    }
                    .font(.system(size: 28))
                }
                .padding(.horizontal)
                .scaledToFit()
            }
            .padding(.horizontal, 24)
            Button(action: { self.timerModel.isPlaying ? self.stopTimer() : self.startTimer() }) {
                Image(systemName: self.timerModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                  .font(.system(size: 64))
            }
            .disabled(self.timerModel.totalSeconds == 0)
            
            Spacer()
        }
        .sheet(isPresented: self.$showTimePicker) {
            TimePicker() { seconds in
                self.setTimer(seconds: seconds)
                self.startTimer()
            }
        }
        .navigationBarItems(
            trailing: Button(action: {}) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 24))
            }
        )
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            self.timerModel.isActive = false
            
            if self.timerModel.isPlaying {
                self.exitTime = Date()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            if self.timerModel.isPlaying {
                // Update time using elapsed time when returning from background
                let elapsedSeconds: Double = -self.exitTime.timeIntervalSinceNow
                self.timerModel.setTime(seconds: lround(Double(self.timerModel.seconds) - elapsedSeconds))
            }
            
            self.timerModel.isActive = true
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TimerView(timerModel: TimerModel(label: "Label", totalSeconds: 10, color: UIColor.blue))
        }
    }
}

// MARK: View - ProgressCircle
struct ProgressCircle: View {
    
    var color: Color
    var progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12)
                // TODO: setting
                .foregroundColor(self.color)
                .opacity(0.3)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(self.color)
                .rotationEffect(.degrees(270))
                .animation(.linear)
        }
    }
}
