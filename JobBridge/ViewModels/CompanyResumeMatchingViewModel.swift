// CompanyResumeMatchingViewModel.swift - 기업용 AI 이력서 매칭 뷰모델
import Foundation
import SwiftUI

@MainActor
class CompanyResumeMatchingViewModel: ObservableObject {
    @Published var myJobPostings: [JobPostingResponse] = []
    @Published var matchedResumes: [ResumeMatchResponse] = []
    @Published var isLoading = false
    @Published var isMatchingInProgress = false
    @Published var errorMessage: String?
    @Published var lastMatchedJobId: Int?

    private let apiService = APIService.shared

    // MARK: - 채용공고 로드
    func loadJobPostings() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let jobPostings = try await apiService.getMyJobPostings()

                await MainActor.run {
                    self.myJobPostings = jobPostings
                    self.isLoading = false

                    print("🟢 기업 채용공고 \(jobPostings.count)개 로드 완료")

                    for (index, job) in jobPostings.enumerated() {
                        print("📋 채용공고 #\(index + 1): \(job.title) (\(job.location))")
                    }
                }

            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.handleError(error, context: "채용공고 로드")
                }
            }
        }
    }

    // MARK: - AI 이력서 매칭 시작
    func startResumeMatching(for jobPosting: JobPostingResponse) {
        // ✅ 기업 회원이 아닌 경우 접근 차단 - 이 부분 제거하거나 수정
        // guard UserDefaults.standard.string(forKey: "userType") == "COMPANY" else {
        //     self.errorMessage = "기업 회원만 사용할 수 있는 기능입니다."
        //     print("⛔️ 기업 회원이 아니므로 매칭 기능 제한")
        //     return
        // }

        isMatchingInProgress = true
        errorMessage = nil
        matchedResumes = []

        print("🔵 AI 이력서 매칭 시작 - 채용공고: \(jobPosting.title) (ID: \(jobPosting.id))")
        print("🔵 현재 사용자 타입: \(UserDefaults.standard.string(forKey: "userType") ?? "없음")")

        Task {
            do {
                let matchedResumeResponses = try await apiService.getMatchingResumesForJob(jobPostingId: jobPosting.id)

                let convertedResumes = matchedResumeResponses.map { companyResume in
                    ResumeMatchResponse(
                        id: companyResume.id,
                        title: companyResume.title,
                        content: companyResume.content,
                        userName: companyResume.userName,
                        createdAt: companyResume.createdAt,
                        updatedAt: companyResume.updatedAt,
                        matchRate: companyResume.matchRate
                    )
                }

                await MainActor.run {
                    self.matchedResumes = convertedResumes
                    self.isMatchingInProgress = false
                    self.lastMatchedJobId = jobPosting.id

                    print("🟢 AI 이력서 매칭 완료 - \(convertedResumes.count)개 결과")

                    for (index, resume) in convertedResumes.enumerated() {
                        print("📄 매칭 #\(index + 1): \(resume.title) - \(Int(resume.matchRate * 100))% 적합 (\(resume.userName))")
                    }

                    let highMatchCount = convertedResumes.filter { $0.matchRate >= 0.8 }.count
                    let mediumMatchCount = convertedResumes.filter { $0.matchRate >= 0.6 && $0.matchRate < 0.8 }.count
                    let lowMatchCount = convertedResumes.filter { $0.matchRate < 0.6 }.count

                    print("📊 매칭 통계:")
                    print("   - 높은 적합도 (80% 이상): \(highMatchCount)명")
                    print("   - 보통 적합도 (60-79%): \(mediumMatchCount)명")
                    print("   - 낮은 적합도 (60% 미만): \(lowMatchCount)명")

                    if let topMatch = convertedResumes.first {
                        print("🏆 최고 매칭: \(topMatch.title) (\(Int(topMatch.matchRate * 100))%)")
                    }
                }

            } catch {
                await MainActor.run {
                    self.isMatchingInProgress = false
                    self.handleError(error, context: "AI 이력서 매칭")
                }
            }
        }
    }

    func clearMatchingResults() {
        matchedResumes = []
        errorMessage = nil
        lastMatchedJobId = nil
        print("🔄 매칭 결과 초기화")
    }

    func refresh() {
        print("🔄 전체 새로고침 시작")
        loadJobPostings()
        clearMatchingResults()
    }

    private func handleError(_ error: Error, context: String) {
        print("🔴 \(context) 오류: \(error)")

        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                self.errorMessage = "인증이 만료되었습니다. 다시 로그인해주세요."
            case .forbidden:
                self.errorMessage = "기업 회원만 접근할 수 있습니다."
            case .serverError(let message):
                self.errorMessage = "서버 오류: \(message)"
            case .decodingError:
                self.errorMessage = "데이터 처리 중 오류가 발생했습니다."
            case .noData:
                self.errorMessage = "데이터를 받아올 수 없습니다."
            case .invalidURL:
                self.errorMessage = "잘못된 요청입니다."
            case .unknown:
                self.errorMessage = "알 수 없는 오류가 발생했습니다."
            }
        } else {
            self.errorMessage = "네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요."
        }
    }

    func getHighMatchCount(threshold: Double = 0.8) -> Int {
        return matchedResumes.filter { $0.matchRate >= threshold }.count
    }

    func getAverageMatchRate() -> Double {
        guard !matchedResumes.isEmpty else { return 0.0 }
        let total = matchedResumes.reduce(0.0) { $0 + $1.matchRate }
        return total / Double(matchedResumes.count)
    }

    func getTopMatchRate() -> Double {
        return matchedResumes.map { $0.matchRate }.max() ?? 0.0
    }

    var hasMatchingResults: Bool {
        return !matchedResumes.isEmpty
    }

    var hasJobPostings: Bool {
        return !myJobPostings.isEmpty
    }
    
    var isAnyLoading: Bool {
        return isLoading || isMatchingInProgress
    }
}
