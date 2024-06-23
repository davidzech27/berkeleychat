//
//  CoursesView.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import SwiftUI

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct CoursesView: View {
    @Environment(Model.self) var model

    @State private var selectedCourses: [String] = []
    @State private var query = ""
    @FocusState private var queryFocusState
    @State private var isQueryFocused = false

    private func onContinue() {
        model.auth.localUser?.courses = selectedCourses
    }

    var body: some View {
        let searchedCourses = query.isEmpty ? courses : courses.filter { $0.lowercased().contains(query.lowercased()) }

        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 8) {
                FadingText("Select your courses")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()

                TextField("", text: $query)
                    .placeholder(when: query.isEmpty) {
                        Text("Search courses").foregroundColor(.white.opacity(isQueryFocused ? 0.75 : 0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(isQueryFocused ? 0.2 : 0.1))
                    )
                    .foregroundColor(.white)
                    .focused($queryFocusState)
                    .onChange(of: queryFocusState) { _, newValue in
                        withAnimation(timingCurve) {
                            isQueryFocused = newValue
                        }
                    }

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(searchedCourses, id: \.self) { course in
                            VStack {
                                HStack {
                                    Button(action: {
                                        if !selectedCourses.contains(course) {
                                            selectedCourses.append(course)
                                        } else {
                                            selectedCourses.removeAll { $0 == course }
                                        }
                                    }) {
                                        Text(course)
                                            .foregroundColor(.white)
                                    }

                                    Spacer()

                                    if selectedCourses.contains(course) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .semibold)).transition(.opacity)
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                )
                                .font(.system(size: 16, weight: .semibold))
                            }
                        }
                    }
                }
                .padding(.vertical, 16)

                RoundedButton("Continue") {
                    onContinue()
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    CoursesView()
}
