// APIService+JobRecommendation.swift - 개인회원용 채용공고 추천 API
import Foundation

// MARK: - 채용공고 추천 응답 모델
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
    
    // 계산 속성들
    var matchScorePercentage: Int {
        return Int(matchScore * 100)
    }
    
    var matchScoreColor: String {
        switch matchScore {
        case 0.9...1.0: return "red"     // 90% 이상 - 빨간색 (최고 매치)
        case 0.8..<0.9: return "green"   // 80-89% - 초록색 (높은 매치)
        case 0.7..<0.8: return "orange"  // 70-79% - 주황색 (양호한 매치)
        case 0.6..<0.7: return "blue"    // 60-69% - 파란색 (기본 매치)
        default: return "gray"           // 60% 미만 - 회색 (낮은 매치)
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
            return daysLeft <= 7 && daysLeft > 0 // 7일 이내
        }
        
        return false
    }
}

// MARK: - APIService 확장
extension APIService {
    
    /// 개인회원용: 내 이력서 기반 채용공고 추천
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
                
                // 매칭 점수 순으로 정렬
                let sortedRecommendations = recommendations.sorted { $0.matchScore > $1.matchScore }
                
                // 로그 출력
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
    
    /// Mock 데이터 (테스트용)
    func getMockJobRecommendations(resumeId: Int) async -> [JobRecommendationResponse] {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2초 지연
        
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
                deadline: nil, // 상시채용
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
}
