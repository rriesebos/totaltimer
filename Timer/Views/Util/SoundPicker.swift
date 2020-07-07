////  SoundPicker.swift
//  Timer
//
//  Created by R Riesebos on 07/07/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import SwiftUI

struct SoundPicker: View {
    
    private var sounds: [Sound] = []
    @Binding private var sound: Sound
    
    
    init(sounds: [Sound], sound: Binding<Sound>) {
        self.sounds = sounds
        self._sound = sound
    }
    
    var body: some View {
        NavigationLink(self.sound.displayName, destination: PickerView(sounds: self.sounds, sound: self.$sound))
    }
}

struct SoundPicker_Previews: PreviewProvider {
    static var previews: some View {
        SoundPicker(sounds: [Sound(name: "Default"), Sound(name: "Spring")], sound: .constant(Sound(name: "Default")))
    }
}

struct PickerView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    private var sounds: [Sound] = []
    @Binding private var sound: Sound
    
    @State private var selectedSound: Sound
    
    
    init(sounds: [Sound], sound: Binding<Sound>) {
        self.sounds = sounds
        
        self._sound = sound
        self._selectedSound = State(initialValue: sound.wrappedValue)
    }
    
    private func select(sound: Sound) {
        self.selectedSound.stop()
        
        self.selectedSound = sound
        self.selectedSound.play()
    }
    
    private func save() {
        self.sound = self.selectedSound
        self.presentationMode.wrappedValue.dismiss()
    }
    
    var body: some View {
        List {
            ForEach(self.sounds, id: \.self) { sound in
                HStack {
                    Text(sound.displayName)
                    Spacer()
                    if sound.name == self.selectedSound.name {
                        Image(systemName: "checkmark")
                            .foregroundColor(Color.accentColor)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.linear(duration: 0.06)) {
                        self.select(sound: sound)
                    }
                }
            }
        }
        .onDisappear {
            self.selectedSound.stop()
        }
        .navigationBarItems(trailing: Button(action: self.save) {
            Text("Done")
        })
    }
}
