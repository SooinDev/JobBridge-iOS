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
    @Published var showResetForm = false

    private let apiService = APIService.shared

    func requestPasswordReset() {
        guard !email.isEmpty else {
            self.errorMessage = "이메일을 입력해주세요."
            return
        }

        guard isValidEmail(email) else {
            self.errorMessage = "유효한 이메일 주소를 입력해주세요."
            return
        }

        self.isLoading = true
        self.errorMessage = nil
        self.successMessage = nil

        let currentEmail = email

        apiService.requestPasswordReset(email: currentEmail) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let message):
                    self.successMessage = message
                    self.showResetForm = true
                case .failure(let error):
                    self.handleAPIError(error)
                }
            }
        }
    }

    func resetPassword(onSuccess: @escaping () -> Void) {
        guard !resetToken.isEmpty else {
            self.errorMessage = "비밀번호 재설정 코드를 입력해주세요."
            return
        }

        guard !newPassword.isEmpty, !confirmPassword.isEmpty else {
            self.errorMessage = "새 비밀번호를 입력해주세요."
            return
        }

        guard newPassword == confirmPassword else {
            self.errorMessage = "비밀번호가 일치하지 않습니다."
            return
        }

        guard newPassword.count >= 8 else {
            self.errorMessage = "비밀번호는 8자 이상이어야 합니다."
            return
        }

        self.isLoading = true
        self.errorMessage = nil
        self.successMessage = nil

        apiService.resetPassword(token: resetToken, newPassword: newPassword) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let message):
                    self.successMessage = message
                    onSuccess() // ✅ 성공 시 클로저 실행
                case .failure(let error):
                    self.handleAPIError(error)
                }
            }
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    private func handleAPIError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .serverError(let message):
                if message.contains("존재하지") || message.contains("찾을 수 없습니다") {
                    self.errorMessage = "등록되지 않은 이메일입니다."
                } else if message.contains("유효하지") || message.contains("invalid") {
                    self.errorMessage = "유효하지 않은 재설정 코드입니다."
                } else if message.contains("만료") || message.contains("expired") {
                    self.errorMessage = "재설정 코드가 만료되었습니다. 새로운 코드를 요청해주세요."
                } else {
                    self.errorMessage = message
                }
            case .unknown:
                self.errorMessage = "네트워크 연결을 확인해주세요."
            default:
                self.errorMessage = "요청 중 오류가 발생했습니다."
            }
        } else {
            self.errorMessage = "네트워크 오류가 발생했습니다."
        }
    }
}
