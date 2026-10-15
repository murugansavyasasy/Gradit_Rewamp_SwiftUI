//
//  EditProfileView.swift
//  Gradit
//
//  Design: 01 Common › Profile and Settings › Edit profile (+ Photo sheet).
//  Mobile number is read-only ("Registered with the college").
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(ProfileStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var birthDate: Date?
    @State private var didLoad = false
    @State private var showPhotoSheet = false
    @State private var showDatePicker = false
    @State private var showCamera = false
    @State private var galleryItem: PhotosPickerItem?
    @FocusState private var focusedField: Field?

    private enum Field { case name, email }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                avatarButton
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                ProfileField(label: String(localized: "Full name"), isFocused: focusedField == .name) {
                    TextField("", text: $fullName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.next)
                        .focused($focusedField, equals: .name)
                        .onSubmit { focusedField = .email }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Mobile number")
                        .font(AppFont.jakarta(13, .semibold))
                        .foregroundStyle(Theme.Colors.ink700)
                    HStack(spacing: 10) {
                        Image(systemName: "phone")
                            .font(.system(size: 15))
                        Text(store.profile?.mobile ?? "—")
                            .font(AppFont.jakarta(15))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(Theme.Colors.ink500)
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(Theme.Colors.divider, in: .rect(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.line))
                    Text("Registered with the college · contact the office to change")
                        .font(AppFont.jakarta(12))
                        .foregroundStyle(Theme.Colors.ink500)
                }
                .accessibilityElement(children: .combine)

                ProfileField(label: String(localized: "Email"), isFocused: focusedField == .email) {
                    TextField("", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .focused($focusedField, equals: .email)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Date of birth")
                        .font(AppFont.jakarta(13, .semibold))
                        .foregroundStyle(Theme.Colors.ink700)
                    Button {
                        focusedField = nil
                        showDatePicker = true
                    } label: {
                        HStack {
                            Text(birthDate.map { $0.formatted(.dateTime.day(.twoDigits).month(.abbreviated).year()) } ?? String(localized: "Add date of birth"))
                                .font(AppFont.jakarta(15))
                                .foregroundStyle(birthDate == nil ? Theme.Colors.ink500 : Theme.Colors.ink900)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.Colors.chevron)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(Theme.Colors.white, in: .rect(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Theme.Colors.inputBorder))
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Date of birth")
                    .accessibilityValue(birthDate.map { $0.formatted(date: .long, time: .omitted) } ?? "Not set")
                }

                if let error = store.errorMessage {
                    ErrorBanner(message: error)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Save changes", isLoading: store.isSaving, isEnabled: hasChanges, action: save)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Theme.Colors.surfaceMuted)
        }
        .background(Theme.Colors.surfaceMuted.ignoresSafeArea())
        .navigationTitle("Edit profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if store.profile == nil { await store.loadProfile() }
            fillFromProfile()
        }
        .onChange(of: store.profile) { fillFromProfile() }
        .onAppear { store.errorMessage = nil }
        .sheet(isPresented: $showPhotoSheet) {
            PhotoOptionsSheet(
                hasPhoto: store.profile?.photoURL != nil,
                galleryItem: $galleryItem,
                onTakePhoto: {
                    showPhotoSheet = false
                    showCamera = true
                },
                onRemove: {
                    showPhotoSheet = false
                    Task { await store.removePhoto() }
                }
            )
        }
        .sheet(isPresented: $showDatePicker) {
            BirthDateSheet(date: $birthDate)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                showCamera = false
                if let data = image?.jpegData(compressionQuality: 0.8) {
                    Task { await store.uploadPhoto(jpegData: data) }
                }
            }
            .ignoresSafeArea()
        }
        .onChange(of: galleryItem) { _, item in
            guard let item else { return }
            showPhotoSheet = false
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data),
                   let jpeg = image.jpegData(compressionQuality: 0.8) {
                    await store.uploadPhoto(jpegData: jpeg)
                }
                galleryItem = nil
            }
        }
    }

    private var avatarButton: some View {
        Button {
            focusedField = nil
            showPhotoSheet = true
        } label: {
            ProfileAvatar(
                name: fullName.isEmpty ? (store.profile?.fullName ?? "") : fullName,
                photoURL: store.profile?.photoURL,
                size: 96,
                background: Color(hex: 0xE3EAFB)
            )
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "camera")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.white)
                    .frame(width: 34, height: 34)
                    .background(Theme.Colors.blue600, in: Circle())
                    .overlay(Circle().strokeBorder(Theme.Colors.surfaceMuted, lineWidth: 3))
                    .offset(x: 2, y: 2)
            }
            .overlay {
                if store.isSaving { ProgressView() }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Change profile photo")
    }

    private var hasChanges: Bool {
        guard let profile = store.profile else { return false }
        return fullName.trimmed != profile.fullName
            || email.trimmed != (profile.email ?? "")
            || birthDate != profile.birthDate
    }

    private func fillFromProfile() {
        guard !didLoad, let profile = store.profile else { return }
        fullName = profile.fullName
        email = profile.email ?? ""
        birthDate = profile.birthDate
        didLoad = true
    }

    private func save() {
        focusedField = nil
        Task {
            if await store.saveProfile(fullName: fullName, email: email, birthDate: birthDate) {
                dismiss()
            }
        }
    }
}

/// Label + 52 pt field with the design's 14 pt radius and focus border.
private struct ProfileField<Content: View>: View {
    let label: String
    let isFocused: Bool
    @ViewBuilder let field: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(AppFont.jakarta(13, .semibold))
                .foregroundStyle(Theme.Colors.ink700)
            field
                .font(AppFont.jakarta(15))
                .foregroundStyle(Theme.Colors.ink900)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Theme.Colors.white, in: .rect(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(isFocused ? Theme.Colors.blue600 : Theme.Colors.inputBorder, lineWidth: isFocused ? 2 : 1)
                }
                .accessibilityLabel(label)
        }
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

/// "Profile photo" bottom sheet: Take photo · Choose from gallery · Remove photo · Cancel.
private struct PhotoOptionsSheet: View {
    let hasPhoto: Bool
    @Binding var galleryItem: PhotosPickerItem?
    let onTakePhoto: () -> Void
    let onRemove: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var cameraAvailable: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }

    var body: some View {
        VStack(spacing: 8) {
            Text("Profile photo")
                .font(AppFont.jakarta(18, .heavy))
                .foregroundStyle(Theme.Colors.ink900)
                .padding(.top, 6)
                .padding(.bottom, 4)

            VStack(spacing: 0) {
                if cameraAvailable {
                    SheetRow(title: String(localized: "Take photo"), systemImage: "camera", action: onTakePhoto)
                    Divider().overlay(Theme.Colors.divider)
                }
                PhotosPicker(selection: $galleryItem, matching: .images, photoLibrary: .shared()) {
                    SheetRowLabel(title: String(localized: "Choose from gallery"), systemImage: "photo")
                }
                .buttonStyle(.plain)
                if hasPhoto {
                    Divider().overlay(Theme.Colors.divider)
                    SheetRow(title: String(localized: "Remove photo"), systemImage: "trash", isDestructive: true, action: onRemove)
                }
            }

            Button("Cancel") { dismiss() }
                .font(AppFont.jakarta(16, .bold))
                .foregroundStyle(Theme.Colors.ink900)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Theme.Colors.white, in: .rect(cornerRadius: Theme.Radius.button))
                .overlay(RoundedRectangle(cornerRadius: Theme.Radius.button).strokeBorder(Theme.Colors.inputBorder))
                .buttonStyle(.plain)
                .padding(.top, 8)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .presentationDetents([.height(hasPhoto ? 340 : 290)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(Theme.Radius.sheet)
    }
}

private struct SheetRow: View {
    let title: String
    let systemImage: String
    var isDestructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SheetRowLabel(title: title, systemImage: systemImage, isDestructive: isDestructive)
        }
        .buttonStyle(.plain)
    }
}

private struct SheetRowLabel: View {
    let title: String
    let systemImage: String
    var isDestructive = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isDestructive ? Theme.Colors.destructive : Theme.Colors.blue600)
                .frame(width: 32, height: 32)
                .background(isDestructive ? Theme.Colors.errorBackground : Theme.Colors.blue50, in: .rect(cornerRadius: 10))
            Text(title)
                .font(AppFont.jakarta(15, .medium))
                .foregroundStyle(isDestructive ? Theme.Colors.destructive : Theme.Colors.ink900)
            Spacer()
            if !isDestructive {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Colors.chevron)
            }
        }
        .frame(minHeight: 56)
        .contentShape(.rect)
    }
}

private struct BirthDateSheet: View {
    @Binding var date: Date?
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Date

    init(date: Binding<Date?>) {
        _date = date
        let fallback = Calendar.current.date(byAdding: .year, value: -18, to: .now) ?? .now
        _draft = State(initialValue: date.wrappedValue ?? fallback)
    }

    var body: some View {
        NavigationStack {
            DatePicker("Date of birth", selection: $draft, in: ...Date.now, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Theme.Colors.blue600)
                .padding(.horizontal, 16)
                .navigationTitle("Date of birth")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            date = draft
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Camera capture via UIImagePickerController (requires NSCameraUsageDescription).
private struct CameraPicker: UIViewControllerRepresentable {
    let onFinish: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraDevice = .front
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinish: (UIImage?) -> Void

        init(onFinish: @escaping (UIImage?) -> Void) {
            self.onFinish = onFinish
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            onFinish((info[.editedImage] ?? info[.originalImage]) as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish(nil)
        }
    }
}

#Preview {
    NavigationStack { EditProfileView() }
        .environment(ProfileStore(role: .parent, service: MockProfileService()))
}
