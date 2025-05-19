import Foundation
import SwiftUI

class JobDetailViewModel: ObservableObject {
    @Published var job: JobPostingResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isApplied = false
    
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
    
    func applyToJob(completion: @escaping (Bool) -> Void) {
        guard let jobId = job?.id else {
            errorMessage = "채용공고 ID가 없습니다."
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
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
                            self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "지원 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                    completion(false)
                }
            }
        }
    }
}
