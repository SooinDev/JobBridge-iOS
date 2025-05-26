// APIService+CompanyApplicationsClean.swift - 실제 기업용 지원자 관리 API (Color 의존성 제거)
import Foundation

// MARK: - 실제 API 응답 모델 (백엔드와 일치)
struct RealCompanyApplicationResponse: Codable, Identifiable {
    let id: Int
    let jobPostingId: Int
    let applicantId: Int
    let applicantName: String
    let applicantEmail: String
    let appliedAt: String
    let status: String
    
    // 계산 속성들 (기존 CompanyApplicationResponse와 호환)
    var formattedAppliedDate: String {
        // ISO 형식의 날짜를 한국어 형식으로 변환
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
}

struct RealCompanyApplicationStats: Codable {
    let totalApplications: Int
    let pendingApplications: Int
    let thisMonthApplications: Int
    
    var acceptanceRate: Double {
        guard totalApplications > 0 else { return 0 }
        return Double(pendingApplications) / Double(totalApplications) * 100
    }
}

extension APIService {
    
    // MARK: - 실제 기업용 지원자 관리 API
    
    /// 특정 채용공고의 지원자 목록 조회 (실제 API)
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
            
            // 백엔드에서 Map<String, Object> 배열로 반환하므로 수동 파싱
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
    
    /// 기업의 지원자 통계 조회 (실제 API)
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
    
    /// 지원자 수 계산 (특정 채용공고)
    func getApplicationCountForJob(jobId: Int) async throws -> Int {
        let applications = try await getRealApplicationsForJob(jobId: jobId)
        return applications.count
    }
    
    /// 모든 채용공고의 지원자 수 맵 생성
    func getAllApplicationCounts(for jobPostings: [JobPostingResponse]) async throws -> [Int: Int] {
        var applicationCounts: [Int: Int] = [:]
        
        // 각 채용공고별로 순차적으로 지원자 수 조회
        for jobPosting in jobPostings {
            do {
                let count = try await getApplicationCountForJob(jobId: jobPosting.id)
                applicationCounts[jobPosting.id] = count
                print("📊 채용공고 '\(jobPosting.title)': \(count)명 지원")
            } catch {
                print("🔴 채용공고 \(jobPosting.id) 지원자 수 조회 실패: \(error)")
                applicationCounts[jobPosting.id] = 0 // 오류 시 0으로 설정
            }
        }
        
        return applicationCounts
    }
}

// MARK: - 호환성을 위한 변환 메서드
extension RealCompanyApplicationResponse {
    /// 기존 CompanyApplicationResponse로 변환
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

extension RealCompanyApplicationStats {
    /// 기존 CompanyApplicationStats로 변환
    func toCompanyApplicationStats() -> CompanyApplicationStats {
        return CompanyApplicationStats(
            totalApplications: self.totalApplications,
            pendingApplications: self.pendingApplications,
            thisMonthApplications: self.thisMonthApplications
        )
    }
}
