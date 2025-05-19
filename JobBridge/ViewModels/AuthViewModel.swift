import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: LoginResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    init() {
        // 앱 시작 시 토큰 존재 여부 확인
        if UserDefaults.standard.string(forKey: "authToken") != nil {
            self.isAuthenticated = true
            // 필요한 경우 사용자 정보 로드
        }
    }
    
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await apiService.login(email: email, password: password)
                DispatchQueue.main.async {
                    self.currentUser = response
                    self.isAuthenticated = true
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "이메일 또는 비밀번호가 올바르지 않습니다."
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "로그인 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                }
            }
        }
    }
    
    func signup(name: String, email: String, password: String, address: String, age: String, phone: String, userType: String) {
        isLoading = true
        errorMessage = nil
        
        // 입력 유효성 검사
        if name.isEmpty || email.isEmpty || password.isEmpty {
            errorMessage = "필수 항목을 모두 입력해주세요"
            isLoading = false
            return
        }
        
        let ageInt = Int(age) ?? 0
        
        let request = SignupRequest(
            pw: password,
            name: name,
            address: address,
            age: ageInt > 0 ? ageInt : nil,
            email: email,
            phonenumber: phone,
            userType: userType
        )
        
        Task {
            do {
                let message = try await apiService.signup(request: request)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = nil
                    // 회원가입 성공 후 처리 (예: 알림 표시)
                    print("회원가입 성공: \(message)")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "회원가입 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                }
            }
        }
    }
    
    func logout() {
        apiService.logout()
        currentUser = nil
        isAuthenticated = false
    }
    
    func sendVerificationCode(email: String, completion: @escaping (Result<String, Error>) -> Void) {
        isLoading = true
        
        Task {
            do {
                let message = try await APIService.shared.sendVerificationCode(email: email)
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(.success(message))
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "인증코드 발송 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    completion(.failure(error))
                }
            }
        }
    }

    func verifyCode(email: String, code: String, completion: @escaping (Result<String, Error>) -> Void) {
        isLoading = true
        
        Task {
            do {
                let message = try await APIService.shared.verifyCode(email: email, code: code)
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(.success(message))
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "인증코드 확인 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = error.localizedDescription
                    }
                    completion(.failure(error))
                }
            }
        }
    }
}
