// APIService+Mock.swift
import Foundation

// MARK: - Mock 확장
extension APIService {
    
    // ✅ 지원자 목록용 Mock 데이터
    func getMockApplicationsForJob(jobId: Int) async -> [CompanyApplicationResponse] {
        return [
            CompanyApplicationResponse(
                id: 1,
                jobPostingId: jobId,
                applicantId: 101,
                applicantName: "홍길동",
                applicantEmail: "hong@example.com",
                appliedAt: "2025-05-01",
                status: "PENDING"
            ),
            CompanyApplicationResponse(
                id: 2,
                jobPostingId: jobId,
                applicantId: 102,
                applicantName: "김철수",
                applicantEmail: "kim@example.com",
                appliedAt: "2025-05-02",
                status: "REVIEWED"
            ),
            CompanyApplicationResponse(
                id: 3,
                jobPostingId: jobId,
                applicantId: 103,
                applicantName: "이영희",
                applicantEmail: "lee@example.com",
                appliedAt: "2025-05-03",
                status: "ACCEPTED"
            )
        ]
    }

    // ✅ 통계용 Mock 데이터
    func getMockApplicationStats() async -> CompanyApplicationStats {
        return CompanyApplicationStats(
            totalApplications: 3,
            pendingApplications: 1,
            thisMonthApplications: 3
        )
    }
}
