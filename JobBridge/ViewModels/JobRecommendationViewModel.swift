// JobRecommendationViewModel.swift - 개인회원용 채용공고 추천 뷰모델
import Foundation
import SwiftUI

@MainActor
class JobRecommendationViewModel: ObservableObject {
    @Published var myResumes: [ResumeResponse] = []
    @Published var recommendedJobs: [JobRecommendationResponse] = []
    @Published var isLoading = false
    @Published var isRecommendationInProgress = false
    @Published var errorMessage: String?
    @Published var lastRecommendedResumeId: Int?
    
    private let apiService = APIService.shared
    
    // MARK: - 내 이력서 로드
    func loadMyResumes() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let resumes = try await apiService.getMyResumes()
                
                await MainActor.run {
                    self.myResumes = resumes
                    self.isLoading = false
                    
                    print("🟢 개인 이력서 \(resumes.count)개 로드 완료")
                    
                    for (index, resume) in resumes.enumerated() {
                        print("📄 이력서 #\(index + 1): \(resume.title)")
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.handleError(error, context: "이력서 로드")
                }
            }
        }
    }
    
    // MARK: - AI 채용공고 추천 시작
    func startJobRecommendation(for resume: ResumeResponse) {
        // 개인 회원 권한 확인
        guard UserDefaults.standard.string(forKey: "userType") == "INDIVIDUAL" else {
            self.errorMessage = "개인 회원만 사용할 수 있는 기능입니다."
            print("⛔️ 개인 회원이 아니므로 추천 기능 제한")
            return
        }
        
        isRecommendationInProgress = true
        errorMessage = nil
        recommendedJobs = []
        
        print("🔵 AI 채용공고 추천 시작 - 이력서: \(resume.title) (ID: \(resume.id))")
        print("🔵 현재 사용자 타입: \(UserDefaults.standard.string(forKey: "userType") ?? "없음")")
        
        Task {
            do {
                let recommendations = try await apiService.getJobRecommendations(resumeId: resume.id)
                
                await MainActor.run {
                    self.recommendedJobs = recommendations
                    self.isRecommendationInProgress = false
                    self.lastRecommendedResumeId = resume.id
                    
                    print("🟢 AI 채용공고 추천 완료 - \(recommendations.count)개 결과")
                    
                    for (index, job) in recommendations.enumerated() {
                        print("📋 추천 #\(index + 1): \(job.title) - \(Int(job.matchScore * 100))% 매치 (\(job.companyName))")
                    }
                    
                    let highMatchCount = recommendations.filter { $0.matchScore >= 0.8 }.count
                    let mediumMatchCount = recommendations.filter { $0.matchScore >= 0.6 && $0.matchScore < 0.8 }.count
                    let lowMatchCount = recommendations.filter { $0.matchScore < 0.6 }.count
                    
                    print("📊 추천 통계:")
                    print("   - 높은 적합도 (80% 이상): \(highMatchCount)개")
                    print("   - 보통 적합도 (60-79%): \(mediumMatchCount)개")
                    print("   - 낮은 적합도 (60% 미만): \(lowMatchCount)개")
                    
                    if let topMatch = recommendations.first {
                        print("🏆 최고 추천: \(topMatch.title) (\(Int(topMatch.matchScore * 100))%)")
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isRecommendationInProgress = false
                    self.handleError(error, context: "AI 채용공고 추천")
                }
            }
        }
    }
    
    // MARK: - Mock 추천 (테스트용)
    func startMockJobRecommendation(for resume: ResumeResponse) {
        isRecommendationInProgress = true
        errorMessage = nil
        recommendedJobs = []
        
        print("🔵 Mock 채용공고 추천 시작 - 이력서: \(resume.title)")
        
        Task {
            let mockRecommendations = await apiService.getMockJobRecommendations(resumeId: resume.id)
            
            await MainActor.run {
                self.recommendedJobs = mockRecommendations
                self.isRecommendationInProgress = false
                self.lastRecommendedResumeId = resume.id
                
                print("🟢 Mock 채용공고 추천 완료 - \(mockRecommendations.count)개 결과")
            }
        }
    }
    
    func clearRecommendationResults() {
        recommendedJobs = []
        errorMessage = nil
        lastRecommendedResumeId = nil
        print("🔄 추천 결과 초기화")
    }
    
    func refresh() {
        print("🔄 전체 새로고침 시작")
        loadMyResumes()
        clearRecommendationResults()
    }
    
    private func handleError(_ error: Error, context: String) {
        print("🔴 \(context) 오류: \(error)")
        
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                self.errorMessage = "인증이 만료되었습니다. 다시 로그인해주세요."
            case .forbidden:
                self.errorMessage = "개인 회원만 접근할 수 있습니다."
            case .serverError(let message):
                self.errorMessage = "서버 오류: \(message)"
            case .decodingError:
                self.errorMessage = "데이터 처리 중 오류가 발생했습니다."
            case .noData:
                self.errorMessage = "데이터를 받아올 수 없습니다."
            case .invalidURL:
                self.errorMessage = "잘못된 요청입니다."
            case .unknown:
                self.errorMessage = "알 수 없는 오류가 발생했습니다."
            }
        } else {
            self.errorMessage = "네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요."
        }
    }
    
    // MARK: - 유틸리티 메서드
    func getHighMatchCount(threshold: Double = 0.8) -> Int {
        return recommendedJobs.filter { $0.matchScore >= threshold }.count
    }
    
    func getAverageMatchScore() -> Double {
        guard !recommendedJobs.isEmpty else { return 0.0 }
        let total = recommendedJobs.reduce(0.0) { $0 + $1.matchScore }
        return total / Double(recommendedJobs.count)
    }
    
    func getTopMatchScore() -> Double {
        return recommendedJobs.map { $0.matchScore }.max() ?? 0.0
    }
    
    func getUrgentJobs() -> [JobRecommendationResponse] {
        return recommendedJobs.filter { $0.isDeadlineSoon }
    }
    
    func getJobsByMatchScore(threshold: Double) -> [JobRecommendationResponse] {
        return recommendedJobs.filter { $0.matchScore >= threshold }
    }
    
    func getJobsByCompany(_ companyName: String) -> [JobRecommendationResponse] {
        return recommendedJobs.filter { $0.companyName.lowercased().contains(companyName.lowercased()) }
    }
    
    func getJobsByLocation(_ location: String) -> [JobRecommendationResponse] {
        return recommendedJobs.filter {
            guard let jobLocation = $0.location else { return false }
            return jobLocation.lowercased().contains(location.lowercased())
        }
    }
    
    var hasRecommendationResults: Bool {
        return !recommendedJobs.isEmpty
    }
    
    var hasResumes: Bool {
        return !myResumes.isEmpty
    }
    
    var isAnyLoading: Bool {
        return isLoading || isRecommendationInProgress
    }
    
    var recommendationSummary: String {
        guard !recommendedJobs.isEmpty else { return "추천 결과가 없습니다" }
        
        let highCount = getHighMatchCount()
        let totalCount = recommendedJobs.count
        let avgScore = Int(getAverageMatchScore() * 100)
        
        return "\(totalCount)개 추천 (높은 적합도: \(highCount)개, 평균 매칭률: \(avgScore)%)"
    }
    //}
    //
    //// MARK: - Mock 데이터 확장 (테스트용)
    //extension JobRecommendationViewModel {
    //    func loadMockResumes() {
    //        myResumes = [
    //            ResumeResponse(
    //                id: 1,
    //                title: "iOS 개발자 이력서",
    //                content: "Swift와 UIKit을 활용한 iOS 앱 개발 경험 3년. MVVM 패턴과 RxSwift를 사용한 반응형 프로그래밍에 익숙합니다.",
    //                createdAt: "2025-01-15 10:30",
    //                updatedAt: "2025-05-20 14:20"
    //            ),
    //            ResumeResponse(
    //                id: 2,
    //                title: "풀스택 개발자 포트폴리오",
    //                content: "Swift iOS 개발과 Node.js 백엔드 개발 경험을 보유하고 있습니다. React Native를 사용한 크로스플랫폼 개발도 가능합니다.",
    //                createdAt: "2025-02-10 09:15",
    //                updatedAt: "2025-05-18 16:45"
    //            ),
    //            ResumeResponse(
    //                id: 3,
    //                title: "신입 개발자 지원서",
    //                content: "컴퓨터공학과 졸업예정. iOS 앱 개발 부트캠프 수료. Swift 기초와 iOS 앱 개발 프로젝트 경험을 보유하고 있습니다.",
    //                createdAt: "2025-03-05 13:20",
    //                updatedAt: "2025-05-15 11:30"
    //            )
    //        ]
    //        print("🟢 Mock 이력서 \(myResumes.count)개 로드 완료")
    //    }
    //
    //    func generateMockRecommendations(for resume: ResumeResponse) {
    //        isRecommendationInProgress = true
    //
    //        // 2초 지연 시뮬레이션
    //        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
    //            self.recommendedJobs = [
    //                JobRecommendationResponse(
    //                    jobId: 101,
    //                    title: "iOS 개발자 (3년차 이상)",
    //                    position: "iOS Developer",
    //                    companyName: "(주)테크스타트업",
    //                    location: "서울 강남구",
    //                    salary: "연봉 4500-6000만원",
    //                    experienceLevel: "경력 1년 이상",
    //                    deadline: "2025-07-10T23:59:59",
    //                    matchScore: 0.82,
    //                    matchReason: "높은 적합도"
    //                ),
    //                JobRecommendationResponse(
    //                    jobId: 104,
    //                    title: "풀스택 개발자 (Swift + React)",
    //                    position: "Full Stack Developer",
    //                    companyName: "스타트업코리아",
    //                    location: "서울 마포구",
    //                    salary: "연봉 5500-7500만원",
    //                    experienceLevel: "경력 2년 이상",
    //                    deadline: nil,
    //                    matchScore: 0.75,
    //                    matchReason: "보통 적합도"
    //                ),
    //                JobRecommendationResponse(
    //                    jobId: 105,
    //                    title: "주니어 iOS 개발자",
    //                    position: "Junior iOS Developer",
    //                    companyName: "에듀테크",
    //                    location: "서울 종로구",
    //                    salary: "연봉 3500-4500만원",
    //                    experienceLevel: "신입/경력 1년",
    //                    deadline: "2025-06-05T23:59:59",
    //                    matchScore: 0.68,
    //                    matchReason: "낮은 적합도"
    //                )
    //            ]
    //
    //            self.isRecommendationInProgress = false
    //            self.lastRecommendedResumeId = resume.id
    //
    //            print("🟢 Mock 추천 완료 - \(self.recommendedJobs.count)개 결과")
    //        }
    //    }
    //}
}
