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
    
    
    // MARK: Methods
    private func addTimer() {
        // TODO: implement
        
        let timerData = TimerData(context: self.managedObjectContext)
        timerData.label = "Timer label"
        timerData.totalSeconds = 0
        
        do {
            try self.managedObjectContext.save()
        } catch {
            os_log("%@", type: .error, error.localizedDescription)
        }
    }
    
    // MARK: View
    var body: some View {
        NavigationView {
            List(self.timersData, id: \.self) { timerData in
                TimerRow(timerModel: TimerModel(timerData: timerData))
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
    
    var timerModel: TimerModel
    
    
    var body: some View {
        NavigationLink(destination: TimerView(timerModel: self.timerModel)) {
            // TODO: play/pause button and time
            HStack(alignment: .center, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(timerModel.label)
                    Text("\(timerModel.time)")
                }
                Image(systemName: "play.circle")
                    .font(.system(size: 42))
            }
        }
    }
}
