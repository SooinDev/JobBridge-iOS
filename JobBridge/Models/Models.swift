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

/// 기업용 지원자 응답 모델
struct CompanyApplicationResponse: Codable, Identifiable {
    let id: Int
    let jobPostingId: Int
    let applicantId: Int
    let applicantName: String
    let applicantEmail: String
    let appliedAt: String
    let status: String
    
    // 계산 속성들
    var formattedAppliedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = formatter.date(from: appliedAt) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy년 M월 d일"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        return appliedAt
    }
    
    var statusText: String {
        switch status {
        case "PENDING": return "대기중"
        case "REVIEWED": return "검토완료"
        case "ACCEPTED": return "합격"
        case "REJECTED": return "불합격"
        default: return "알 수 없음"
        }
    }
    
    var statusColor: Color {
        switch status {
        case "PENDING": return .blue
        case "REVIEWED": return .orange
        case "ACCEPTED": return .green
        case "REJECTED": return .red
        default: return .gray
        }
    }
}

/// 기업용 지원자 통계 모델
struct CompanyApplicationStats: Codable {
    let totalApplications: Int
    let pendingApplications: Int
    let thisMonthApplications: Int
    
    var acceptanceRate: Double {
        guard totalApplications > 0 else { return 0 }
        return Double(pendingApplications) / Double(totalApplications) * 100
    }
}

/// 지원자 필터링 옵션
enum ApplicationFilter: String, CaseIterable {
    case all = "전체"
    case pending = "대기중"
    case reviewed = "검토완료"
    case accepted = "합격"
    case rejected = "불합격"
    
    var systemImageName: String {
        switch self {
        case .all: return "person.3.fill"
        case .pending: return "clock.fill"
        case .reviewed: return "eye.fill"
        case .accepted: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .primary
        case .pending: return .blue
        case .reviewed: return .orange
        case .accepted: return .green
        case .rejected: return .red
        }
    }
}
