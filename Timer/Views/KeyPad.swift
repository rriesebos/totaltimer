////  KeyPad.swift
//  Timer
//
//  Created by R Riesebos on 25/06/2020.
//  Copyright © 2020 rriesebos. All rights reserved.
//

import SwiftUI

struct KeyPad: View {
    
    // MARK: Properties
    var action: (Key) -> Void
    
    
    init(action: @escaping (Key) -> Void) {
        self.action = action
    }

    // MARK: View
    var body: some View {
        VStack(alignment: .center, spacing: 32) {
            HStack(alignment: .center) {
                KeyPadButton(action: self.action, key: Key.numerical(1))
                Spacer()
                KeyPadButton(action: self.action, key: Key.numerical(2))
                Spacer()
                KeyPadButton(action: self.action, key: Key.numerical(3))
            }
            HStack(alignment: .center) {
                KeyPadButton(action: self.action, key: Key.numerical(4))
                Spacer()
                KeyPadButton(action: self.action, key: Key.numerical(5))
                Spacer()
                KeyPadButton(action: self.action, key: Key.numerical(6))
            }
            HStack(alignment: .center) {
                KeyPadButton(action: self.action, key: Key.numerical(7))
                Spacer()
                KeyPadButton(action: self.action, key: Key.numerical(8))
                Spacer()
                KeyPadButton(action: self.action, key: Key.numerical(9))
            }
            HStack(alignment: .center) {
                KeyPadButton(action: self.action, key: Key.clear)
                Spacer()
                KeyPadButton(action: self.action, key: Key.numerical(0))
                Spacer()
                KeyPadButton(action: self.action, key: Key.delete)
            }
        }
        .font(.system(size: 36))
    }
}

enum Key {
    case numerical(Int)
    case delete
    case clear
}

struct KeyPadButton: View {
    
    // MARK: Properties
    private let maxInputLength = 2
    
    let action: (Key) -> Void
    let key: Key
    
    
    // MARK: Methods
    private func keyWasPressed() {
        self.action(self.key)
    }
    
    // TODO: Convert to swift case in SwiftUI 2
    private func buttonValue() -> AnyView {
        switch self.key {
        case let Key.numerical(value):
            return AnyView(Text(String(value))
                .frame(width: 40, height: 40, alignment: .center))
        case Key.delete:
            return AnyView(Image(systemName: "delete.left")
                .font(.system(size: 28))
                .frame(width: 40, height: 40, alignment: .center))
        case Key.clear:
            return AnyView(Image(systemName: "clear")
                .font(.system(size: 28))
                .frame(width: 40, height: 40, alignment: .center))
        }
    }

    // MARK: View
    var body: some View {
        Button(action: self.keyWasPressed) {
            self.buttonValue()
        }
    }
}

struct KeyPad_Previews: PreviewProvider {
    static var previews: some View {
        KeyPad(action: {_ in })
    }
}
