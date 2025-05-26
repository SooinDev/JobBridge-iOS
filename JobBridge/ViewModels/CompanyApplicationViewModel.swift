// CompanyApplicationViewModel.swift - 실제 API만 사용
import Foundation
import SwiftUI

class CompanyApplicationViewModel: ObservableObject {
    @Published var applications: [CompanyApplicationResponse] = []
    @Published var stats: CompanyApplicationStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: ApplicationFilter = .all
    
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
    func loadApplications(for jobId: Int) {
        isLoading = true
        errorMessage = nil
        
        print("🔵 실제 API로 지원자 목록 로드 시작 - jobId: \(jobId)")

        Task {
            do {
                // 실제 API 호출
                let realApplications = try await apiService.getRealApplicationsForJob(jobId: jobId)
                
                // RealCompanyApplicationResponse를 CompanyApplicationResponse로 변환
                let convertedApplications = realApplications.map { $0.toCompanyApplicationResponse() }

                DispatchQueue.main.async {
                    self.applications = convertedApplications
                    self.isLoading = false
                    print("🟢 실제 지원자 \(convertedApplications.count)명 로드 완료")
                    
                    // 지원자별 상세 정보 로깅
                    for (index, application) in convertedApplications.enumerated() {
                        print("📄 지원자 #\(index + 1): \(application.applicantName) (\(application.statusText))")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("🔴 실제 지원자 목록 로드 실패: \(error)")
                    
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
    func loadStats() {
        print("🔵 실제 API로 통계 로드 시작")
        
        Task {
            do {
                // 실제 API 호출
                let realStats = try await apiService.getRealApplicationStats()
                
                // RealCompanyApplicationStats를 CompanyApplicationStats로 변환
                let convertedStats = realStats.toCompanyApplicationStats()

                DispatchQueue.main.async {
                    self.stats = convertedStats
                    print("🟢 실제 통계 로드 완료")
                    print("   - 총 지원자: \(convertedStats.totalApplications)")
                    print("   - 대기중: \(convertedStats.pendingApplications)")
                    print("   - 이번 달: \(convertedStats.thisMonthApplications)")
                }
            } catch {
                print("🔴 실제 통계 로드 실패: \(error)")
                
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
        print("🔄 필터 변경: \(filter.rawValue) (\(filteredApplications.count)명)")
    }

    func updateApplicationStatus(applicationId: Int, newStatus: String) {
        Task {
            do {
                // TODO: 실제 상태 업데이트 API 구현 필요
                // let result = try await apiService.updateApplicationStatus(applicationId: applicationId, status: newStatus)
                
                DispatchQueue.main.async {
                    if let index = self.applications.firstIndex(where: { $0.id == applicationId }) {
                        print("🔄 지원자 상태 업데이트: \(applicationId) -> \(newStatus)")
                        
                        // 로컬 상태 업데이트 (임시)
                        let updatedApplication = self.applications[index]
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
            } catch {
                print("🔴 지원자 상태 업데이트 실패: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "상태 업데이트에 실패했습니다."
                }
            }
        }
    }

    func refresh(for jobId: Int) {
        print("🔄 지원자 데이터 새로고침 - jobId: \(jobId)")
        loadApplications(for: jobId)
        loadStats()
    }

    func searchApplications(query: String) {
        // TODO: 검색 기능 구현
        print("🔍 지원자 검색: \(query)")
    }
    
    // MARK: - 개발용 디버깅
    func debugLogCurrentState() {
        print("🔧 [DEBUG] 현재 지원자 관리 상태:")
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
        
        print("   - 지원자 목록:")
        for (index, application) in applications.enumerated() {
            print("     #\(index + 1): \(application.applicantName) (\(application.statusText))")
        }
    }
}
