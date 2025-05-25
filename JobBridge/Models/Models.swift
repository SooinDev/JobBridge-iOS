import Foundation

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
struct JobPostingRequest: Codable {
    let title: String
    let description: String
    let position: String
    let requiredSkills: String
    let experienceLevel: String
    let location: String
    let salary: String
    let deadline: String // ISO 형식 날짜
}

// MARK: - 알림 관련 모델
struct NotificationResponse: Codable, Identifiable {
    let id: Int
    let senderId: Int
    let receiverId: Int
    let jobPostingId: Int
    let message: String
    let isRead: Bool
    let createdAt: String
}

// MARK: - Equatable 구현
extension JobPostingResponse: Equatable {
    static func == (lhs: JobPostingResponse, rhs: JobPostingResponse) -> Bool {
        return lhs.id == rhs.id
    }
}

struct CareerRecommendationResponse: Codable {
    let recommendations: [String]
}
