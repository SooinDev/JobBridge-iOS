import Foundation
import SwiftUI

class JobViewModel: ObservableObject {
    @Published var jobs: [JobPostingResponse] = []
    @Published var matchingJobs: [JobPostingResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadRecentJobs() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedJobs = try await apiService.getRecentJobs()
                DispatchQueue.main.async {
                    self.jobs = fetchedJobs
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
                            self.errorMessage = "채용공고를 불러오는 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                }
            }
        }
    }
    
    func loadMatchingJobs(resumeId: Int) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedJobs = try await apiService.getMatchingJobs(resumeId: resumeId)
                DispatchQueue.main.async {
                    self.matchingJobs = fetchedJobs
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
                            self.errorMessage = "매칭 결과를 불러오는 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                }
            }
        }
    }
}
