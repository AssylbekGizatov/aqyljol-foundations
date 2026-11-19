import Foundation
import FirebaseAuth

final class ResetPasswordViewModel {
    var email: String = "" { didSet { recalc() } }
    
    var isSubmitEnabled: ((Bool) -> Void)?
    var isLoading: ((Bool) -> Void)?
    var errorText: ((String?) -> Void)?
    var onSuccess: ((String) -> Void)?

    private func recalc() {
        let ok = !email.trimmingCharacters(in: .whitespaces).isEmpty
        isSubmitEnabled?(ok)
    }

    func submit() {
        guard !email.isEmpty else { return }
        isLoading?(true); errorText?(nil)
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self else { return }
            self.isLoading?(false)
            if let error = error { self.errorText?(error.localizedDescription); return }
            self.onSuccess?(self.email)
        }
    }
}
