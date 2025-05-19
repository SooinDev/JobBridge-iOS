import Foundation
import SwiftUI

class ApplicationViewModel: ObservableObject {
    @Published var applications: [ApplicationResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadMyApplications() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("🔵 지원 내역 로드 시작")
                let fetchedApplications = try await apiService.getMyApplications()
                DispatchQueue.main.async {
                    print("🟢 지원 내역 \(fetchedApplications.count)개 로드 완료")
                    
                    // 디버깅: 각 지원 항목 데이터 출력
                    for (index, app) in fetchedApplications.enumerated() {
                        print("📄 지원 #\(index + 1): jobPostingId=\(app.jobPostingId), title=\(app.jobTitle), company=\(app.companyName), date=\(app.appliedAt)")
                    }
                    
                    self.applications = fetchedApplications
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("🔴 지원 내역 로드 실패: \(error)")
                    
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .forbidden(let message):
                            self.errorMessage = message
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        case .decodingError:
                            self.errorMessage = "데이터 형식 오류가 발생했습니다."
                            
                            // 디코딩 오류 시 추가 디버깅 로그
                            print("🔴 디코딩 오류 - 백엔드와 클라이언트 모델 불일치 가능성")
                            print("🔴 ApplicationResponse 모델 구조:")
                            print("   - jobPostingId: Int")
                            print("   - jobTitle: String")
                            print("   - companyName: String")
                            print("   - appliedAt: String(날짜 형식)")
                        default:
                            self.errorMessage = "지원 내역을 불러오는 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                }
            }
        }
    }
}
