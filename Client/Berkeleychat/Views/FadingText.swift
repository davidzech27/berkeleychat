//
//  FadingText.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import SwiftUI

struct FadingText: View {
    let text: String
    let animationDelay: Double = 0.01
    @State private var animate = false

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, letter in
                Text(String(letter)).fixedSize()
                    .opacity(animate ? 1 : 0)
                    .blur(radius: animate ? 0 : 20)
                    .animation(
                        .easeInOut(duration: 1).delay(Double(index) * animationDelay),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}

#Preview {
    FadingText("asdfasdf")
}
