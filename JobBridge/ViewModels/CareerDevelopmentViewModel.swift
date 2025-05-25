import Foundation
import SwiftUI

class CareerDevelopmentViewModel: ObservableObject {
    @Published var recommendations: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadCareerRecommendations(resumeId: Int, jobPostingId: Int) {
        isLoading = true
        errorMessage = nil
        recommendations = []
        
        print("🔵 경력 개발 추천 요청 - resumeId: \(resumeId), jobPostingId: \(jobPostingId)")
        
        Task {
            do {
                let response = try await apiService.getCareerRecommendations(
                    resumeId: resumeId,
                    jobPostingId: jobPostingId
                )
                
                DispatchQueue.main.async {
                    print("🟢 경력 개발 추천 \(response.recommendations.count)개 로드 완료")
                    self.recommendations = response.recommendations
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("🔴 경력 개발 추천 로드 실패: \(error)")
                    
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "경력 개발 가이드를 불러오는 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                }
            }
        }
    }
}
