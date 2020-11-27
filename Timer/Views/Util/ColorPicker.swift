////  ColorPicker.swift
//  Timer
//
//  Created by R Riesebos on 01/07/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import SwiftUI

struct TimerColorPicker: View {
    
    // MARK: Properties
    @State private var customColor = Color.red
    
    @Environment(\.presentationMode) var presentationMode
    
    let completion: (UIColor) -> Void
    
    // MARK: Initializer
    init(completion: @escaping (UIColor) -> Void) {
        self.completion = completion
    }
    
    // MARK: View
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pick a color")
                .font(.largeTitle)
                .bold()
                .padding()
            
            VStack(alignment: .center, spacing: 16) {
                ForEach(UIColor.timerColors, id: \.self) { timerColor in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(timerColor))
                        .frame(height: 40)
                        .onTapGesture {
                            self.completion(timerColor)
                            self.presentationMode.wrappedValue.dismiss()
                        }
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

struct ColorPicker_Previews: PreviewProvider {
    static var previews: some View {
        TimerColorPicker() { _ in }
    }
}
