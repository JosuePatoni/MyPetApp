import Foundation
import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class EditProfileViewModel {
    var username: String
    var currentPassword = ""
    var newPassword = ""
    var confirmPassword = ""
    var photoItem: PhotosPickerItem?
    private(set) var photoData: Data?
    var errorMessage: String?

    init(user: User) {
        username = user.username
        photoData = user.photoData
    }

    func loadPhoto() async {
        guard let photoItem,
              let data = try? await photoItem.loadTransferable(type: Data.self)
        else { return }
        photoData = ImageDownscaler.jpegData(from: data)
    }

    /// Si la contraseña nueva queda vacía, se conserva la actual.
    func save(user: User, auth: AuthService, session: SessionStore) -> Bool {
        do {
            errorMessage = nil
            try auth.updateProfile(
                user,
                username: username,
                photoData: photoData,
                currentPassword: currentPassword,
                newPassword: newPassword,
                confirmPassword: confirmPassword
            )
            // Actualiza el nombre guardado en Keychain para que la sesión se restaure con el nuevo.
            session.signIn(user)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
