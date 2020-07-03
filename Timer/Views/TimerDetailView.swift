//
//  TimerView.swift
//  Timer
//
//  Created by R Riesebos on 25/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import SwiftUI
import os.log

struct TimerDetailView: View {
    
    // MARK: Properties
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @ObservedObject var timerManager: TimerManager
    
    @State private var showTimePicker = false
    @State private var showColorPicker = false
    
    @State private var exitTime = Date()
    
    @State private var notificationID = UUID().uuidString
    
    
    // MARK: Initializer
    init(timerManager: TimerManager) {
        self.timerManager = timerManager
    }
    
    // MARK: Methods
    private func setTimer(seconds: Int) {
        self.timerManager.set(seconds: seconds)
        self.timerManager.save(managedObjectContext: self.managedObjectContext)
    }
    
    // MARK: View
    var body: some View {
        VStack(spacing: 64) {
            TextField(self.timerManager.label, text: self.$timerManager.label, onEditingChanged: { isEditing in
                if isEditing {
                    return
                }
                
                self.timerManager.save(managedObjectContext: self.managedObjectContext)
            })
                .font(.system(size: 34, weight: .medium, design: .default))
                .lineLimit(1)
                .multilineTextAlignment(.center)
            
            ZStack {
                ProgressCircle(color: Color(self.timerManager.color), progress: self.timerManager.progress, defaultLineWidth: 12, progressLineWidth: 20)
                    .onTapGesture {
                        self.showColorPicker = true
                    }
                    .sheet(isPresented: self.$showColorPicker) {
                        ColorPicker() { uiColor in
                            self.timerManager.color = uiColor
                        }
                    }
                
                VStack(alignment: .center, spacing: 16) {
                    TimeView(seconds: self.timerManager.seconds)
                        .padding()
                        .scaledToFit()
                        .onTapGesture {
                            self.showTimePicker = true
                        }
                        .sheet(isPresented: self.$showTimePicker) {
                            TimePicker() { seconds in
                                self.setTimer(seconds: seconds)
                                self.timerManager.startTimer()
                            }
                        }

                    HStack(spacing: 24) {
                        Button(action: { self.timerManager.subtractTime(seconds: 30) }) {
                            Text("- 30")
                        }
                        .opacity(self.timerManager.isPlaying ? 1 : 0)
                        .animation(.linear(duration: 0.1))
                        Button(action: self.timerManager.reset) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 54))
                        }
                        Button(action: { self.timerManager.addTime(seconds: 30) }) {
                            Text("+ 30")
                        }
                        .opacity(self.timerManager.isPlaying ? 1 : 0)
                        .animation(.linear(duration: 0.1))
                    }
                    .font(.system(size: 28))
                    .accentColor(Color(self.timerManager.color))
                }
                .padding(.horizontal)
                .scaledToFit()
            }
            .padding(.horizontal, 24)
            
            Button(action: { self.timerManager.isPlaying ? self.timerManager.stopTimer() : self.timerManager.startTimer() }) {
                Image(systemName: self.timerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 64))
            }
            .disabled(self.timerManager.totalSeconds == 0)
            .accentColor(Color(self.timerManager.color))
            
            Spacer()
        }
        .navigationBarItems(
            trailing: NavigationLink(destination: TimerEditView(timerManager: self.timerManager)) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 24))
            }
        )
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

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TimerDetailView(timerManager: TimerManager(label: "Label", totalSeconds: 10, color: UIColor.blue))
        }
    }
}