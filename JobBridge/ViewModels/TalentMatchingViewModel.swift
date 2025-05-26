// TalentMatchingViewModel.swift - 기업회원용 인재 매칭 뷰모델
import Foundation
import SwiftUI

@MainActor
class TalentMatchingViewModel: ObservableObject {
    @Published var myJobPostings: [JobPostingResponse] = []
    @Published var matchedTalents: [TalentMatchResponse] = []
    @Published var isLoading = false
    @Published var isMatchingInProgress = false
    @Published var errorMessage: String?
    @Published var lastMatchedJobId: Int?
    
    private let apiService = APIService.shared
    
    // MARK: - 내 채용공고 로드
    func loadMyJobPostings() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let jobPostings = try await apiService.getMyJobPostings()
                
                await MainActor.run {
                    self.myJobPostings = jobPostings
                    self.isLoading = false
                    
                    print("🟢 기업 채용공고 \(jobPostings.count)개 로드 완료")
                    
                    for (index, job) in jobPostings.enumerated() {
                        print("📋 채용공고 #\(index + 1): \(job.title) (\(job.location))")
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.handleError(error, context: "채용공고 로드")
                }
            }
        }
    }
    
    // MARK: - AI 인재 매칭 시작
    func startTalentMatching(for jobPosting: JobPostingResponse) {
        // 기업 회원 권한 확인
        guard UserDefaults.standard.string(forKey: "userType") == "COMPANY" else {
            self.errorMessage = "기업 회원만 사용할 수 있는 기능입니다."
            print("⛔️ 기업 회원이 아니므로 매칭 기능 제한")
            return
        }
        
        isMatchingInProgress = true
        errorMessage = nil
        matchedTalents = []
        
        print("🔵 AI 인재 매칭 시작 - 채용공고: \(jobPosting.title) (ID: \(jobPosting.id))")
        print("🔵 현재 사용자 타입: \(UserDefaults.standard.string(forKey: "userType") ?? "없음")")
        
        Task {
            do {
                let talents = try await apiService.getTalentMatching(jobPostingId: jobPosting.id)
                
                await MainActor.run {
                    self.matchedTalents = talents
                    self.isMatchingInProgress = false
                    self.lastMatchedJobId = jobPosting.id
                    
                    print("🟢 AI 인재 매칭 완료 - \(talents.count)명 결과")
                    
                    for (index, talent) in talents.enumerated() {
                        print("👤 매칭 #\(index + 1): \(talent.candidateName) - \(Int(talent.matchScore * 100))% 매치 (\(talent.fitmentLevelKorean))")
                    }
                    
                    let excellentCount = talents.filter { $0.fitmentLevel == "EXCELLENT" }.count
                    let veryGoodCount = talents.filter { $0.fitmentLevel == "VERY_GOOD" }.count
                    let goodCount = talents.filter { $0.fitmentLevel == "GOOD" }.count
                    
                    print("📊 매칭 통계:")
                    print("   - 완벽 매치: \(excellentCount)명")
                    print("   - 매우 좋음: \(veryGoodCount)명")
                    print("   - 좋음: \(goodCount)명")
                    
                    if let topMatch = talents.first {
                        print("🏆 최고 매칭: \(topMatch.candidateName) (\(Int(topMatch.matchScore * 100))%)")
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isMatchingInProgress = false
                    self.handleError(error, context: "AI 인재 매칭")
                }
            }
        }
    }
    
    // MARK: - Mock 매칭 (테스트용)
    func startMockTalentMatching(for jobPosting: JobPostingResponse) {
        isMatchingInProgress = true
        errorMessage = nil
        matchedTalents = []
        
        print("🔵 Mock 인재 매칭 시작 - 채용공고: \(jobPosting.title)")
        
        Task {
            let mockTalents = await apiService.getMockTalentMatching(jobPostingId: jobPosting.id)
            
            await MainActor.run {
                self.matchedTalents = mockTalents
                self.isMatchingInProgress = false
                self.lastMatchedJobId = jobPosting.id
                
                print("🟢 Mock 인재 매칭 완료 - \(mockTalents.count)명 결과")
            }
        }
    }
    
    func clearMatchingResults() {
        matchedTalents = []
        errorMessage = nil
        lastMatchedJobId = nil
        print("🔄 매칭 결과 초기화")
    }
    
    func refresh() {
        print("🔄 전체 새로고침 시작")
        loadMyJobPostings()
        clearMatchingResults()
    }
    
    private func handleError(_ error: Error, context: String) {
        print("🔴 \(context) 오류: \(error)")
        
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                self.errorMessage = "인증이 만료되었습니다. 다시 로그인해주세요."
            case .forbidden:
                self.errorMessage = "기업 회원만 접근할 수 있습니다."
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
    func getExcellentMatchCount() -> Int {
        return matchedTalents.filter { $0.fitmentLevel == "EXCELLENT" }.count
    }
    
    func getHighMatchCount(threshold: Double = 0.8) -> Int {
        return matchedTalents.filter { $0.matchScore >= threshold }.count
    }
    
    func getAverageMatchScore() -> Double {
        guard !matchedTalents.isEmpty else { return 0.0 }
        let total = matchedTalents.reduce(0.0) { $0 + $1.matchScore }
        return total / Double(matchedTalents.count)
    }
    
    func getTopMatchScore() -> Double {
        return matchedTalents.map { $0.matchScore }.max() ?? 0.0
    }
    
    func getRecentlyUpdatedTalents() -> [TalentMatchResponse] {
        return matchedTalents.filter { $0.isRecentlyUpdated }
    }
    
    func getTalentsByFitmentLevel(_ level: String) -> [TalentMatchResponse] {
        return matchedTalents.filter { $0.fitmentLevel == level }
    }
    
    var hasMatchingResults: Bool {
        return !matchedTalents.isEmpty
    }
    
    var hasJobPostings: Bool {
        return !myJobPostings.isEmpty
    }
    
    var isAnyLoading: Bool {
        return isLoading || isMatchingInProgress
    }
}
