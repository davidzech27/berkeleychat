//
//  MajorView.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import SwiftUI

let majors = [
    "Computer Science",
    "Engineering (General)",
    "Mechanical Engineering",
    "Electrical Engineering",
    "Chemical Engineering",
    "Biology",
    "Physics",
    "Mathematics",
    "Information Technology",
    "Data Science",
    "Chemistry",
    "Aerospace Engineering",
    "Civil Engineering",
    "Biotechnology",
    "Business Administration and Management",
    "Nursing",
    "Psychology",
    "Economics",
    "Accounting",
    "Finance"
  ]

struct MajorView: View {
    @Environment(Model.self) var model

    @State private var major = majors.first!

    private func onContinue() {
        model.auth.localUser?.major = major
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 8) {
                FadingText("What's your major?")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()

                FadingText("Select the major most relevant to you.")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .opacity(0.75)
                

                

                Spacer()

                Picker("Major", selection: $major) {
                    ForEach(majors, id: \.self) { major in
                        Text(major)
                            .tag(major)
                    }
                }
                .foregroundColor(.white)
                .pickerStyle(.wheel)

                Spacer()

                RoundedButton("Continue") {
                    onContinue()
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    MajorView()
}
