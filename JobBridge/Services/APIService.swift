import Foundation

// MARK: - API 에러 정의
enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case unauthorized(String)
    case forbidden(String)
    case serverError(String)
    case unknown
    
    var errorMessage: String {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .noData:
            return "데이터를 받아오지 못했습니다."
        case .decodingError:
            return "데이터 형식에 문제가 있습니다."
        case .unauthorized(let message):
            return message
        case .forbidden(let message):
            return message
        case .serverError(let message):
            return "서버 오류: \(message)"
        case .unknown:
            return "알 수 없는 오류가 발생했습니다."
        }
    }
}

// MARK: - 응답 모델 정의
struct RealCompanyApplicationResponse: Codable, Identifiable {
    let id: Int
    let jobPostingId: Int
    let applicantId: Int
    let applicantName: String
    let applicantEmail: String
    let appliedAt: String
    let status: String
    
    var formattedAppliedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = inputFormatter.date(from: appliedAt) {
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
    
    var statusColorName: String {
        switch status {
        case "PENDING": return "blue"
        case "REVIEWED": return "orange"
        case "ACCEPTED": return "green"
        case "REJECTED": return "red"
        default: return "gray"
        }
    }
    
    func toCompanyApplicationResponse() -> CompanyApplicationResponse {
        return CompanyApplicationResponse(
            id: self.id,
            jobPostingId: self.jobPostingId,
            applicantId: self.applicantId,
            applicantName: self.applicantName,
            applicantEmail: self.applicantEmail,
            appliedAt: self.appliedAt,
            status: self.status
        )
    }
}

struct RealCompanyApplicationStats: Codable {
    let totalApplications: Int
    let pendingApplications: Int
    let thisMonthApplications: Int
    
    var acceptanceRate: Double {
        guard totalApplications > 0 else { return 0 }
        return Double(pendingApplications) / Double(totalApplications) * 100
    }
    
    func toCompanyApplicationStats() -> CompanyApplicationStats {
        return CompanyApplicationStats(
            totalApplications: self.totalApplications,
            pendingApplications: self.pendingApplications,
            thisMonthApplications: self.thisMonthApplications
        )
    }
}

struct CompanyMatchingResumeResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let content: String
    let userName: String
    let createdAt: String
    let updatedAt: String
    let matchRate: Double
    
    var formattedCreatedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = inputFormatter.date(from: createdAt) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy년 M월 d일"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        return createdAt
    }
    
    var matchRatePercentage: Int {
        return Int(matchRate * 100)
    }
    
    var matchRateColor: String {
        switch matchRate {
        case 0.9...1.0: return "red"
        case 0.8..<0.9: return "green"
        case 0.7..<0.8: return "orange"
        case 0.6..<0.7: return "blue"
        default: return "gray"
        }
    }
    
    var matchRateDescription: String {
        switch matchRate {
        case 0.9...1.0: return "완벽 매치"
        case 0.8..<0.9: return "높은 적합도"
        case 0.7..<0.8: return "양호한 적합도"
        case 0.6..<0.7: return "기본 적합도"
        default: return "낮은 적합도"
        }
    }
}

struct JobRecommendationResponse: Codable, Identifiable {
    let jobId: Int
    let title: String
    let position: String
    let companyName: String
    let location: String?
    let salary: String?
    let experienceLevel: String?
    let deadline: String?
    let matchScore: Double
    let matchReason: String
    
    var id: Int { jobId }
    
    var matchScorePercentage: Int {
        return Int(matchScore * 100)
    }
    
    var matchScoreColor: String {
        switch matchScore {
        case 0.9...1.0: return "red"
        case 0.8..<0.9: return "green"
        case 0.7..<0.8: return "orange"
        case 0.6..<0.7: return "blue"
        default: return "gray"
        }
    }
    
    var formattedDeadline: String {
        guard let deadline = deadline else { return "상시채용" }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = inputFormatter.date(from: deadline) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "M월 d일까지"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        return deadline
    }
    
    var isDeadlineSoon: Bool {
        guard let deadline = deadline else { return false }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = inputFormatter.date(from: deadline) {
            let timeInterval = date.timeIntervalSinceNow
            let daysLeft = timeInterval / (24 * 60 * 60)
            return daysLeft <= 7 && daysLeft > 0
        }
        
        return false
    }
}

struct TalentMatchResponse: Codable, Identifiable {
    let resumeId: Int
    let resumeTitle: String
    let candidateName: String
    let candidateEmail: String
    let candidateLocation: String?
    let candidateAge: Int?
    let resumeUpdatedAt: String
    let matchScore: Double
    let fitmentLevel: String
    let recommendationReason: String
    
    var id: Int { resumeId }
    
    var matchScorePercentage: Int {
        return Int(matchScore * 100)
    }
    
    var matchScoreColor: String {
        switch matchScore {
        case 0.9...1.0: return "red"
        case 0.8..<0.9: return "green"
        case 0.7..<0.8: return "orange"
        case 0.6..<0.7: return "blue"
        default: return "gray"
        }
    }
    
    var fitmentLevelKorean: String {
        switch fitmentLevel {
        case "EXCELLENT": return "완벽 매치"
        case "VERY_GOOD": return "매우 좋음"
        case "GOOD": return "좋음"
        case "FAIR": return "보통"
        case "POTENTIAL": return "잠재력"
        default: return "검토 필요"
        }
    }
    
    var fitmentLevelColor: String {
        switch fitmentLevel {
        case "EXCELLENT": return "red"
        case "VERY_GOOD": return "green"
        case "GOOD": return "blue"
        case "FAIR": return "orange"
        case "POTENTIAL": return "purple"
        default: return "gray"
        }
    }
    
    var formattedUpdatedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = inputFormatter.date(from: resumeUpdatedAt) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy년 M월 d일"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        return resumeUpdatedAt
    }
    
    var candidateAgeString: String {
        guard let age = candidateAge else { return "비공개" }
        return "\(age)세"
    }
    
    var isRecentlyUpdated: Bool {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        if let date = inputFormatter.date(from: resumeUpdatedAt) {
            let timeInterval = Date().timeIntervalSince(date)
            let daysAgo = timeInterval / (24 * 60 * 60)
            return daysAgo <= 30
        }
        
        return false
    }
}

// MARK: - APIService 메인 클래스
class APIService {
    static let shared = APIService()
    
    // ip 하드코딩
    internal let baseURL = "http://192.168.219.103:8080/api"
    
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        
        configuration.timeoutIntervalForRequest = 120.0
        configuration.timeoutIntervalForResource = 300.0
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        configuration.httpMaximumConnectionsPerHost = 6
        
        return URLSession(configuration: configuration)
    }()
    
    internal var authToken: String? {
        get {
            return temporaryAuthToken ?? UserDefaults.standard.string(forKey: "authToken")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "authToken")
        }
    }
    
    private var temporaryAuthToken: String?
    
    private init() {}
    
    // MARK: - 인증 관련 API
    
    func login(email: String, password: String, rememberMe: Bool = false) async throws -> LoginResponse {
        let url = URL(string: "\(baseURL)/user/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email, "pw": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 401 {
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorResponse["message"] {
                    throw APIError.unauthorized(errorMessage)
                } else {
                    throw APIError.unauthorized("아이디 또는 비밀번호가 일치하지 않습니다.")
                }
            }
            
            if httpResponse.statusCode != 200 {
                if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorResponse["message"] {
                    throw APIError.serverError(errorMessage)
                } else {
                    throw APIError.serverError("Status code: \(httpResponse.statusCode)")
                }
            }
            
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            if rememberMe {
                self.authToken = loginResponse.token
                saveUserInfo(loginResponse)
            } else {
                UserDefaults.standard.removeObject(forKey: "authToken")
                self.temporaryAuthToken = loginResponse.token
            }
            
            return loginResponse
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.unknown
        }
    }
    
    func signup(request: SignupRequest) async throws -> String {
        let url = URL(string: "\(baseURL)/user/signup")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        if let message = String(data: data, encoding: .utf8) {
            return message
        } else {
            throw APIError.decodingError
        }
    }
    
    // MARK: - 로그아웃
    
    func logout() {
        temporaryAuthToken = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userType")
    }
    
    // MARK: - Private Methods
    
    private func saveUserInfo(_ loginResponse: LoginResponse) {
        UserDefaults.standard.set(loginResponse.name, forKey: "userName")
        UserDefaults.standard.set(loginResponse.email, forKey: "userEmail")
        UserDefaults.standard.set(loginResponse.userType, forKey: "userType")
    }
}

// MARK: - 매칭 관련 API
extension APIService {
    
    func getMatchingJobsForResume(resumeId: Int) async throws -> [MatchingJobResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/match/jobs?resumeId=\(resumeId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 120.0
        
        print("🔵 매칭 채용공고 요청: \(url.absoluteString)")
        print("🔵 타임아웃 설정: \(request.timeoutInterval)초")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
            }
            
            if httpResponse.statusCode == 408 {
                throw APIError.serverError("AI 분석이 예상보다 오래 걸리고 있습니다. 잠시 후 다시 시도해주세요.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            do {
                let matchingJobs = try JSONDecoder().decode([MatchingJobResponse].self, from: data)
                print("🟢 매칭 결과 \(matchingJobs.count)개 파싱 완료")
                return matchingJobs
            } catch {
                print("🔴 JSON 디코딩 오류: \(error)")
                throw APIError.decodingError
            }
            
        } catch let error as URLError {
            print("🔴 네트워크 요청 오류: \(error)")
            
            switch error.code {
            case .timedOut:
                throw APIError.serverError("AI 분석이 예상보다 오래 걸리고 있습니다. 잠시 후 다시 시도해주세요.")
            case .networkConnectionLost, .notConnectedToInternet:
                throw APIError.serverError("네트워크 연결을 확인하고 다시 시도해주세요.")
            case .cannotConnectToHost, .cannotFindHost:
                throw APIError.serverError("서버에 연결할 수 없습니다. 잠시 후 다시 시도해주세요.")
            default:
                throw APIError.serverError("네트워크 오류: \(error.localizedDescription)")
            }
        } catch {
            print("🔴 네트워크 요청 오류: \(error)")
            throw error
        }
    }
    
    func getMatchingJobsForResumeWithRetry(resumeId: Int, maxRetries: Int = 3) async throws -> [MatchingJobResponse] {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                print("🔄 AI 매칭 시도 \(attempt)/\(maxRetries)")
                return try await getMatchingJobsForResume(resumeId: resumeId)
                
            } catch let error as APIError {
                lastError = error
                
                switch error {
                case .unauthorized, .forbidden:
                    throw error
                default:
                    break
                }
                
                if attempt < maxRetries {
                    let delay = Double(attempt) * 2.0
                    print("🟡 \(delay)초 후 재시도...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
            } catch {
                lastError = error
                
                if attempt < maxRetries {
                    let delay = Double(attempt) * 2.0
                    print("🟡 \(delay)초 후 재시도...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? APIError.unknown
    }
    
    func checkIfAlreadyApplied(jobId: Int) async throws -> Bool {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/applications/check/\(jobId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
            }
            
            if httpResponse.statusCode == 403 {
                return false
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let applied = jsonResponse?["applied"] as? Bool ?? false
                return applied
            } catch {
                throw APIError.decodingError
            }
            
        } catch {
            if error is APIError {
                throw error
            } else {
                throw APIError.unknown
            }
        }
    }
    
    func getCareerRecommendations(resumeId: Int, jobPostingId: Int) async throws -> CareerRecommendationResponse {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/match/career?resumeId=\(resumeId)&jobPostingId=\(jobPostingId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60.0
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
            }
            
            if httpResponse.statusCode == 408 {
                throw APIError.serverError("경력 분석이 예상보다 오래 걸리고 있습니다. 잠시 후 다시 시도해주세요.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            do {
                let recommendationsArray = try JSONDecoder().decode([String].self, from: data)
                return CareerRecommendationResponse(recommendations: recommendationsArray)
            } catch {
                return try JSONDecoder().decode(CareerRecommendationResponse.self, from: data)
            }
            
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw APIError.serverError("경력 분석이 예상보다 오래 걸리고 있습니다. 잠시 후 다시 시도해주세요.")
            default:
                throw APIError.serverError("네트워크 오류: \(error.localizedDescription)")
            }
        } catch {
            throw error
        }
    }
}

// MARK: - 이력서 관련 API
extension APIService {
    
    func getMyResumes() async throws -> [ResumeResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/resume/my")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode([ResumeResponse].self, from: data)
    }
    
    func createResume(request: ResumeRequest) async throws -> ResumeResponse {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/resume")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(ResumeResponse.self, from: data)
    }
    
    func updateResume(resumeId: Int, request: ResumeRequest) async throws -> ResumeResponse {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/resume/\(resumeId)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await urlSession.data(for: urlRequest)
        let httpResponse = response as? HTTPURLResponse
        
        guard let httpResponse = httpResponse else {
            throw APIError.unknown
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(ResumeResponse.self, from: data)
    }
    
    func deleteResume(resumeId: Int) async throws {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/resume/\(resumeId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        
        guard let httpResponse = httpResponse else {
            throw APIError.unknown
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
    }
}

// MARK: - 채용공고 관련 API
extension APIService {
    
    func getRecentJobs() async throws -> [JobPostingResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/jobs/recent")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode([JobPostingResponse].self, from: data)
    }
    
    func getAllJobs(page: Int = 0, size: Int = 50, sortBy: String = "createdAt", sortDir: String = "desc") async throws -> [JobPostingResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/jobs/all?page=\(page)&size=\(size)&sortBy=\(sortBy)&sortDir=\(sortDir)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 모든 채용공고 요청: \(url.absoluteString)")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        print("🟢 응답 코드: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        let jobs = try JSONDecoder().decode([JobPostingResponse].self, from: data)
        print("🟢 총 \(jobs.count)개 채용공고 로드 완료")
        
        return jobs
    }
    
    func getJobPosting(jobId: Int) async throws -> JobPostingResponse {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/job-posting/\(jobId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        
        guard let httpResponse = httpResponse, httpResponse.statusCode == 200 else {
            if let message = String(data: data, encoding: .utf8) {
                throw APIError.serverError(message)
            }
            throw APIError.unknown
        }
        
        return try JSONDecoder().decode(JobPostingResponse.self, from: data)
    }
}

// MARK: - 지원 관련 API
extension APIService {
    
    func getMyApplications() async throws -> [ApplicationResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/applications/mine")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 403 {
                throw APIError.forbidden("권한이 없습니다")
            }
            
            if httpResponse.statusCode != 200 {
                throw APIError.serverError("서버 오류: \(httpResponse.statusCode)")
            }
            
            if data.isEmpty {
                return []
            }
            
            do {
                let decoder = JSONDecoder()
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                return try decoder.decode([ApplicationResponse].self, from: data)
            } catch {
                throw APIError.decodingError
            }
        } catch {
            throw error
        }
    }
    
    func applyToJob(jobId: Int) async throws -> String {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/apply/\(jobId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let emptyBody: [String: Any] = [:]
        request.httpBody = try? JSONSerialization.data(withJSONObject: emptyBody)
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 403 {
                let errorMessage = data.isEmpty ? "권한이 없습니다. 개인 회원으로 로그인했는지 확인하세요." : (String(data: data, encoding: .utf8) ?? "권한 오류")
                throw APIError.forbidden(errorMessage)
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = data.isEmpty ? "서버 오류: \(httpResponse.statusCode)" : (String(data: data, encoding: .utf8) ?? "서버 오류")
                throw APIError.serverError(errorMessage)
            }
            
            return data.isEmpty ? "지원이 완료되었습니다." : (String(data: data, encoding: .utf8) ?? "지원이 완료되었습니다.")
        } catch {
            throw error
        }
    }
}

// MARK: - 이메일 인증 관련 API
extension APIService {
    
    func sendVerificationCode(email: String) async throws -> String {
        let url = URL(string: "\(baseURL)/user/send-code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        
        guard let httpResponse = httpResponse, httpResponse.statusCode == 200 else {
            if let message = String(data: data, encoding: .utf8) {
                throw APIError.serverError(message)
            }
            throw APIError.unknown
        }
        
        return String(data: data, encoding: .utf8) ?? "인증코드가 발송되었습니다."
    }

    func verifyCode(email: String, code: String) async throws -> String {
        let url = URL(string: "\(baseURL)/user/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email, "code": code]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await urlSession.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        
        guard let httpResponse = httpResponse, httpResponse.statusCode == 200 else {
            if let message = String(data: data, encoding: .utf8) {
                throw APIError.serverError(message)
            }
            throw APIError.unknown
        }
        
        return String(data: data, encoding: .utf8) ?? "이메일 인증이 완료되었습니다."
    }
}

// MARK: - 비밀번호 재설정 관련 API
extension APIService {
    
    func requestPasswordReset(email: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let result = try await self.requestPasswordReset(email: email)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func resetPassword(token: String, newPassword: String, completion: @escaping (Result<String, Error>) -> Void) {
        Task {
            do {
                let result = try await self.resetPassword(token: token, newPassword: newPassword)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func requestPasswordReset(email: String) async throws -> String {
        let url = URL(string: "\(baseURL)/user/password-reset")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("🔵 비밀번호 재설정 요청: \(url.absoluteString)")
        print("🔵 요청 이메일: \(email)")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🟢 응답 데이터: \(responseString)")
            }
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 400 {
                if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorResponse["message"] as? String {
                    throw APIError.serverError(message)
                } else if let errorMessage = String(data: data, encoding: .utf8) {
                    throw APIError.serverError(errorMessage)
                } else {
                    throw APIError.serverError("잘못된 요청입니다.")
                }
            }
            
            if httpResponse.statusCode == 500 {
                throw APIError.serverError("서버 내부 오류가 발생했습니다.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = jsonResponse["message"] as? String {
                return message
            }
            else if let message = String(data: data, encoding: .utf8), !message.isEmpty {
                return message
            }
            else {
                return "비밀번호 재설정 코드가 이메일로 발송되었습니다."
            }
            
        } catch {
            print("🔴 비밀번호 재설정 요청 오류: \(error)")
            
            if error is APIError {
                throw error
            } else {
                throw APIError.unknown
            }
        }
    }

    func resetPassword(token: String, newPassword: String) async throws -> String {
        let url = URL(string: "\(baseURL)/user/password-reset/confirm")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "token": token,
            "newPassword": newPassword
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("🔵 비밀번호 변경 요청: \(url.absoluteString)")
        print("🔵 토큰: \(token)")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🟢 응답 데이터: \(responseString)")
            }
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 400 {
                if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = errorResponse["message"] as? String {
                    throw APIError.serverError(message)
                } else if let errorMessage = String(data: data, encoding: .utf8) {
                    throw APIError.serverError(errorMessage)
                } else {
                    throw APIError.serverError("유효하지 않은 토큰이거나 비밀번호 형식이 올바르지 않습니다.")
                }
            }
            
            if httpResponse.statusCode == 500 {
                throw APIError.serverError("서버 내부 오류가 발생했습니다.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            if let jsonResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let message = jsonResponse["message"] as? String {
                return message
            }
            else if let message = String(data: data, encoding: .utf8), !message.isEmpty {
                return message
            }
            else {
                return "비밀번호가 성공적으로 변경되었습니다."
            }
            
        } catch {
            print("🔴 비밀번호 변경 오류: \(error)")
            
            if error is APIError {
                throw error
            } else {
                throw APIError.unknown
            }
        }
    }
}

// MARK: - 기업용 채용공고 관리 API
extension APIService {
    
    func getMyJobPostings() async throws -> [JobPostingResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/job-posting/my")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 내 채용공고 조회 요청: \(url.absoluteString)")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🟢 응답 데이터: \(responseString)")
            }
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
            }
            
            if httpResponse.statusCode == 403 {
                throw APIError.forbidden("기업 회원만 접근할 수 있습니다.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            let jobPostings = try JSONDecoder().decode([JobPostingResponse].self, from: data)
            print("🟢 내 채용공고 \(jobPostings.count)개 로드 완료")
            
            return jobPostings
            
        } catch {
            print("🔴 내 채용공고 조회 오류: \(error)")
            throw error
        }
    }
    
    func createJobPosting(request: CompanyJobPostingRequest) async throws -> JobPostingResponse {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/job-posting")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        print("🔵 채용공고 등록 요청: \(url.absoluteString)")
        print("🔵 요청 데이터: \(String(data: urlRequest.httpBody ?? Data(), encoding: .utf8) ?? "nil")")
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🟢 응답 데이터: \(responseString)")
            }
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
            }
            
            if httpResponse.statusCode == 403 {
                throw APIError.forbidden("기업 회원만 채용공고를 등록할 수 있습니다.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            let newJobPosting = try JSONDecoder().decode(JobPostingResponse.self, from: data)
            print("🟢 채용공고 등록 완료: \(newJobPosting.title)")
            
            return newJobPosting
            
        } catch {
            print("🔴 채용공고 등록 오류: \(error)")
            throw error
        }
    }
    
    func updateJobPosting(jobId: Int, request: CompanyJobPostingRequest) async throws -> JobPostingResponse {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/job-posting/\(jobId)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        print("🔵 채용공고 수정 요청: \(url.absoluteString)")
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
            }
            
            if httpResponse.statusCode == 403 {
                throw APIError.forbidden("자신의 채용공고만 수정할 수 있습니다.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            let updatedJobPosting = try JSONDecoder().decode(JobPostingResponse.self, from: data)
            print("🟢 채용공고 수정 완료: \(updatedJobPosting.title)")
            
            return updatedJobPosting
            
        } catch {
            print("🔴 채용공고 수정 오류: \(error)")
            throw error
        }
    }
    
    func deleteJobPosting(jobId: Int) async throws {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/job-posting/\(jobId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 채용공고 삭제 요청: \(url.absoluteString)")
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
            }
            
            if httpResponse.statusCode == 403 {
                throw APIError.forbidden("자신의 채용공고만 삭제할 수 있습니다.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            print("🟢 채용공고 삭제 완료")
            
        } catch {
            print("🔴 채용공고 삭제 오류: \(error)")
            throw error
        }
    }
}

// MARK: - 기업용 지원자 관리 API
extension APIService {
    
    func getRealApplicationsForJob(jobId: Int) async throws -> [RealCompanyApplicationResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/company/applications/job/\(jobId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 실제 지원자 목록 조회 요청: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🟢 응답 데이터: \(responseString)")
            }
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
            }
            
            if httpResponse.statusCode == 403 {
                throw APIError.forbidden("기업 회원만 접근할 수 있습니다.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                throw APIError.decodingError
            }
            
            let applications = jsonArray.compactMap { dict -> RealCompanyApplicationResponse? in
                guard
                    let id = dict["id"] as? Int,
                    let jobPostingId = dict["jobPostingId"] as? Int,
                    let applicantId = dict["applicantId"] as? Int,
                    let applicantName = dict["applicantName"] as? String,
                    let applicantEmail = dict["applicantEmail"] as? String,
                    let appliedAt = dict["appliedAt"] as? String,
                    let status = dict["status"] as? String
                else {
                    print("🔴 JSON 파싱 실패: \(dict)")
                    return nil
                }
                
                return RealCompanyApplicationResponse(
                    id: id,
                    jobPostingId: jobPostingId,
                    applicantId: applicantId,
                    applicantName: applicantName,
                    applicantEmail: applicantEmail,
                    appliedAt: appliedAt,
                    status: status
                )
            }
            
            print("🟢 실제 지원자 \(applications.count)명 로드 완료")
            return applications
            
        } catch {
            print("🔴 실제 지원자 목록 조회 오류: \(error)")
            throw error
        }
    }
    
    func getRealApplicationStats() async throws -> RealCompanyApplicationStats {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/company/applications/stats")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 실제 지원자 통계 조회 요청: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
            }
            
            if httpResponse.statusCode == 403 {
                throw APIError.forbidden("기업 회원만 접근할 수 있습니다.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            let stats = try JSONDecoder().decode(RealCompanyApplicationStats.self, from: data)
            print("🟢 실제 지원자 통계 로드 완료")
            
            return stats
            
        } catch {
            print("🔴 실제 지원자 통계 조회 오류: \(error)")
            throw error
        }
    }
    
    func getApplicationCountForJob(jobId: Int) async throws -> Int {
        let applications = try await getRealApplicationsForJob(jobId: jobId)
        return applications.count
    }
    
    func getAllApplicationCounts(for jobPostings: [JobPostingResponse]) async throws -> [Int: Int] {
        var applicationCounts: [Int: Int] = [:]
        
        for jobPosting in jobPostings {
            do {
                let count = try await getApplicationCountForJob(jobId: jobPosting.id)
                applicationCounts[jobPosting.id] = count
                print("📊 채용공고 '\(jobPosting.title)': \(count)명 지원")
            } catch {
                print("🔴 채용공고 \(jobPosting.id) 지원자 수 조회 실패: \(error)")
                applicationCounts[jobPosting.id] = 0
            }
        }
        
        return applicationCounts
    }
}

// MARK: - 기업용 이력서 매칭 API
extension APIService {
    
    func getMatchingResumesForJob(jobPostingId: Int) async throws -> [CompanyMatchingResumeResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }

        let url = URL(string: "\(baseURL)/match/resumes?jobPostingId=\(jobPostingId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 이력서 매칭 API 요청: \(url.absoluteString)")
        print("🔵 요청 헤더: \(request.allHTTPHeaderFields ?? [:])")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        print("🟢 응답 코드: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
            print("🟢 응답 데이터: \(responseString)")
        }

        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode([CompanyMatchingResumeResponse].self, from: data)
        case 401:
            throw APIError.unauthorized("인증이 만료되었습니다.")
        case 403:
            let errorMessage = String(data: data, encoding: .utf8) ?? "기업 회원만 접근할 수 있습니다."
            print("🔴 403 에러 상세: \(errorMessage)")
            throw APIError.forbidden(errorMessage)
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
            throw APIError.serverError("오류 \(httpResponse.statusCode): \(errorMessage)")
        }
    }
}

// MARK: - 개인회원용 채용공고 추천 API
extension APIService {
    
    func getJobRecommendations(resumeId: Int) async throws -> [JobRecommendationResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/api/job-recommendation?resumeId=\(resumeId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 채용공고 추천 API 요청: \(url.absoluteString)")
        print("🔵 요청 헤더: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            
            print("🟢 응답 코드: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🟢 응답 데이터: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                let recommendations = try JSONDecoder().decode([JobRecommendationResponse].self, from: data)
                print("🟢 채용공고 추천 \(recommendations.count)개 로드 완료")
                
                let sortedRecommendations = recommendations.sorted { $0.matchScore > $1.matchScore }
                
                for (index, job) in sortedRecommendations.enumerated() {
                    print("📋 추천 #\(index + 1): \(job.title) - \(Int(job.matchScore * 100))% 매치 (\(job.companyName))")
                }
                
                return sortedRecommendations
                
            case 401:
                throw APIError.unauthorized("인증이 만료되었습니다.")
            case 403:
                let errorMessage = String(data: data, encoding: .utf8) ?? "개인 회원만 접근할 수 있습니다."
                throw APIError.forbidden(errorMessage)
            case 404:
                throw APIError.serverError("이력서를 찾을 수 없습니다.")
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("오류 \(httpResponse.statusCode): \(errorMessage)")
            }
            
        } catch {
            print("🔴 채용공고 추천 API 오류: \(error)")
            throw error
        }
    }
}

// MARK: - 기업회원용 인재 매칭 API
extension APIService {
    
    func getTalentMatching(jobPostingId: Int) async throws -> [TalentMatchResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/api/talent-matching?jobPostingId=\(jobPostingId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 인재 매칭 API 요청: \(url.absoluteString)")
        print("🔵 요청 헤더: \(request.allHTTPHeaderFields ?? [:])")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            
            print("🟢 응답 코드: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🟢 응답 데이터: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                let talents = try JSONDecoder().decode([TalentMatchResponse].self, from: data)
                print("🟢 인재 매칭 \(talents.count)명 로드 완료")
                
                let sortedTalents = talents.sorted { $0.matchScore > $1.matchScore }
                
                for (index, talent) in sortedTalents.enumerated() {
                    print("👤 매칭 #\(index + 1): \(talent.candidateName) - \(Int(talent.matchScore * 100))% 매치 (\(talent.fitmentLevelKorean))")
                }
                
                let excellentCount = sortedTalents.filter { $0.fitmentLevel == "EXCELLENT" }.count
                let veryGoodCount = sortedTalents.filter { $0.fitmentLevel == "VERY_GOOD" }.count
                let goodCount = sortedTalents.filter { $0.fitmentLevel == "GOOD" }.count
                
                print("📊 매칭 통계:")
                print("   - 완벽 매치: \(excellentCount)명")
                print("   - 매우 좋음: \(veryGoodCount)명")
                print("   - 좋음: \(goodCount)명")
                
                return sortedTalents
                
            case 401:
                throw APIError.unauthorized("인증이 만료되었습니다.")
            case 403:
                let errorMessage = String(data: data, encoding: .utf8) ?? "기업 회원만 접근할 수 있습니다."
                throw APIError.forbidden(errorMessage)
            case 404:
                throw APIError.serverError("채용공고를 찾을 수 없습니다.")
            default:
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("오류 \(httpResponse.statusCode): \(errorMessage)")
            }
            
        } catch {
            print("🔴 인재 매칭 API 오류: \(error)")
            throw error
        }
    }
}

// MARK: - Mock 데이터 API
extension APIService {
    
    // MARK: - 채용공고 매칭 Mock 데이터
    func getMockMatchingJobs(resumeId: Int) async -> [MatchingJobResponse] {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        return [
            MatchingJobResponse(
                id: 101,
                title: "iOS 개발자 (Swift/SwiftUI)",
                description: "SwiftUI와 Combine을 활용한 iOS 앱 개발. 3년 이상 경력 우대.",
                createdAt: "2024-01-15 10:30",
                updatedAt: "2024-01-15 10:30",
                matchRate: 0.95
            ),
            MatchingJobResponse(
                id: 102,
                title: "모바일 앱 개발자 (iOS/Android)",
                description: "크로스플랫폼 모바일 앱 개발 경험자 모집. Flutter 또는 React Native 경험 우대.",
                createdAt: "2024-01-14 14:20",
                updatedAt: "2024-01-14 14:20",
                matchRate: 0.88
            ),
            MatchingJobResponse(
                id: 103,
                title: "프론트엔드 개발자 (React/TypeScript)",
                description: "React와 TypeScript를 활용한 웹 프론트엔드 개발. 모던 개발 도구 경험 필수.",
                createdAt: "2024-01-13 09:15",
                updatedAt: "2024-01-13 09:15",
                matchRate: 0.82
            ),
            MatchingJobResponse(
                id: 104,
                title: "풀스택 개발자 (Node.js/React)",
                description: "백엔드와 프론트엔드 모두 개발 가능한 풀스택 개발자 모집.",
                createdAt: "2024-01-12 16:45",
                updatedAt: "2024-01-12 16:45",
                matchRate: 0.76
            ),
            MatchingJobResponse(
                id: 105,
                title: "앱 개발 인턴 (iOS/Android)",
                description: "모바일 앱 개발에 관심있는 신입/인턴 개발자 모집. 멘토링 제공.",
                createdAt: "2024-01-11 11:30",
                updatedAt: "2024-01-11 11:30",
                matchRate: 0.69
            )
        ]
    }
    
    // MARK: - 이력서 매칭 Mock 데이터
    func getMockMatchingResumes(jobPostingId: Int) async -> [CompanyMatchingResumeResponse] {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        return [
            CompanyMatchingResumeResponse(
                id: 201,
                title: "3년차 iOS 개발자 이력서",
                content: "Swift, SwiftUI, UIKit을 활용한 iOS 앱 개발 경험 3년. MVVM 패턴과 Combine을 활용한 반응형 프로그래밍에 익숙하며, 다수의 앱스토어 출시 경험 보유.",
                userName: "김개발",
                createdAt: "2024-01-15T10:30:00",
                updatedAt: "2024-01-15T10:30:00",
                matchRate: 0.92
            ),
            CompanyMatchingResumeResponse(
                id: 202,
                title: "신입 모바일 개발자",
                content: "컴퓨터공학과 졸업예정. iOS 개발 부트캠프 수료. Swift, UIKit 기초 학습 완료. 개인 프로젝트로 날씨앱, 투두리스트 앱 개발 경험.",
                userName: "이신입",
                createdAt: "2024-01-14T14:20:00",
                updatedAt: "2024-01-14T14:20:00",
                matchRate: 0.85
            ),
            CompanyMatchingResumeResponse(
                id: 203,
                title: "풀스택 개발자 포트폴리오",
                content: "프론트엔드(React, TypeScript)와 백엔드(Node.js, Express) 개발 경험. 모바일 앱 개발에도 관심이 있어 Flutter를 학습중.",
                userName: "박풀스택",
                createdAt: "2024-01-13T09:15:00",
                updatedAt: "2024-01-13T09:15:00",
                matchRate: 0.78
            ),
            CompanyMatchingResumeResponse(
                id: 204,
                title: "경력 전환 개발자",
                content: "마케팅 경력 5년 후 개발자로 전환. 프로그래밍 교육과정 수료. Swift 기초 학습완료하고 간단한 iOS 앱 프로젝트 진행중.",
                userName: "최전환",
                createdAt: "2024-01-12T16:45:00",
                updatedAt: "2024-01-12T16:45:00",
                matchRate: 0.71
            ),
            CompanyMatchingResumeResponse(
                id: 205,
                title: "대학생 개발자 인턴 지원",
                content: "컴퓨터공학과 3학년 재학중. iOS 개발 동아리 활동. Swift Playground를 통한 기초 학습. 인턴십을 통해 실무 경험을 쌓고싶음.",
                userName: "한대학",
                createdAt: "2024-01-11T11:30:00",
                updatedAt: "2024-01-11T11:30:00",
                matchRate: 0.63
            )
        ]
    }
    
    // MARK: - 채용공고 추천 Mock 데이터
    func getMockJobRecommendations(resumeId: Int) async -> [JobRecommendationResponse] {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        return [
            JobRecommendationResponse(
                jobId: 1,
                title: "iOS 개발자 (3년차 이상)",
                position: "iOS Developer",
                companyName: "(주)테크스타트업",
                location: "서울 강남구",
                salary: "연봉 5000-7000만원",
                experienceLevel: "경력 3년 이상",
                deadline: "2025-06-15T23:59:59",
                matchScore: 0.94,
                matchReason: "매우 높은 적합도"
            ),
            JobRecommendationResponse(
                jobId: 2,
                title: "Swift 백엔드 개발자",
                position: "Backend Developer",
                companyName: "글로벌테크",
                location: "서울 판교",
                salary: "연봉 6000-8000만원",
                experienceLevel: "경력 2년 이상",
                deadline: "2025-06-30T23:59:59",
                matchScore: 0.87,
                matchReason: "높은 적합도"
            ),
            JobRecommendationResponse(
                jobId: 3,
                title: "모바일 앱 개발자 (iOS/Android)",
                position: "Mobile Developer",
                companyName: "모바일솔루션",
                location: "서울 송파구",
                salary: "연봉 4500-6000만원",
                experienceLevel: "경력 1년 이상",
                deadline: "2025-07-10T23:59:59",
                matchScore: 0.82,
                matchReason: "높은 적합도"
            ),
            JobRecommendationResponse(
                jobId: 4,
                title: "풀스택 개발자 (Swift + React)",
                position: "Full Stack Developer",
                companyName: "스타트업코리아",
                location: "서울 마포구",
                salary: "연봉 5500-7500만원",
                experienceLevel: "경력 2년 이상",
                deadline: nil,
                matchScore: 0.75,
                matchReason: "보통 적합도"
            ),
            JobRecommendationResponse(
                jobId: 5,
                title: "주니어 iOS 개발자",
                position: "Junior iOS Developer",
                companyName: "에듀테크",
                location: "서울 종로구",
                salary: "연봉 3500-4500만원",
                experienceLevel: "신입/경력 1년",
                deadline: "2025-06-05T23:59:59",
                matchScore: 0.68,
                matchReason: "낮은 적합도"
            )
        ]
    }
    
    // MARK: - 인재 매칭 Mock 데이터
    func getMockTalentMatching(jobPostingId: Int) async -> [TalentMatchResponse] {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        return [
            TalentMatchResponse(
                resumeId: 101,
                resumeTitle: "5년차 iOS 개발자 포트폴리오",
                candidateName: "김민수",
                candidateEmail: "kim.minsu@example.com",
                candidateLocation: "서울시 강남구",
                candidateAge: 29,
                resumeUpdatedAt: "2025-05-20T14:30:00",
                matchScore: 0.95,
                fitmentLevel: "EXCELLENT",
                recommendationReason: "요구사항과 매우 높은 일치도를 보입니다"
            ),
            TalentMatchResponse(
                resumeId: 102,
                resumeTitle: "Swift 전문 백엔드 개발자",
                candidateName: "이지은",
                candidateEmail: "lee.jieun@example.com",
                candidateLocation: "경기도 성남시",
                candidateAge: 27,
                resumeUpdatedAt: "2025-05-18T09:15:00",
                matchScore: 0.89,
                fitmentLevel: "VERY_GOOD",
                recommendationReason: "대부분의 요구사항을 충족합니다"
            ),
            TalentMatchResponse(
                resumeId: 103,
                resumeTitle: "풀스택 개발자 (iOS + Web)",
                candidateName: "박준형",
                candidateEmail: "park.junho@example.com",
                candidateLocation: "서울시 마포구",
                candidateAge: 31,
                resumeUpdatedAt: "2025-05-15T16:45:00",
                matchScore: 0.84,
                fitmentLevel: "VERY_GOOD",
                recommendationReason: "대부분의 요구사항을 충족합니다"
            ),
            TalentMatchResponse(
                resumeId: 104,
                resumeTitle: "3년차 모바일 앱 개발자",
                candidateName: "최서연",
                candidateEmail: "choi.seoyeon@example.com",
                candidateLocation: "서울시 송파구",
                candidateAge: 26,
                resumeUpdatedAt: "2025-05-12T11:20:00",
                matchScore: 0.78,
                fitmentLevel: "GOOD",
                recommendationReason: "주요 요구사항을 충족합니다"
            ),
            TalentMatchResponse(
                resumeId: 105,
                resumeTitle: "신입 iOS 개발자 지원",
                candidateName: "정태윤",
                candidateEmail: "jung.taeyoon@example.com",
                candidateLocation: "인천시 연수구",
                candidateAge: 24,
                resumeUpdatedAt: "2025-05-10T13:30:00",
                matchScore: 0.71,
                fitmentLevel: "GOOD",
                recommendationReason: "주요 요구사항을 충족합니다"
            ),
            TalentMatchResponse(
                resumeId: 106,
                resumeTitle: "경력 전환 개발자 (마케팅→개발)",
                candidateName: "한수빈",
                candidateEmail: "han.subin@example.com",
                candidateLocation: "서울시 종로구",
                candidateAge: 30,
                resumeUpdatedAt: "2025-05-08T10:00:00",
                matchScore: 0.65,
                fitmentLevel: "FAIR",
                recommendationReason: "일부 요구사항을 충족합니다"
            ),
            TalentMatchResponse(
                resumeId: 107,
                resumeTitle: "대학생 인턴 지원자",
                candidateName: "오동현",
                candidateEmail: "oh.donghyun@example.com",
                candidateLocation: "서울시 서대문구",
                candidateAge: 22,
                resumeUpdatedAt: "2025-05-05T15:20:00",
                matchScore: 0.58,
                fitmentLevel: "POTENTIAL",
                recommendationReason: "추가 검토가 필요합니다"
            )
        ]
    }
    
    // MARK: - 지원자 목록 Mock 데이터
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

    // MARK: - 통계 Mock 데이터
    func getMockApplicationStats() async -> CompanyApplicationStats {
        return CompanyApplicationStats(
            totalApplications: 3,
            pendingApplications: 1,
            thisMonthApplications: 3
        )
    }
}
