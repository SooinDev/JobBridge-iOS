// APIService+CompanyResumeMatching.swift - 기업용 이력서 매칭 API
import Foundation

// MARK: - 매칭 이력서 응답 모델
struct CompanyMatchingResumeResponse: Codable, Identifiable {
    let id: Int
    let title: String
    let content: String
    let userName: String
    let createdAt: String
    let updatedAt: String
    let matchRate: Double
    
    // 계산 속성들
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
        case 0.9...1.0: return "red"     // 90% 이상 - 빨간색 (최고 매치)
        case 0.8..<0.9: return "green"   // 80-89% - 초록색 (높은 매치)
        case 0.7..<0.8: return "orange"  // 70-79% - 주황색 (양호한 매치)
        case 0.6..<0.7: return "blue"    // 60-69% - 파란색 (기본 매치)
        default: return "gray"           // 60% 미만 - 회색 (낮은 매치)
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

// MARK: - APIService 확장
extension APIService {
    
    /// Mock 데이터 생성 (테스트용)
    func getMockMatchingResumes(jobPostingId: Int) async -> [CompanyMatchingResumeResponse] {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2초 지연
        
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
            // 403 에러 메시지를 더 자세히 확인
            let errorMessage = String(data: data, encoding: .utf8) ?? "기업 회원만 접근할 수 있습니다."
            print("🔴 403 에러 상세: \(errorMessage)")
            throw APIError.forbidden(errorMessage)
        default:
            let errorMessage = String(data: data, encoding: .utf8) ?? "알 수 없는 오류"
            throw APIError.serverError("오류 \(httpResponse.statusCode): \(errorMessage)")
        }
    }
}
