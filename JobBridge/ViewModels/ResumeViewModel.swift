import Foundation
import SwiftUI

class ResumeViewModel: ObservableObject {
    @Published var resumes: [ResumeResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadResumes() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedResumes = try await apiService.getMyResumes()
                DispatchQueue.main.async {
                    self.resumes = fetchedResumes
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "이력서를 불러오는 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                }
            }
        }
    }
    
    func createResume(title: String, content: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let request = ResumeRequest(title: title, content: content)
        
        Task {
            do {
                let newResume = try await apiService.createResume(request: request)
                DispatchQueue.main.async {
                    self.resumes.insert(newResume, at: 0)
                    self.isLoading = false
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "이력서를 생성하는 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                    completion(false)
                }
            }
        }
    }
}
