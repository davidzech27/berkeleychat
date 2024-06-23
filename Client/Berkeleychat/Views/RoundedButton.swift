//
//  Button.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import SwiftUI

struct RoundedButton: View {
    let solid: Bool
    let text: String
    let loading: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(_ text: String, solid: Bool = true, loading: Bool = false, action: @escaping () -> Void) {
        self.text = text
        self.solid = solid
        self.loading = loading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            if !loading {
                Text(text)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in

                                if !isPressed {
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        isPressed = true
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    isPressed = false
                                }

                                action()
                            }
                    )

            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 48)
        .background(solid ? .white : .clear)
        .foregroundColor(solid ? .black : .white)
        .font(.system(size: 16, weight: .semibold))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .transition(.blurReplace)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }

                    action()
                }
        )
        .opacity((isPressed && !loading) ? 0.8 : 1.0)
    }
}

#Preview {
    RoundedButton("asdf") {}
}
