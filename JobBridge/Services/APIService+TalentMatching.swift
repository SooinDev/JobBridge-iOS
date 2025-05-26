// APIService+TalentMatching.swift - 기업회원용 인재 매칭 API
import Foundation

// MARK: - 인재 매칭 응답 모델
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
            return daysAgo <= 30 // 30일 이내 업데이트
        }
        
        return false
    }
}

// MARK: - APIService 확장
extension APIService {
    
    /// 기업회원용: 내 채용공고에 적합한 인재 매칭
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
                
                // 매칭 점수 순으로 정렬 (이미 백엔드에서 정렬되지만 확실히 하기 위해)
                let sortedTalents = talents.sorted { $0.matchScore > $1.matchScore }
                
                // 로그 출력
                for (index, talent) in sortedTalents.enumerated() {
                    print("👤 매칭 #\(index + 1): \(talent.candidateName) - \(Int(talent.matchScore * 100))% 매치 (\(talent.fitmentLevelKorean))")
                }
                
                // 통계 로그
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
    
    /// Mock 데이터 (테스트용)
    func getMockTalentMatching(jobPostingId: Int) async -> [TalentMatchResponse] {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2초 지연
        
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
}
