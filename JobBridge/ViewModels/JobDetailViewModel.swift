import Foundation
import SwiftUI

class JobDetailViewModel: ObservableObject {
    @Published var job: JobPostingResponse?
    @Published var isLoading = false
    @Published var isCheckingApplication = false // 지원 여부 확인 중 상태 추가
    @Published var errorMessage: String?
    @Published var isApplied = false // 이미 지원한 공고인지 상태
    @Published var applicationErrorMessage: String? // 지원 시 발생한 오류 메시지
    
    private let apiService = APIService.shared
    private var jobId: Int?
    
    // 채용공고 ID로 초기화
    init(jobId: Int) {
        self.jobId = jobId
        loadJob()
    }
    
    // 채용공고 객체로 초기화
    init(job: JobPostingResponse) {
        self.job = job
        self.jobId = job.id
        checkIfAlreadyApplied()
    }
    
    func loadJob() {
        guard let jobId = jobId else {
            errorMessage = "채용공고 ID가 없습니다."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedJob = try await apiService.getJobPosting(jobId: jobId)
                DispatchQueue.main.async {
                    self.job = fetchedJob
                    self.isLoading = false
                    // 공고 정보를 가져온 후 지원 여부 확인
                    self.checkIfAlreadyApplied()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "채용공고를 불러오는 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                }
            }
        }
    }
    
    // 이미 지원한 공고인지 확인하는 메서드
    func checkIfAlreadyApplied() {
        guard let jobId = jobId ?? job?.id else {
            return
        }
        
        isCheckingApplication = true
        
        Task {
            do {
                let applied = try await apiService.checkIfAlreadyApplied(jobId: jobId)
                DispatchQueue.main.async {
                    self.isApplied = applied
                    self.isCheckingApplication = false
                    
                    if applied {
                        print("✅ 이미 지원한 공고입니다: \(jobId)")
                    } else {
                        print("📝 아직 지원하지 않은 공고입니다: \(jobId)")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isCheckingApplication = false
                    print("⚠️ 지원 여부 확인 중 오류 발생: \(error)")
                    // 오류 발생 시 기본값으로 미지원 상태 설정 (사용자 경험 관점)
                    self.isApplied = false
                }
            }
        }
    }
    
    func applyToJob(completion: @escaping (Bool) -> Void) {
        guard let jobId = job?.id else {
            errorMessage = "채용공고 ID가 없습니다."
            completion(false)
            return
        }
        
        // 이미 지원한 공고인지 한 번 더 확인
        if isApplied {
            applicationErrorMessage = "이미 지원한 공고입니다."
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        applicationErrorMessage = nil
        
        Task {
            do {
                let message = try await apiService.applyToJob(jobId: jobId)
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isApplied = true
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.applicationErrorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .forbidden(let message):
                            self.applicationErrorMessage = message
                        case .serverError(let message):
                            if message.contains("이미 지원") {
                                self.isApplied = true
                                self.applicationErrorMessage = "이미 지원한 공고입니다."
                            } else {
                                self.applicationErrorMessage = "서버 오류: \(message)"
                            }
                        default:
                            self.applicationErrorMessage = "지원 중 오류가 발생했습니다."
                        }
                    } else {
                        self.applicationErrorMessage = "네트워크 오류가 발생했습니다."
                    }
                    completion(false)
                }
            }
        }
    }
}
