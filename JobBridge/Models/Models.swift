import Foundation

// 백엔드의 MyApplicationDto와 정확히 일치하도록 수정
struct ApplicationResponse: Codable, Identifiable {
    let jobPostingId: Int  // 백엔드는 Long이지만 Swift에서는 Int로 변환
    let jobTitle: String
    let companyName: String
    let appliedAt: String  // LocalDateTime이 JSON으로 변환된 형식
    
    // Identifiable 프로토콜을 위한 계산 프로퍼티
    var id: Int { jobPostingId }
    
    // CodingKeys 정의 - 백엔드 필드명과 정확히 일치
    private enum CodingKeys: String, CodingKey {
        case jobPostingId
        case jobTitle
        case companyName
        case appliedAt
    }
    
    // 커스텀 디코더 - 날짜 형식 변환 문제가 있을 경우 주석 해제하여 사용
    /*
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 필수 필드 디코딩
        jobPostingId = try container.decode(Int.self, forKey: .jobPostingId)
        jobTitle = try container.decode(String.self, forKey: .jobTitle)
        companyName = try container.decode(String.self, forKey: .companyName)
        
        // 날짜 필드 처리 - 원본 문자열 그대로 저장
        appliedAt = try container.decode(String.self, forKey: .appliedAt)
        
        print("🟢 디코딩 성공: \(jobTitle), 날짜: \(appliedAt)")
    }
    */
}

// 로그인 요청 모델
struct LoginRequest: Codable {
    let email: String
    let pw: String
}

// 로그인 응답 모델
struct LoginResponse: Codable {
    let token: String
    let name: String
    let email: String
    let userType: String
}

// 회원가입 요청 모델
struct SignupRequest: Codable {
    let pw: String
    let name: String
    let address: String
    let age: Int?
    let email: String
    let phonenumber: String
    let userType: String // "INDIVIDUAL" 또는 "COMPANY"
}

// 이력서 응답 모델
struct ResumeResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let content: String
    let userName: String
    let createdAt: String
    let updatedAt: String
    var matchRate: Double?
}

// 이력서 생성/수정 요청 모델
struct ResumeRequest: Codable {
    let title: String
    let content: String
}

// 채용공고 응답 모델
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
    var matchRate: Double?
}

// 채용공고 검색 요청 모델
struct JobSearchRequest: Codable {
    let keyword: String?
    let location: String?
    let experienceLevel: String?
    let activeOnly: Bool?
}
