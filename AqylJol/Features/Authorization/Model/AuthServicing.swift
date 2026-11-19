import Foundation

protocol AuthServicing {
    func signIn(email: String, password: String, completion: @escaping (Result<UserRecord, Error>) -> Void)
    func signUp(email: String, password: String, firstName: String, lastName: String, role: String?, completion: @escaping (Result<UserRecord, Error>) -> Void)
}
