////  ProgressCircle.swift
//  Timer
//
//  Created by R Riesebos on 30/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import SwiftUI

struct ProgressCircle: View {
    
    var color: Color
    var progress: Double
    
    var defaultLineWidth: CGFloat
    var progressLineWidth: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: self.defaultLineWidth)
                .foregroundColor(self.color)
                .opacity(0.3)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: self.progressLineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(self.color)
                .rotationEffect(.degrees(270))
                .animation(.linear)
        }
    }
}
struct ProgressCircle_Previews: PreviewProvider {
    static var previews: some View {
        ProgressCircle(color: Color.blue, progress: 0.5, defaultLineWidth: 12, progressLineWidth: 20)
    }
}
