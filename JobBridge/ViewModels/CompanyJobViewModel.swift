// CompanyJobViewModel.swift - 실제 지원자 수 API 연동
import Foundation
import SwiftUI

class CompanyJobViewModel: ObservableObject {
    @Published var myJobPostings: [JobPostingResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalApplications = 0
    @Published var applicationCounts: [Int: Int] = [:] // 채용공고 ID별 지원자 수
    @Published var isLoadingApplicationCounts = false
    @Published var applicationCountsError: String?
    
    private let apiService = APIService.shared
    
    // MARK: - 채용공고 로드
    func loadMyJobPostings() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let jobPostings = try await apiService.getMyJobPostings()
                DispatchQueue.main.async {
                    self.myJobPostings = jobPostings
                    self.isLoading = false
                    
                    // 채용공고 로드 후 실제 지원자 수 조회
                    self.loadRealApplicationCounts()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .forbidden:
                            self.errorMessage = "기업 회원만 접근할 수 있습니다."
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
    
    // MARK: - 실제 지원자 수 조회
    func loadRealApplicationCounts() {
        guard !myJobPostings.isEmpty else {
            print("⚠️ 채용공고가 없어서 지원자 수 조회를 건너뜁니다.")
            return
        }
        
        isLoadingApplicationCounts = true
        applicationCountsError = nil
        
        print("🔵 실제 지원자 수 조회 시작 - \(myJobPostings.count)개 공고")
        
        Task {
            do {
                // 실제 API를 사용하여 지원자 수 조회
                let counts = try await apiService.getAllApplicationCounts(for: myJobPostings)
                
                DispatchQueue.main.async {
                    self.applicationCounts = counts
                    self.totalApplications = counts.values.reduce(0, +)
                    self.isLoadingApplicationCounts = false
                    
                    print("🟢 실제 지원자 수 조회 완료:")
                    print("   - 총 지원자: \(self.totalApplications)명")
                    print("   - 공고별 지원자 수: \(counts)")
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingApplicationCounts = false
                    
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.applicationCountsError = "인증이 만료되었습니다."
                        case .forbidden:
                            self.applicationCountsError = "권한이 없습니다."
                        case .serverError(let message):
                            self.applicationCountsError = "서버 오류: \(message)"
                        default:
                            self.applicationCountsError = "지원자 수 조회 중 오류가 발생했습니다."
                        }
                    } else {
                        self.applicationCountsError = "네트워크 오류가 발생했습니다."
                    }
                    
                    print("🔴 실제 지원자 수 조회 실패: \(error)")
                    
                    // 오류 시 기본값으로 0 설정
                    self.applicationCounts = Dictionary(uniqueKeysWithValues:
                        self.myJobPostings.map { ($0.id, 0) })
                    self.totalApplications = 0
                }
            }
        }
    }
    
    // MARK: - 특정 채용공고의 지원자 수 조회
    func getApplicationCount(for jobPostingId: Int) -> Int {
        return applicationCounts[jobPostingId] ?? 0
    }
    
    // MARK: - 채용공고 관리 메서드들
    func createJobPosting(request: CompanyJobPostingRequest, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let newJobPosting = try await apiService.createJobPosting(request: request)
                DispatchQueue.main.async {
                    self.myJobPostings.insert(newJobPosting, at: 0)
                    self.isLoading = false
                    
                    // 새 공고의 지원자 수는 0으로 초기화
                    self.applicationCounts[newJobPosting.id] = 0
                    
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .forbidden:
                            self.errorMessage = "기업 회원만 채용공고를 등록할 수 있습니다."
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "채용공고 등록 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                    completion(false)
                }
            }
        }
    }
    
    func updateJobPosting(jobId: Int, request: CompanyJobPostingRequest, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let updatedJobPosting = try await apiService.updateJobPosting(jobId: jobId, request: request)
                DispatchQueue.main.async {
                    // 기존 공고를 업데이트된 공고로 교체
                    if let index = self.myJobPostings.firstIndex(where: { $0.id == jobId }) {
                        self.myJobPostings[index] = updatedJobPosting
                    }
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
                        case .forbidden:
                            self.errorMessage = "자신의 채용공고만 수정할 수 있습니다."
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "채용공고 수정 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                    completion(false)
                }
            }
        }
    }
    
    func deleteJobPosting(jobId: Int) {
        Task {
            do {
                try await apiService.deleteJobPosting(jobId: jobId)
                DispatchQueue.main.async {
                    self.myJobPostings.removeAll { $0.id == jobId }
                    
                    // 지원자 수 맵에서도 제거
                    if let removedCount = self.applicationCounts.removeValue(forKey: jobId) {
                        self.totalApplications -= removedCount
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if let apiError = error as? APIError {
                        self.errorMessage = apiError.errorMessage
                    } else {
                        self.errorMessage = "채용공고 삭제 중 오류가 발생했습니다."
                    }
                }
            }
        }
    }
    
    // MARK: - 새로고침
    func refresh() {
        loadMyJobPostings() // 채용공고 로드 후 자동으로 지원자 수도 조회됨
    }
    
    // MARK: - 통계 정보
    var averageApplicationsPerJob: Double {
        guard !myJobPostings.isEmpty else { return 0 }
        return Double(totalApplications) / Double(myJobPostings.count)
    }
    
    var mostPopularJob: (JobPostingResponse, Int)? {
        guard !applicationCounts.isEmpty else { return nil }
        
        let maxEntry = applicationCounts.max { $0.value < $1.value }
        guard let (jobId, count) = maxEntry,
              let job = myJobPostings.first(where: { $0.id == jobId }) else {
            return nil
        }
        
        return (job, count)
    }
}

// MARK: - 개발용 디버깅 메서드
extension CompanyJobViewModel {
    
    /// 개발용: 지원자 수 강제 새로고침
    func debugRefreshApplicationCounts() {
        print("🔧 [DEBUG] 지원자 수 강제 새로고침")
        loadRealApplicationCounts()
    }
    
    /// 개발용: 현재 지원자 수 상태 로깅
    func debugLogApplicationCounts() {
        print("🔧 [DEBUG] 현재 지원자 수 상태:")
        print("   - 총 지원자: \(totalApplications)")
        print("   - 로딩 중: \(isLoadingApplicationCounts)")
        print("   - 오류: \(applicationCountsError ?? "없음")")
        print("   - 공고별 지원자 수:")
        
        for jobPosting in myJobPostings {
            let count = applicationCounts[jobPosting.id] ?? 0
            print("     * \(jobPosting.title): \(count)명")
        }
    }
}
