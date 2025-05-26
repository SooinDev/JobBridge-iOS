import Foundation

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

class APIService {
    static let shared = APIService()
    
    // 접근 제어자 변경
    internal let baseURL = "http://192.168.219.100:8080/api"
    
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
            let (data, response) = try await URLSession.shared.data(for: request)
            
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
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
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
    
    // MARK: - 🔥 매칭 관련 API (핵심 기능)
    
    func getMatchingJobsForResume(resumeId: Int) async throws -> [MatchingJobResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/match/jobs?resumeId=\(resumeId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 매칭 채용공고 요청: \(url.absoluteString)")
        print("🔵 요청 헤더: \(request.allHTTPHeaderFields ?? [:])")
        
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
            
            if httpResponse.statusCode == 400 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "잘못된 요청입니다."
                throw APIError.serverError("요청 오류: \(errorMessage)")
            }
            
            if httpResponse.statusCode == 404 {
                throw APIError.serverError("이력서를 찾을 수 없습니다.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            do {
                let matchingJobs = try JSONDecoder().decode([MatchingJobResponse].self, from: data)
                print("🟢 매칭 결과 \(matchingJobs.count)개 파싱 완료")
                
                for (index, job) in matchingJobs.enumerated() {
                    print("🟢 매칭 #\(index + 1): \(job.title) (일치도: \(Int(job.matchRate * 100))%)")
                }
                
                return matchingJobs
            } catch {
                print("🔴 JSON 디코딩 오류: \(error)")
                print("🔴 원본 데이터: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw APIError.decodingError
            }
            
        } catch {
            print("🔴 네트워크 요청 오류: \(error)")
            throw error
        }
    }
    
    // 🔥 Mock 데이터 (테스트용)
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
    
    // MARK: - 지원 여부 확인 API
    
    func checkIfAlreadyApplied(jobId: Int) async throws -> Bool {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/applications/check/\(jobId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 지원 여부 확인 요청: \(url.absoluteString)")
        print("🔵 요청 헤더: \(request.allHTTPHeaderFields ?? [:])")
        
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
                // 기업 회원이거나 권한이 없는 경우
                print("⚠️ 권한 없음 - 개인 회원만 지원 가능")
                return false
            }
            
            if httpResponse.statusCode == 400 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "잘못된 요청입니다."
                throw APIError.serverError("요청 오류: \(errorMessage)")
            }
            
            if httpResponse.statusCode == 404 {
                throw APIError.serverError("채용공고를 찾을 수 없습니다.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            // JSON 응답 파싱
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let applied = jsonResponse?["applied"] as? Bool ?? false
                let hasError = jsonResponse?["error"] as? Bool ?? false
                
                if hasError {
                    print("🔴 서버에서 오류 응답")
                    return false
                }
                
                print("🟢 지원 여부 확인 완료: \(applied)")
                return applied
                
            } catch {
                print("🔴 JSON 파싱 오류: \(error)")
                throw APIError.decodingError
            }
            
        } catch {
            print("🔴 네트워크 요청 오류: \(error)")
            
            // 네트워크 오류 시 안전하게 false 반환 (사용자가 지원을 시도할 수 있도록)
            if error is APIError {
                throw error
            } else {
                throw APIError.unknown
            }
        }
    }
    
    // MARK: - 이력서 관련 API
    
    func getMyResumes() async throws -> [ResumeResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/resume/my")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
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
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
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
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
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
    
    // MARK: - 채용공고 관련 API
    
    func getRecentJobs() async throws -> [JobPostingResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/jobs/recent")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
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
    
    // ✅ 새로 추가: 모든 채용공고 조회
    func getAllJobs(page: Int = 0, size: Int = 50, sortBy: String = "createdAt", sortDir: String = "desc") async throws -> [JobPostingResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/jobs/all?page=\(page)&size=\(size)&sortBy=\(sortBy)&sortDir=\(sortDir)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 모든 채용공고 요청: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        
        guard let httpResponse = httpResponse, httpResponse.statusCode == 200 else {
            if let message = String(data: data, encoding: .utf8) {
                throw APIError.serverError(message)
            }
            throw APIError.unknown
        }
        
        return try JSONDecoder().decode(JobPostingResponse.self, from: data)
    }
    
    // MARK: - 지원 관련 API
    
    func getMyApplications() async throws -> [ApplicationResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/applications/mine")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
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
            let (data, response) = try await URLSession.shared.data(for: request)
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
    
    // MARK: - 이메일 인증 관련
    
    func sendVerificationCode(email: String) async throws -> String {
        let url = URL(string: "\(baseURL)/user/send-code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        
        guard let httpResponse = httpResponse, httpResponse.statusCode == 200 else {
            if let message = String(data: data, encoding: .utf8) {
                throw APIError.serverError(message)
            }
            throw APIError.unknown
        }
        
        return String(data: data, encoding: .utf8) ?? "이메일 인증이 완료되었습니다."
    }
    
    // MARK: - 비밀번호 재설정 관련 API
    
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
    
    // APIService.swift의 기존 함수들 뒤에 추가
    func getCareerRecommendations(resumeId: Int, jobPostingId: Int) async throws -> CareerRecommendationResponse {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/match/career?resumeId=\(resumeId)&jobPostingId=\(jobPostingId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 경력 개발 API 호출: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 경력 개발 응답 코드: \(httpResponse?.statusCode ?? 0)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("🟢 경력 개발 응답 데이터: \(responseString)")
            }
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 401 {
                throw APIError.unauthorized("인증이 만료되었습니다. 다시 로그인해주세요.")
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
                throw APIError.serverError("서버 오류 (\(httpResponse.statusCode)): \(errorMessage)")
            }
            
            // 백엔드 응답이 배열인지 객체인지 먼저 확인
            do {
                // 먼저 배열로 디코딩 시도
                let recommendationsArray = try JSONDecoder().decode([String].self, from: data)
                return CareerRecommendationResponse(recommendations: recommendationsArray)
            } catch {
                // 배열 디코딩 실패 시 객체로 디코딩 시도
                return try JSONDecoder().decode(CareerRecommendationResponse.self, from: data)
            }
            
        } catch {
            print("🔴 경력 개발 API 오류: \(error)")
            throw error
        }
    }
    
    // MARK: - 비밀번호 재설정 관련 API

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
            let (data, response) = try await URLSession.shared.data(for: request)
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
            let (data, response) = try await URLSession.shared.data(for: request)
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


// APIService.swift에 추가할 기업용 메서드들 (수정된 버전)

extension APIService {
    
    // MARK: - 기업용 채용공고 관리 API
    
    /// 내가 등록한 채용공고 목록 조회
    func getMyJobPostings() async throws -> [JobPostingResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized("인증이 필요합니다. 로그인해주세요.")
        }
        
        let url = URL(string: "\(baseURL)/job-posting/my")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 내 채용공고 조회 요청: \(url.absoluteString)")
        
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
            
            let jobPostings = try JSONDecoder().decode([JobPostingResponse].self, from: data)
            print("🟢 내 채용공고 \(jobPostings.count)개 로드 완료")
            
            return jobPostings
            
        } catch {
            print("🔴 내 채용공고 조회 오류: \(error)")
            throw error
        }
    }
    
    /// 새 채용공고 등록
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
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
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
    
    /// 채용공고 수정
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
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
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
    
    /// 채용공고 삭제
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
