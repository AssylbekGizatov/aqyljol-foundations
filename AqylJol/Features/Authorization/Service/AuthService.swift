import Foundation
import Firebase
import FirebaseAuth

final class AuthService: AuthServicing {
    private let auth: Auth
    private let db: Firestore
    private let userRepo: UserRepository

    init(auth: Auth = Auth.auth(), db: Firestore = Firestore.firestore()) {
        self.auth = auth
        self.db = db
        self.userRepo = UserRepository(db: db)
    }

    // MARK: - Sign In
    func signIn(email: String,
                password: String,
                completion: @escaping (Result<UserRecord, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error { return completion(.failure(error)) }
            guard let self, let user = result?.user else {
                return completion(.failure(NSError(domain: "Auth", code: -1,
                                                   userInfo: [NSLocalizedDescriptionKey: "Unknown auth error"])))
            }
            self.userRepo.fetch(uid: user.uid) { repoResult in
                switch repoResult {
                case .success(let record):
                    UserProfileStore.shared.save(record)
                    completion(.success(record))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }
    }

    // MARK: - Sign Up
    func signUp(email: String,
                password: String,
                firstName: String,
                lastName: String,
                role: String?,
                completion: @escaping (Result<UserRecord, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error { return completion(.failure(error)) }
            guard let self, let user = result?.user else {
                return completion(.failure(NSError(domain: "Auth", code: -1,
                                                   userInfo: [NSLocalizedDescriptionKey: "Unknown auth error"])))
            }
            self.userRepo.create(uid: user.uid,
                                 email: email,
                                 firstName: firstName,
                                 lastName: lastName,
                                 role: role) { repoResult in
                switch repoResult {
                case .success(let record):
                    UserProfileStore.shared.save(record)
                    completion(.success(record))
                case .failure(let err):
                    completion(.failure(err))
                }
            }
        }
    }

    // MARK: - Update Profile
    func updateProfile(firstName: String,
                       lastName: String,
                       role: String?,
                       completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = auth.currentUser?.uid else {
            return completion(.failure(NSError(domain: "Auth",
                                               code: 401,
                                               userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])))
        }

        userRepo.updateProfile(uid: uid,
                               firstName: firstName,
                               lastName: lastName,
                               role: role) { error in
            if let error = error { return completion(.failure(error)) }
            if var local = UserProfileStore.shared.load() {
                local.firstName = firstName
                local.lastName = lastName
                local.role = role
                UserProfileStore.shared.save(local)
            }

            completion(.success(()))
        }
    }

    // MARK: - Sign Out
    func signOut() throws {
        try auth.signOut()
        UserProfileStore.shared.clear()
    }
}
