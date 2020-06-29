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
    
    @State private var timerModels: [TimerModel] = []
    @State private var firstFetch = true
    
    
    // MARK: Methods
    private func addTimer() {
        // TODO: implement
        
        let timerData = TimerData(context: self.managedObjectContext)
        timerData.label = "Timer label"
        timerData.totalSeconds = 0
        
        self.timerModels.append(TimerModel(timerData: timerData))
        
        do {
            try self.managedObjectContext.save()
        } catch {
            os_log("%@", type: .error, error.localizedDescription)
        }
    }
    
    // MARK: View
    var body: some View {
        NavigationView {
            List(self.timerModels, id: \.id) { timerModel in
                TimerRow(timerModel: timerModel)
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
            
            self.timerModels = self.timersData.map {
                    TimerModel(timerData: $0)
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
    
    @ObservedObject var timerModel: TimerModel
    
    
    var body: some View {
        return NavigationLink(destination: TimerView(timerModel: self.timerModel)) {
            // TODO: play/pause button and time
            HStack(alignment: .center, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(self.timerModel.label)
                    Text(Time.secondsToTimeString(seconds: self.timerModel.seconds))
                }
                Image(systemName: "play.circle")
                    .font(.system(size: 42))
            }
        }
    }
}
