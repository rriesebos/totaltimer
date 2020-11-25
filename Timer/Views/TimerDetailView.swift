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
    
    @ObservedObject var timer: TimerData
    
    @State private var showTimePicker = false
    @State private var showColorPicker = false
    
    @State private var editTimer = false
    
    @State private var exitTime = Date()
    
    @State private var notificationID = UUID().uuidString
    
    
    // MARK: Initializer
    init(timer: TimerData) {
        self.timer = timer
    }
    
    // MARK: Methods
    private func setTimer(seconds: Int) {
        self.timer.set(seconds: seconds)
        self.timer.save(managedObjectContext: self.managedObjectContext)
    }
    
    // MARK: View
    var body: some View {
        ZStack {
            NavigationLink(destination: TimerEditView(timer: self.timer), isActive: self.$editTimer) {
                EmptyView()
            }
            
            VStack(spacing: 72) {
                Spacer()
                
                TextField(self.timer.label, text: self.$timer.label, onEditingChanged: { isEditing in
                    if isEditing {
                        return
                    }
                    
                    self.timer.save(managedObjectContext: self.managedObjectContext)
                })
                    .font(.system(size: 34, weight: .medium, design: .default))
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .padding(.top, -40)
                
                ZStack(alignment: .center) {
                    ProgressCircle(color: Color(self.timer.color as! UIColor), progress: self.timer.progress, defaultLineWidth: 12, progressLineWidth: 20)
                        .frame(maxWidth: 600, maxHeight: 600)
                        .scaledToFill()
                        .onTapGesture {
                            self.showColorPicker = true
                        }
                        .sheet(isPresented: self.$showColorPicker) {
                            TimerColorPicker() { uiColor in
                                self.timer.color = uiColor
                            }
                        }
                    
                    VStack(alignment: .center, spacing: 16) {
                        TimeView(seconds: self.timer.seconds)
                            .padding()
                            .scaledToFit()
                            .onTapGesture {
                                self.showTimePicker = true
                            }
                            .sheet(isPresented: self.$showTimePicker) {
                                TimePicker() { seconds in
                                    self.setTimer(seconds: seconds)
                                    self.timer.startTimer()
                                }
                            }

                        HStack(spacing: 24) {
                            Button(action: { self.timer.subtractTime(seconds: 30) }) {
                                Text("- 30")
                            }
                            .opacity(self.timer.isPlaying ? 1 : 0)
                            .animation(.linear(duration: 0.1))
                            Button(action: self.timer.reset) {
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .font(.system(size: 54))
                            }
                            Button(action: { self.timer.addTime(seconds: 30) }) {
                                Text("+ 30")
                            }
                            .opacity(self.timer.isPlaying ? 1 : 0)
                            .animation(.linear(duration: 0.1))
                        }
                        .font(.system(size: 28))
                        .accentColor(Color(self.timer.color as! UIColor))
                    }
                    .padding(.horizontal)
                    .scaledToFit()
                }
                
                Button(action: { self.timer.isPlaying ? self.timer.stopTimer() : self.timer.startTimer() }) {
                    Image(systemName: self.timer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }
                .padding(.bottom, 32)
                .disabled(self.timer.totalSeconds == 0)
                .accentColor(Color(self.timer.color as! UIColor))
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarItems(
            trailing: Button(action: {
                self.editTimer = true
                self.timer.stopTimer()
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 24))
            }
        )
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let timer = TimerData.init(context: context)
        timer.label = "Label"
        timer.totalSeconds = 10
        timer.color = UIColor.blue
        
        return NavigationView {
            TimerDetailView(timer: timer)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environment(\.managedObjectContext, context)
    }
}
