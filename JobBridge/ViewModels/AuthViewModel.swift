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
            // 저장된 사용자 정보가 있다면 로드
            loadSavedUserInfo()
        }
    }
    
    // 저장된 사용자 정보 로드
    private func loadSavedUserInfo() {
        let name = UserDefaults.standard.string(forKey: "userName") ?? ""
        let email = UserDefaults.standard.string(forKey: "userEmail") ?? ""
        let userType = UserDefaults.standard.string(forKey: "userType") ?? ""
        
        if !name.isEmpty && !email.isEmpty && !userType.isEmpty {
            // 저장된 정보로 사용자 객체 생성
            self.currentUser = LoginResponse(
                token: UserDefaults.standard.string(forKey: "authToken") ?? "",
                name: name,
                email: email,
                userType: userType
            )
        }
    }
    
    func login(email: String, password: String, rememberMe: Bool = false) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let response = try await apiService.login(email: email, password: password, rememberMe: rememberMe)
                DispatchQueue.main.async {
                    self.currentUser = response
                    self.isAuthenticated = true
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        // errorMessage 속성 사용
                        self.errorMessage = apiError.errorMessage
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
