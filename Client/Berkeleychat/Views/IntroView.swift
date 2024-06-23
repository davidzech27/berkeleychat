//
//  IntroView.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import AVFoundation
import SwiftUI

struct IntroView: View {
    @Environment(Model.self) var model

    let accessToken: String
    let email: String
    let name: String
    let profilePhotoUrl: String
    let major: String
    let courses: [String]

    @State private var audioRecorder = AudioRecorder()
    @State private var intro: Data?
    @State private var introUrl: String?

    @State private var isCreatingAccount = false

    private func startRecording() {
        audioRecorder.startRecording()
    }

    private func stopRecording() {
        intro = audioRecorder.stopRecording()

        Task {
            introUrl = try await model.grpc.uploadAudio(audio: intro!, accessToken: accessToken)
        }
    }

    private func onContinue() {
        isCreatingAccount = true
        Task {
            try await model.grpc.createAccount(accessToken: accessToken, email: email, name: name, profilePhotoUrl: profilePhotoUrl, major: major, courses: courses, introUrl: introUrl!)

            model.auth.localUser?.introUrl = introUrl
        }
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 8) {
                FadingText("Record your intro.")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .bold()

                VStack(spacing: 2) {
                    FadingText("Press and hold to start recording an")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .opacity(0.75)
                    FadingText("audio message for your profile.")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .opacity(0.75)
                }

                Spacer()

                if audioRecorder.isRecording {
                    VStack(spacing: 8) {
                        Text("Recording").foregroundColor(.white).fontWeight(.semibold).font(.title3)

                        Text("\(audioRecorder.recordingSeconds) seconds").foregroundColor(.white.opacity(0.75)).font(.title3)
                    }
                    .transition(.flipFromBottom)
                }

                if intro != nil {
                    VStack(spacing: 8) {
                        Text("Recorded").foregroundColor(.white).fontWeight(.semibold).font(.title3)

                        Text(audioRecorder.formattedTime()).foregroundColor(.white.opacity(0.75)).font(.title3)
                    }
                }

                Spacer()

                if intro == nil {
                    RoundedButton(!audioRecorder.isRecording ?"Start recording" : "Release to stop recording") {
                        stopRecording()
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onChanged { _ in
                                startRecording()
                            }
                    )
                } else {
                    RoundedButton("Continue", loading: introUrl == nil || isCreatingAccount) {
                        onContinue()
                    }
                }
            }
            .padding(16)
        }
    }
}

@Observable
class AudioRecorder {
    var isRecording = false
    var recordingSeconds = 0
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var timer: Timer?

    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording.mp3")

            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEGLayer3,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                AVEncoderBitRateKey: 128_000,
            ]

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()

            recordingURL = audioFilename
            isRecording = true
            recordingSeconds = 0

            startTimer()
        } catch {
            print("Could not start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() -> Data? {
        audioRecorder?.stop()
        isRecording = false
        stopTimer()

        guard let url = recordingURL else { return nil }
        do {
            let data = try Data(contentsOf: url)
            // Optional: Delete the temporary file after reading
            try FileManager.default.removeItem(at: url)
            return data
        } catch {
            print("Error reading audio data: \(error.localizedDescription)")
            return nil
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.recordingSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func formattedTime() -> String {
        let minutes = recordingSeconds / 60
        let seconds = recordingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// #Preview {
//    // IntroView(accessToken: "")
// }
