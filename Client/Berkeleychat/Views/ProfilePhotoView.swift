//
//  ProfilePhotoView.swift
//  Berkeleychat
//
//  Created by David Zechowy on 6/22/24.
//

import AVFoundation
import PhotosUI
import SwiftUI

struct FlipFromBottom: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                isActive ? Angle(degrees: -30) : Angle(degrees: 0),
                axis: (x: 1.0, y: 0.0, z: 0.0),
                anchor: UnitPoint(x: 0.5, y: -0.5),
                perspective: 1
            )
            .opacity(isActive ? 0 : 1)
            .blur(radius: isActive ? 128 : 0)
    }
}

extension AnyTransition {
    static var flipFromBottom: AnyTransition {
        .modifier(
            active: FlipFromBottom(isActive: true),
            identity: FlipFromBottom(isActive: false)
        ).animation(timingCurve)
    }
}

struct ProfilePhotoView: View {
    @Environment(Model.self) var model

    let accessToken: String
    let email: String
    let name: String

    @State private var profilePhoto: UIImage?
    @State private var profilePhotoUrl: String?
    @State private var showingCamera = false
    @State private var showingPhotoPicker = false

    private var uploadingProfilePhoto: Bool {
        profilePhoto != nil && profilePhotoUrl == nil
    }

    private func onSetProfilePhoto(profilePhoto: UIImage) {
        Task {
            profilePhotoUrl = try await model.grpc.uploadPhoto(photo: profilePhoto, accessToken: accessToken)
        }
    }

    private func onContinue() {
        model.auth.localUser?.profilePhotoUrl = profilePhotoUrl
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            let firstName = name.split(separator: " ").first ?? ""
            let lastName = name.split(separator: " ").last ?? ""
            let fullName = "\(firstName) \(lastName)"

            let startOfEmail = email.split(separator: "@").first ?? ""

            VStack(alignment: profilePhoto == nil ? .center : .leading, spacing: 8) {
                if let profilePhoto = profilePhoto {
                    VStack(alignment: .leading, spacing: 16) {
                        Image(uiImage: profilePhoto)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(fullName)
                                .foregroundColor(.white)
                                .font(.title3)
                                .bold()

                            Text("@\(startOfEmail)")
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .opacity(0.75)
                        }
                    }
                    .transition(.flipFromBottom)
                } else {
                    FadingText("Hello, \(firstName).")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .bold()

                    FadingText("Let's see your profile photo.")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .opacity(0.75)
                }

                Spacer()

                if profilePhoto == nil {
                    RoundedButton("Choose from library", solid: false) {
                        showingPhotoPicker = true
                    }

                    RoundedButton("Take a photo") {
                        showingCamera = true
                    }
                } else {
                    RoundedButton("Change photo", solid: false) {
                        profilePhoto = nil
                    }

                    RoundedButton("Continue", loading: uploadingProfilePhoto) {
                        onContinue()
                    }
                }
            }
            .padding(16)
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $profilePhoto)
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPicker(selectedImage: $profilePhoto)
            }
        }.onChange(of: profilePhoto) { _, profilePhoto in
            guard let profilePhoto = profilePhoto else {
                return
            }

            onSetProfilePhoto(profilePhoto: profilePhoto)
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_: PHPickerViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.selectedImage = image as? UIImage
                    }
                }
            }
        }
    }
}
