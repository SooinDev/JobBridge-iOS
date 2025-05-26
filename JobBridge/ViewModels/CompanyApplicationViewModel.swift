// CompanyApplicationViewModel.swift - 실제 API 연동
import Foundation
import SwiftUI

class CompanyApplicationViewModel: ObservableObject {
    @Published var applications: [CompanyApplicationResponse] = []
    @Published var stats: CompanyApplicationStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: ApplicationFilter = .all
    @Published var useRealAPI = true // 실제 API 사용 여부 토글
    
    private let apiService = APIService.shared

    var filteredApplications: [CompanyApplicationResponse] {
        switch selectedFilter {
        case .all: return applications
        case .pending: return applications.filter { $0.status == "PENDING" }
        case .reviewed: return applications.filter { $0.status == "REVIEWED" }
        case .accepted: return applications.filter { $0.status == "ACCEPTED" }
        case .rejected: return applications.filter { $0.status == "REJECTED" }
        }
    }

    var filterCounts: [ApplicationFilter: Int] {
        var counts: [ApplicationFilter: Int] = [:]
        counts[.all] = applications.count
        counts[.pending] = applications.filter { $0.status == "PENDING" }.count
        counts[.reviewed] = applications.filter { $0.status == "REVIEWED" }.count
        counts[.accepted] = applications.filter { $0.status == "ACCEPTED" }.count
        counts[.rejected] = applications.filter { $0.status == "REJECTED" }.count
        return counts
    }

    // MARK: - 실제 API를 사용한 지원자 목록 로드
    func loadApplications(for jobId: Int, useMockData: Bool = false) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetchedApplications: [CompanyApplicationResponse]

                if useMockData || !useRealAPI {
                    print("🟡 Mock 데이터로 지원자 목록 로드 중...")
                    fetchedApplications = await apiService.getMockApplicationsForJob(jobId: jobId)
                } else {
                    print("🔵 실제 API로 지원자 목록 로드 중...")
                    
                    // 실제 API 호출
                    let realApplications = try await apiService.getRealApplicationsForJob(jobId: jobId)
                    
                    // RealCompanyApplicationResponse를 CompanyApplicationResponse로 변환
                    fetchedApplications = realApplications.map { $0.toCompanyApplicationResponse() }
                }

                DispatchQueue.main.async {
                    self.applications = fetchedApplications
                    self.isLoading = false
                    print("🟢 지원자 \(fetchedApplications.count)명 로드 완료")
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("🔴 지원자 목록 로드 실패: \(error)")
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .forbidden:
                            self.errorMessage = "기업 회원만 접근할 수 있습니다."
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "지원자 목록을 불러오는 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                }
            }
        }
    }

    // MARK: - 실제 API를 사용한 통계 로드
    func loadStats(useMockData: Bool = false) {
        Task {
            do {
                let fetchedStats: CompanyApplicationStats
                
                if useMockData || !useRealAPI {
                    print("🟡 Mock 데이터로 통계 로드 중...")
                    fetchedStats = await apiService.getMockApplicationStats()
                } else {
                    print("🔵 실제 API로 통계 로드 중...")
                    
                    // 실제 API 호출
                    let realStats = try await apiService.getRealApplicationStats()
                    
                    // RealCompanyApplicationStats를 CompanyApplicationStats로 변환
                    fetchedStats = realStats.toCompanyApplicationStats()
                }

                DispatchQueue.main.async {
                    self.stats = fetchedStats
                    print("🟢 통계 로드 완료")
                    print("   - 총 지원자: \(fetchedStats.totalApplications)")
                    print("   - 대기중: \(fetchedStats.pendingApplications)")
                    print("   - 이번 달: \(fetchedStats.thisMonthApplications)")
                }
            } catch {
                print("🔴 통계 로드 실패: \(error)")
                
                DispatchQueue.main.async {
                    // 통계 로드 실패 시 기본값 설정
                    self.stats = CompanyApplicationStats(
                        totalApplications: 0,
                        pendingApplications: 0,
                        thisMonthApplications: 0
                    )
                }
            }
        }
    }

    func changeFilter(to filter: ApplicationFilter) {
        selectedFilter = filter
    }

    func updateApplicationStatus(applicationId: Int, newStatus: String) {
        Task {
            // TODO: 실제 상태 업데이트 API 구현 필요
            // 현재는 로컬 상태만 업데이트
            DispatchQueue.main.async {
                if let index = self.applications.firstIndex(where: { $0.id == applicationId }) {
                    print("지원자 상태 업데이트: \(applicationId) -> \(newStatus)")
                    
                    // 로컬 상태 업데이트
                    var updatedApplication = self.applications[index]
                    // CompanyApplicationResponse는 struct이므로 직접 수정 불가
                    // 새로운 객체를 생성해야 함
                    let newApplication = CompanyApplicationResponse(
                        id: updatedApplication.id,
                        jobPostingId: updatedApplication.jobPostingId,
                        applicantId: updatedApplication.applicantId,
                        applicantName: updatedApplication.applicantName,
                        applicantEmail: updatedApplication.applicantEmail,
                        appliedAt: updatedApplication.appliedAt,
                        status: newStatus
                    )
                    
                    self.applications[index] = newApplication
                }
            }
        }
    }

    func refresh(for jobId: Int, useMockData: Bool = false) {
        loadApplications(for: jobId, useMockData: useMockData)
        loadStats(useMockData: useMockData)
    }

    func searchApplications(query: String) {
        // TODO: 검색 기능
        print("🔍 지원자 검색: \(query)")
    }
    
    // MARK: - API 모드 토글
    func toggleAPIMode() {
        useRealAPI.toggle()
        print("🔧 API 모드 변경: \(useRealAPI ? "실제 API" : "Mock 데이터")")
    }
    
    // MARK: - 개발용 디버깅
    func debugLogCurrentState() {
        print("🔧 [DEBUG] 현재 지원자 관리 상태:")
        print("   - API 모드: \(useRealAPI ? "실제 API" : "Mock 데이터")")
        print("   - 총 지원자: \(applications.count)")
        print("   - 선택된 필터: \(selectedFilter.rawValue)")
        print("   - 필터링된 지원자: \(filteredApplications.count)")
        print("   - 로딩 중: \(isLoading)")
        print("   - 오류: \(errorMessage ?? "없음")")
        
        if let stats = stats {
            print("   - 통계:")
            print("     * 총 지원자: \(stats.totalApplications)")
            print("     * 대기중: \(stats.pendingApplications)")
            print("     * 이번 달: \(stats.thisMonthApplications)")
        }
    }
}
