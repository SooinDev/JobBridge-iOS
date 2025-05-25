import Foundation
import SwiftUI

class JobDetailViewModel: ObservableObject {
    @Published var job: JobPostingResponse?
    @Published var isLoading = false
    @Published var isCheckingApplication = false // 지원 여부 확인 중 상태
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
    
    // ✅ 실제 API를 사용하여 지원 여부 확인
    func checkIfAlreadyApplied() {
        guard let jobId = jobId ?? job?.id else {
            print("⚠️ jobId가 없어서 지원 여부 확인을 건너뜁니다.")
            return
        }
        
        isCheckingApplication = true
        applicationErrorMessage = nil
        
        print("🔵 지원 여부 확인 시작 - jobId: \(jobId)")
        
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
                    
                    // 에러 타입에 따른 처리
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            print("🔴 인증 오류 - 로그인이 필요합니다")
                            self.applicationErrorMessage = "로그인이 필요합니다."
                        case .forbidden:
                            print("🔴 권한 오류 - 개인 회원만 지원 가능")
                            self.applicationErrorMessage = "개인 회원만 지원할 수 있습니다."
                        case .serverError(let message):
                            print("🔴 서버 오류: \(message)")
                            self.applicationErrorMessage = message
                        default:
                            print("🔴 기타 API 오류: \(error)")
                            // 기본값으로 미지원 상태 설정 (사용자가 지원을 시도할 수 있도록)
                            self.isApplied = false
                        }
                    } else {
                        print("🔴 네트워크 오류: \(error)")
                        // 네트워크 오류 시에도 기본값으로 미지원 상태 설정
                        self.isApplied = false
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
                    self.isApplied = true // 지원 성공 시 상태 업데이트
                    print("✅ 지원 완료: \(message)")
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
