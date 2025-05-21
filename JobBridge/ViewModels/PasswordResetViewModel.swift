import Foundation
import SwiftUI

class PasswordResetViewModel: ObservableObject {
    @Published var email = ""
    @Published var resetToken = ""
    @Published var newPassword = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showResetForm = false // 이메일 제출 후 토큰 입력 및 새 비밀번호 설정 폼으로 전환
    
    private let apiService = APIService.shared
    
    func requestPasswordReset() {
        if email.isEmpty {
            errorMessage = "이메일을 입력해주세요."
            return
        }
        
        // 이메일 형식 검증
        if !isValidEmail(email) {
            errorMessage = "유효한 이메일 주소를 입력해주세요."
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                let message = try await apiService.requestPasswordReset(email: email)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.successMessage = message
                    self.showResetForm = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "비밀번호 재설정 요청 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                }
            }
        }
    }
    
    func resetPassword() {
        if resetToken.isEmpty {
            errorMessage = "비밀번호 재설정 코드를 입력해주세요."
            return
        }
        
        if newPassword.isEmpty || confirmPassword.isEmpty {
            errorMessage = "새 비밀번호를 입력해주세요."
            return
        }
        
        if newPassword != confirmPassword {
            errorMessage = "비밀번호가 일치하지 않습니다."
            return
        }
        
        // 비밀번호 강도 검증
        if newPassword.count < 8 {
            errorMessage = "비밀번호는 8자 이상이어야 합니다."
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        Task {
            do {
                let message = try await apiService.resetPassword(token: resetToken, newPassword: newPassword)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.successMessage = message
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "비밀번호 변경 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                }
            }
        }
    }
    
    // 간단한 이메일 형식 검증
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}
