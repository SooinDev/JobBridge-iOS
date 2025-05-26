import Foundation
import SwiftUI

// MARK: - 지원 관련 모델
struct ApplicationResponse: Codable, Identifiable {
    let jobPostingId: Int
    let jobTitle: String
    let companyName: String
    let appliedAt: String
    
    var id: Int { jobPostingId }
    
    private enum CodingKeys: String, CodingKey {
        case jobPostingId
        case jobTitle
        case companyName
        case appliedAt
    }
}

// MARK: - 로그인 관련 모델
struct LoginRequest: Codable {
    let email: String
    let pw: String
}

struct LoginResponse: Codable {
    let token: String
    let name: String
    let email: String
    let userType: String
}

// MARK: - 회원가입 관련 모델
struct SignupRequest: Codable {
    let pw: String
    let name: String
    let address: String
    let age: Int?
    let email: String
    let phonenumber: String
    let userType: String // "INDIVIDUAL" 또는 "COMPANY"
}

// MARK: - 이력서 관련 모델
struct ResumeResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let content: String
    let userName: String
    let createdAt: String
    let updatedAt: String
    var matchRate: Double?
}

struct ResumeRequest: Codable {
    let title: String
    let content: String
}

// MARK: - 🔥 채용공고 관련 모델 (매칭 기능 포함)
struct JobPostingResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let position: String
    let requiredSkills: String
    let experienceLevel: String
    let location: String
    let salary: String
    let deadline: String?
    let companyName: String?
    let companyEmail: String?
    let createdAt: String
    var matchRate: Double? // 🔥 매칭률 추가
}

// MARK: - 🔥 매칭 관련 모델 (단일 정의)
struct MatchingJobResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String
    let createdAt: String
    let updatedAt: String
    let matchRate: Double
}

// MARK: - 채용공고 검색 관련 모델
struct JobSearchRequest: Codable {
    let keyword: String?
    let location: String?
    let experienceLevel: String?
    let activeOnly: Bool?
}

// MARK: - 이메일 인증 관련 모델
struct EmailRequest: Codable {
    let email: String
}

struct VerificationRequest: Codable {
    let email: String
    let code: String
}

// MARK: - 🔥 기업용 채용공고 관리 모델
struct CompanyJobPostingRequest: Codable {
    let title: String
    let description: String
    let position: String
    let requiredSkills: String
    let experienceLevel: String
    let location: String
    let salary: String
    let deadline: String // ISO 형식 날짜 또는 빈 문자열
}

// MARK: - 🔥 기업용 지원자 관리 모델 (추후 구현)
struct JobApplicationResponse: Codable, Identifiable {
    let id: Int
    let jobPostingId: Int
    let resumeId: Int
    let applicantId: Int
    let applicantName: String
    let applicantEmail: String
    let resumeTitle: String
    let status: String // "PENDING", "REVIEWED", "ACCEPTED", "REJECTED"
    let applicationDate: String
    let updatedAt: String
}

// MARK: - 🔥 지원자 상태 업데이트 요청 (추후 구현)
struct ApplicationStatusUpdateRequest: Codable {
    let status: String // "REVIEWED", "ACCEPTED", "REJECTED"
    let note: String? // 선택적 메모
}

// MARK: - 🔥 기업 통계 정보 (추후 구현)
struct CompanyStatsResponse: Codable {
    let totalJobPostings: Int
    let activeJobPostings: Int
    let totalApplications: Int
    let pendingApplications: Int
    let thisMonthApplications: Int
    let averageApplicationsPerJob: Double
}

// MARK: - 🔥 기업용 이력서 매칭 응답 (추후 구현)
struct CompanyResumeMatchResponse: Codable, Identifiable {
    let resumeId: Int
    let resumeTitle: String
    let applicantName: String
    let matchRate: Double
    let skills: [String]
    let experience: String
    let createdAt: String
    
    var id: Int { resumeId }
}

// MARK: - 🔥 알림 모델
struct CompanyNotificationResponse: Codable, Identifiable {
    let id: Int
    let senderId: Int
    let receiverId: Int
    let jobPostingId: Int?
    let type: String // "APPLICATION", "JOB_DEADLINE", "MATCH_FOUND"
    let title: String
    let message: String
    let isRead: Bool
    let createdAt: String
    let data: [String: String]? // 추가 데이터 (JSON)
}

struct CareerRecommendationResponse: Codable {
    let recommendations: [String]
}

// MARK: - JobPostingResponse Extensions
extension JobPostingResponse {
    var isExpired: Bool {
        guard let deadline = deadline else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let deadlineDate = formatter.date(from: deadline) else { return false }
        return deadlineDate < Date()
    }
    
    var daysUntilDeadline: Int? {
        guard let deadline = deadline else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let deadlineDate = formatter.date(from: deadline) else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: deadlineDate).day
    }
    
    var statusText: String {
        if isExpired {
            return "마감"
        } else if let days = daysUntilDeadline {
            if days <= 0 {
                return "오늘 마감"
            } else if days <= 3 {
                return "D-\(days)"
            } else {
                return "진행중"
            }
        } else {
            return "상시채용"
        }
    }
    
    var statusColor: Color {
        if isExpired {
            return .red
        } else if let days = daysUntilDeadline {
            if days <= 3 {
                return .orange
            } else {
                return .green
            }
        } else {
            return .blue
        }
    }
}

// MARK: - Equatable 구현
extension JobPostingResponse: Equatable {
    static func == (lhs: JobPostingResponse, rhs: JobPostingResponse) -> Bool {
        return lhs.id == rhs.id
    }
}

extension CompanyJobPostingRequest: Equatable {
    static func == (lhs: CompanyJobPostingRequest, rhs: CompanyJobPostingRequest) -> Bool {
        return lhs.title == rhs.title &&
               lhs.description == rhs.description &&
               lhs.position == rhs.position &&
               lhs.requiredSkills == rhs.requiredSkills &&
               lhs.experienceLevel == rhs.experienceLevel &&
               lhs.location == rhs.location &&
               lhs.salary == rhs.salary &&
               lhs.deadline == rhs.deadline
    }
}

extension JobApplicationResponse: Equatable {
    static func == (lhs: JobApplicationResponse, rhs: JobApplicationResponse) -> Bool {
        return lhs.id == rhs.id
    }
}

extension CompanyNotificationResponse: Equatable {
    static func == (lhs: CompanyNotificationResponse, rhs: CompanyNotificationResponse) -> Bool {
        return lhs.id == rhs.id
    }
}
