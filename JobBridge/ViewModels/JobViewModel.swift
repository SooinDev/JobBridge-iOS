import Foundation
import SwiftUI

class JobViewModel: ObservableObject {
    @Published var jobs: [JobPostingResponse] = []           // 최근 채용공고 (10개)
    @Published var allJobs: [JobPostingResponse] = []        // ✅ 모든 채용공고
    @Published var matchingJobs: [JobPostingResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    // MARK: - 기본 채용공고 로드 (최근 10개)
    func loadRecentJobs() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedJobs = try await apiService.getRecentJobs()
                DispatchQueue.main.async {
                    self.jobs = fetchedJobs
                    self.isLoading = false
                    print("🟢 최근 채용공고 \(fetchedJobs.count)개 로드 완료")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - ✅ 새로 추가: 모든 채용공고 로드
    func loadAllJobs(page: Int = 0, size: Int = 1000) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedJobs = try await apiService.getAllJobs(page: page, size: size)
                DispatchQueue.main.async {
                    if page == 0 {
                        // 첫 페이지는 기존 데이터 교체
                        self.allJobs = fetchedJobs
                    } else {
                        // 추가 페이지는 기존 데이터에 추가
                        self.allJobs.append(contentsOf: fetchedJobs)
                    }
                    self.isLoading = false
                    print("🟢 전체 채용공고 \(self.allJobs.count)개 로드 완료 (페이지: \(page))")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - 🔥 핵심: 이력서 기반 매칭 채용공고 로드 (실제 AI API만 사용)
    func loadMatchingJobs(resumeId: Int) {
        isLoading = true
        errorMessage = nil
        matchingJobs = []
        
        Task {
            do {
                print("🔵 실제 AI 매칭 API 호출 - resumeId: \(resumeId)")
                let fetchedJobs: [MatchingJobResponse] = try await apiService.getMatchingJobsForResume(resumeId: resumeId)
                
                DispatchQueue.main.async {
                    print("🟢 AI 매칭 결과 \(fetchedJobs.count)개 로드 완료")
                    
                    // MatchingJobResponse를 JobPostingResponse로 변환
                    self.matchingJobs = fetchedJobs.map { matchingJob in
                        JobPostingResponse(
                            id: matchingJob.id,
                            title: matchingJob.title,
                            description: matchingJob.description,
                            position: "개발자", // 실제 API에서는 백엔드에서 제공해야 함
                            requiredSkills: "Swift, iOS, SwiftUI", // 실제 API에서는 백엔드에서 제공해야 함
                            experienceLevel: "3-5년", // 실제 API에서는 백엔드에서 제공해야 함
                            location: "서울", // 실제 API에서는 백엔드에서 제공해야 함
                            salary: "4000-6000만원", // 실제 API에서는 백엔드에서 제공해야 함
                            deadline: nil,
                            companyName: "테크 컴퍼니", // 실제 API에서는 백엔드에서 제공해야 함
                            companyEmail: nil,
                            createdAt: matchingJob.createdAt,
                            matchRate: matchingJob.matchRate
                        )
                    }
                    
                    // 매칭률 높은 순으로 정렬
                    self.matchingJobs.sort { job1, job2 in
                        let rate1 = job1.matchRate ?? 0
                        let rate2 = job2.matchRate ?? 0
                        return rate1 > rate2
                    }
                    
                    self.isLoading = false
                    
                    // 디버그 로깅
                    if MatchingDebugSettings.enableDetailedLogging {
                        self.logMatchingResults()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("🔴 AI 매칭 API 호출 실패: \(error)")
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - 🔥 Mock 또는 실제 API 호출 (개발용)
    func loadMatchingJobsWithFallback(resumeId: Int) {
        isLoading = true
        errorMessage = nil
        matchingJobs = []
        
        Task {
            do {
                let fetchedJobs: [MatchingJobResponse]
                
                // 개발 중에는 Mock 데이터 사용 가능
                if MatchingDebugSettings.useMockData {
                    print("🟡 Mock 데이터 사용 중...")
                    fetchedJobs = await apiService.getMockMatchingJobs(resumeId: resumeId)
                } else {
                    print("🔵 실제 API 호출 중...")
                    fetchedJobs = try await apiService.getMatchingJobsForResume(resumeId: resumeId)
                }
                
                // 매칭률 필터링
                let filteredJobs = fetchedJobs.filter {
                    $0.matchRate >= MatchingDebugSettings.minimumMatchRate
                }
                
                DispatchQueue.main.async {
                    if MatchingDebugSettings.enableDetailedLogging {
                        print("🟢 총 \(fetchedJobs.count)개 중 \(filteredJobs.count)개 표시")
                        filteredJobs.forEach { job in
                            print("  📄 \(job.title) - \(Int(job.matchRate * 100))%")
                        }
                    }
                    
                    // JobPostingResponse로 변환
                    self.matchingJobs = filteredJobs.map { matchingJob in
                        JobPostingResponse(
                            id: matchingJob.id,
                            title: matchingJob.title,
                            description: matchingJob.description,
                            position: "개발자", // Mock 데이터용
                            requiredSkills: "Swift, iOS, SwiftUI", // Mock 데이터용
                            experienceLevel: "3-5년", // Mock 데이터용
                            location: "서울", // Mock 데이터용
                            salary: "4000-6000만원", // Mock 데이터용
                            deadline: nil,
                            companyName: "테크 컴퍼니", // Mock 데이터용
                            companyEmail: nil,
                            createdAt: matchingJob.createdAt,
                            matchRate: matchingJob.matchRate
                        )
                    }
                    
                    // 매칭률 높은 순 정렬
                    self.matchingJobs.sort { job1, job2 in
                        let rate1 = job1.matchRate ?? 0
                        let rate2 = job2.matchRate ?? 0
                        return rate1 > rate2
                    }
                    
                    self.isLoading = false
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if MatchingDebugSettings.enableDetailedLogging {
                        print("🔴 매칭 API 오류: \(error)")
                    }
                    
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - 매칭 결과 초기화
    func clearMatchingResults() {
        matchingJobs = []
        errorMessage = nil
    }
    
    // MARK: - 특정 채용공고 상세 조회
    func loadJobDetail(jobId: Int) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let jobDetail = try await apiService.getJobPosting(jobId: jobId)
                DispatchQueue.main.async {
                    // 필요에 따라 상세 정보 처리
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.handleError(error)
                }
            }
        }
    }
    
    // MARK: - 에러 처리
    private func handleError(_ error: Error) {
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

// MARK: - 🔧 매칭 개발 설정
struct MatchingDebugSettings {
    // 🔧 실제 AI 사용으로 변경 (false로 설정)
    static let useMockData = false
    
    // 🔧 상세 로깅 활성화
    static let enableDetailedLogging = true
    
    // 🔧 Mock 응답 지연 시간 (초) - 실제 AI 사용 시 무시됨
    static let mockResponseDelay: Double = 1.5
    
    // 🔧 최소 매칭률 필터 (60% 이상만 표시)
    static let minimumMatchRate: Double = 0.6
}

// MARK: - 🔧 매칭 성능 측정 도구
class MatchingPerformanceTracker {
    static let shared = MatchingPerformanceTracker()
    private var startTime: Date?
    
    func startTracking() {
        startTime = Date()
        if MatchingDebugSettings.enableDetailedLogging {
            print("⏱️ 매칭 성능 측정 시작")
        }
    }
    
    func endTracking(resultCount: Int) {
        guard let startTime = startTime else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        
        if MatchingDebugSettings.enableDetailedLogging {
            print("⏱️ 매칭 완료: \(String(format: "%.2f", duration))초, \(resultCount)개 결과")
        }
        
        self.startTime = nil
    }
}

// MARK: - 🔧 매칭 통계 도우미
extension JobViewModel {
    
    // 매칭 결과 통계 정보
    var matchingStats: MatchingStats {
        let rates = matchingJobs.compactMap { $0.matchRate }
        
        return MatchingStats(
            totalCount: matchingJobs.count,
            averageRate: rates.isEmpty ? 0 : rates.reduce(0, +) / Double(rates.count),
            maxRate: rates.max() ?? 0,
            minRate: rates.min() ?? 0,
            highQualityCount: rates.filter { $0 >= 0.8 }.count,
            mediumQualityCount: rates.filter { $0 >= 0.6 && $0 < 0.8 }.count,
            lowQualityCount: rates.filter { $0 < 0.6 }.count
        )
    }
    
    // 매칭률별 그룹화
    func groupJobsByMatchRate() -> [MatchRateGroup] {
        let groups = [
            MatchRateGroup(title: "🔥 90% 이상", minRate: 0.9, maxRate: 1.0),
            MatchRateGroup(title: "🟢 80-89%", minRate: 0.8, maxRate: 0.89),
            MatchRateGroup(title: "🟡 70-79%", minRate: 0.7, maxRate: 0.79),
            MatchRateGroup(title: "🔴 60-69%", minRate: 0.6, maxRate: 0.69)
        ]
        
        return groups.map { group in
            var updatedGroup = group
            updatedGroup.jobs = matchingJobs.filter { job in
                guard let rate = job.matchRate else { return false }
                return rate >= group.minRate && rate <= group.maxRate
            }
            return updatedGroup
        }.filter { !$0.jobs.isEmpty }
    }
}

// MARK: - 🔧 매칭 관련 데이터 구조
struct MatchingStats {
    let totalCount: Int
    let averageRate: Double
    let maxRate: Double
    let minRate: Double
    let highQualityCount: Int
    let mediumQualityCount: Int
    let lowQualityCount: Int
}

struct MatchRateGroup {
    let title: String
    let minRate: Double
    let maxRate: Double
    var jobs: [JobPostingResponse] = []
}

// MARK: - 🔧 개발 도구 확장
extension JobViewModel {
    
    // 개발용: 매칭 결과 로깅
    func logMatchingResults() {
        guard MatchingDebugSettings.enableDetailedLogging else { return }
        
        print("\n📊 매칭 결과 분석:")
        print("총 개수: \(matchingJobs.count)")
        
        if !matchingJobs.isEmpty {
            let stats = matchingStats
            print("평균 매칭률: \(Int(stats.averageRate * 100))%")
            print("최고 매칭률: \(Int(stats.maxRate * 100))%")
            print("최저 매칭률: \(Int(stats.minRate * 100))%")
            print("고품질(80%+): \(stats.highQualityCount)개")
            print("중품질(60-79%): \(stats.mediumQualityCount)개")
            print("저품질(60%미만): \(stats.lowQualityCount)개")
            
            print("\n상위 3개 매칭 결과:")
            for (index, job) in matchingJobs.prefix(3).enumerated() {
                let rate = Int((job.matchRate ?? 0) * 100)
                print("\(index + 1). \(job.title) - \(rate)%")
            }
        }
        print("=====================================\n")
    }
    
    // 개발용: Mock 데이터 재생성
    func regenerateMockData(resumeId: Int) {
        if MatchingDebugSettings.useMockData {
            loadMatchingJobsWithFallback(resumeId: resumeId)
        }
    }
    
    // 개발용: 매칭률 필터 변경
    func filterByMatchRate(minRate: Double) {
        matchingJobs = matchingJobs.filter { job in
            (job.matchRate ?? 0) >= minRate
        }
    }
}
