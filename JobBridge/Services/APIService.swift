import Foundation

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case unauthorized
    case forbidden(String)
    case serverError(String)
    case unknown
}

class APIService {
    static let shared = APIService() // 싱글톤 패턴
    
    // 실제 API 서버 URL로 변경해야 합니다
    private let baseURL = "http://192.168.219.100:8080/api"
    
    // 임시 토큰을 위한 속성 추가
    private var temporaryAuthToken: String?
    
    // 인증 토큰 접근자 수정
    private var authToken: String? {
        get {
            // 먼저 임시 토큰을 확인하고, 없으면 UserDefaults에서 확인
            return temporaryAuthToken ?? UserDefaults.standard.string(forKey: "authToken")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "authToken")
        }
    }
    
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
                throw APIError.unauthorized
            }
            
            if httpResponse.statusCode != 200 {
                throw APIError.serverError("Status code: \(httpResponse.statusCode)")
            }
            
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            // rememberMe 매개변수에 따라 토큰 저장 방식 변경
            if rememberMe {
                // 로그인 유지 시 UserDefaults에 토큰 저장
                self.authToken = loginResponse.token
                // 추가로 사용자 정보도 저장할 수 있음
                saveUserInfo(loginResponse)
            } else {
                // 로그인 유지를 원하지 않는 경우
                // 기존 저장된 토큰이 있다면 삭제
                UserDefaults.standard.removeObject(forKey: "authToken")
                // 메모리에만 토큰 보관
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
        
        // 백엔드가 단순 문자열을 반환하는 경우
        if let message = String(data: data, encoding: .utf8) {
            return message
        } else {
            throw APIError.decodingError
        }
    }
    
    // MARK: - 이력서 관련 API
    
    func getMyResumes() async throws -> [ResumeResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/resume/my")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode([ResumeResponse].self, from: data)
    }
    
    func createResume(request: ResumeRequest) async throws -> ResumeResponse {
        guard let token = authToken else {
            throw APIError.unauthorized
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
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode(ResumeResponse.self, from: data)
    }
    
    // MARK: - 채용공고 관련 API
    
    func getRecentJobs() async throws -> [JobPostingResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/jobs/recent")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode([JobPostingResponse].self, from: data)
    }
    
    func getMatchingJobs(resumeId: Int) async throws -> [JobPostingResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/match/jobs?resumeId=\(resumeId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        if httpResponse.statusCode != 200 {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }
        
        return try JSONDecoder().decode([JobPostingResponse].self, from: data)
    }
    
    // MARK: - 로그아웃 기능
    
    func logout() {
        // 토큰 삭제
        temporaryAuthToken = nil
        UserDefaults.standard.removeObject(forKey: "authToken")
        
        // 사용자 정보 삭제
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.removeObject(forKey: "userEmail")
        UserDefaults.standard.removeObject(forKey: "userType")
    }
    
    // 이메일 인증코드 요청 메서드
    func sendVerificationCode(email: String) async throws -> String {
        let url = URL(string: "\(baseURL)/user/send-code")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("🔵 인증코드 요청: \(url.absoluteString)")
        print("🔵 요청 본문: \(body)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
        print("🟢 응답 데이터: \(String(data: data, encoding: .utf8) ?? "")")
        
        guard let httpResponse = httpResponse, httpResponse.statusCode == 200 else {
            if let message = String(data: data, encoding: .utf8) {
                throw APIError.serverError(message)
            }
            throw APIError.unknown
        }
        
        return String(data: data, encoding: .utf8) ?? "인증코드가 발송되었습니다."
    }

    // 이메일 인증코드 확인 메서드
    func verifyCode(email: String, code: String) async throws -> String {
        let url = URL(string: "\(baseURL)/user/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email, "code": code]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("🔵 인증코드 확인 요청: \(url.absoluteString)")
        print("🔵 요청 본문: \(body)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
        print("🟢 응답 데이터: \(String(data: data, encoding: .utf8) ?? "")")
        
        guard let httpResponse = httpResponse, httpResponse.statusCode == 200 else {
            if let message = String(data: data, encoding: .utf8) {
                throw APIError.serverError(message)
            }
            throw APIError.unknown
        }
        
        return String(data: data, encoding: .utf8) ?? "이메일 인증이 완료되었습니다."
    }
    
    // 지원 내역 조회 메서드
    
    func getMyApplications() async throws -> [ApplicationResponse] {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/applications/mine")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 지원내역 요청: \(url.absoluteString)")
        print("🔵 인증 토큰: Bearer \(token)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
            
            // 응답 데이터 확인
            if let responseString = String(data: data, encoding: .utf8) {
                print("🟢 지원내역 응답 데이터: \(responseString)")
            } else {
                print("🟡 응답 데이터를 문자열로 변환할 수 없습니다.")
            }
            
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 403 {
                throw APIError.forbidden("권한이 없습니다")
            }
            
            if httpResponse.statusCode != 200 {
                throw APIError.serverError("서버 오류: \(httpResponse.statusCode)")
            }
            
            // 빈 응답 처리
            if data.isEmpty {
                print("🟡 응답 데이터가 비어 있습니다.")
                return []
            }
            
            // 응답 데이터 디코딩
            do {
                let decoder = JSONDecoder()
                
                // 날짜 포맷 처리를 위한 설정
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                
                // JSON 구조 분석 로그
                if let json = try? JSONSerialization.jsonObject(with: data) {
                    print("🟢 JSON 구조: \(json)")
                }
                
                return try decoder.decode([ApplicationResponse].self, from: data)
            } catch let decodingError {
                print("🔴 디코딩 오류: \(decodingError)")
                
                // 디코딩 오류 상세 정보
                if let decodingError = decodingError as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("키를 찾을 수 없음: \(key.stringValue), 경로: \(context.codingPath)")
                    case .typeMismatch(let type, let context):
                        print("타입 불일치: \(type), 경로: \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("값을 찾을 수 없음: \(type), 경로: \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("데이터 손상: \(context)")
                    @unknown default:
                        print("알 수 없는 디코딩 오류")
                    }
                }
                
                throw APIError.decodingError
            }
        } catch {
            print("🔴 네트워크 오류: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 채용공고 상세 조회
    func getJobPosting(jobId: Int) async throws -> JobPostingResponse {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        let url = URL(string: "\(baseURL)/job-posting/\(jobId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 채용공고 상세 요청: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        
        print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
        
        guard let httpResponse = httpResponse, httpResponse.statusCode == 200 else {
            if let message = String(data: data, encoding: .utf8) {
                print("🔴 서버 오류: \(message)")
                throw APIError.serverError(message)
            }
            throw APIError.unknown
        }
        
        return try JSONDecoder().decode(JobPostingResponse.self, from: data)
    }

    // 채용공고 지원하기
    func applyToJob(jobId: Int) async throws -> String {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        // URL 경로 확인
        let url = URL(string: "\(baseURL)/apply/\(jobId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 빈 요청 본문 추가 (필요한 경우)
        let emptyBody: [String: Any] = [:]
        request.httpBody = try? JSONSerialization.data(withJSONObject: emptyBody)
        
        print("🔵 채용공고 지원 요청: \(url.absoluteString)")
        print("🔵 인증 토큰: \(token)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
            print("🟢 응답 헤더: \(httpResponse?.allHeaderFields ?? [:])")
            
            if data.isEmpty {
                print("🟡 응답 데이터가 비어 있습니다")
            } else if let responseString = String(data: data, encoding: .utf8) {
                print("🟢 응답 데이터: \(responseString)")
            }
            
            // 오류 처리
            guard let httpResponse = httpResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 403 {
                // 응답 본문이 비어 있으면 기본 메시지 사용
                let errorMessage = data.isEmpty ? "권한이 없습니다. 개인 회원으로 로그인했는지 확인하세요." : (String(data: data, encoding: .utf8) ?? "권한 오류")
                print("🔴 권한 오류: \(errorMessage)")
                throw APIError.forbidden(errorMessage)
            }
            
            if httpResponse.statusCode != 200 {
                let errorMessage = data.isEmpty ? "서버 오류: \(httpResponse.statusCode)" : (String(data: data, encoding: .utf8) ?? "서버 오류")
                print("🔴 서버 오류: \(errorMessage)")
                throw APIError.serverError(errorMessage)
            }
            
            return data.isEmpty ? "지원이 완료되었습니다." : (String(data: data, encoding: .utf8) ?? "지원이 완료되었습니다.")
        } catch {
            print("🔴 네트워크 오류: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 이미 지원한 공고인지 확인하는 메서드
    func checkIfAlreadyApplied(jobId: Int) async throws -> Bool {
        guard let token = authToken else {
            throw APIError.unauthorized
        }
        
        // 방법 1: 서버에 직접 확인 요청 (이런 API가 있는 경우)
        let url = URL(string: "\(baseURL)/apply/check/\(jobId)")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("🔵 지원 여부 확인 요청: \(url.absoluteString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as? HTTPURLResponse
            
            print("🟢 응답 코드: \(httpResponse?.statusCode ?? 0)")
            
            // 서버가 200 OK와 함께 true/false 반환하는 경우
            if let httpResponse = httpResponse, httpResponse.statusCode == 200 {
                if let boolResponse = try? JSONDecoder().decode(Bool.self, from: data) {
                    return boolResponse
                }
                
                // 또는 서버가 간단한 문자열 "true"/"false" 반환하는 경우
                if let responseString = String(data: data, encoding: .utf8) {
                    return responseString.lowercased().contains("true")
                }
            }
            
            // 방법 2: 위 API가 없다면, 모든 지원 내역을 가져와서 클라이언트에서 체크
            return try await checkApplicationsContainJob(jobId: jobId)
            
        } catch {
            print("🔴 지원 여부 확인 오류: \(error.localizedDescription)")
            // 오류 발생 시 방법 2 시도
            return try await checkApplicationsContainJob(jobId: jobId)
        }
    }

    // 내 지원 내역에 특정 공고가 있는지 확인하는 보조 메서드
    private func checkApplicationsContainJob(jobId: Int) async throws -> Bool {
        do {
            // 모든 지원 내역 가져오기
            let applications = try await getMyApplications()
            
            // 지원 내역 중에 해당 공고 ID가 있는지 확인
            return applications.contains(where: { $0.jobPostingId == jobId })
        } catch {
            print("🔴 지원 내역 확인 오류: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 사용자 정보 저장 메서드
    private func saveUserInfo(_ loginResponse: LoginResponse) {
        // 사용자 정보 UserDefaults에 저장
        UserDefaults.standard.set(loginResponse.name, forKey: "userName")
        UserDefaults.standard.set(loginResponse.email, forKey: "userEmail")
        UserDefaults.standard.set(loginResponse.userType, forKey: "userType")
    }
    
    // APIService.swift에 추가
    func requestPasswordReset(email: String) async throws -> String {
        let url = URL(string: "\(baseURL)/user/password-reset")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "서버 오류"
            throw APIError.serverError(errorMessage)
        }
        
        // 응답 메시지 파싱
        if let responseDict = try? JSONDecoder().decode([String: String].self, from: data),
           let message = responseDict["message"] {
            return message
        }
        
        return "비밀번호 재설정 코드가 이메일로 발송되었습니다. 이메일을 확인해주세요."
    }

    // 비밀번호 변경 함수 (토큰 검증 및 새 비밀번호 설정)
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
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }
        
        if httpResponse.statusCode != 200 {
            let errorMessage = String(data: data, encoding: .utf8) ?? "서버 오류"
            throw APIError.serverError(errorMessage)
        }
        
        // 응답 메시지 파싱
        if let responseDict = try? JSONDecoder().decode([String: String].self, from: data),
           let message = responseDict["message"] {
            return message
        }
        
        return "비밀번호가 성공적으로 변경되었습니다. 새 비밀번호로 로그인해주세요."
    }
}
