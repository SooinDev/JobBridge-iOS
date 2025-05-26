// CompanyJobViewModel.swift
import Foundation
import SwiftUI

class CompanyJobViewModel: ObservableObject {
    @Published var myJobPostings: [JobPostingResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var totalApplications = 0 // TODO: 실제 지원자 수 API 연동
    
    private let apiService = APIService.shared
    
    func loadMyJobPostings() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let jobPostings = try await apiService.getMyJobPostings()
                DispatchQueue.main.async {
                    self.myJobPostings = jobPostings
                    self.isLoading = false
                    // TODO: 각 공고별 지원자 수 계산
                    self.calculateTotalApplications()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .forbidden:
                            self.errorMessage = "기업 회원만 접근할 수 있습니다."
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
    
    func createJobPosting(request: CompanyJobPostingRequest, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let newJobPosting = try await apiService.createJobPosting(request: request)
                DispatchQueue.main.async {
                    self.myJobPostings.insert(newJobPosting, at: 0)
                    self.isLoading = false
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .forbidden:
                            self.errorMessage = "기업 회원만 채용공고를 등록할 수 있습니다."
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "채용공고 등록 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                    completion(false)
                }
            }
        }
    }
    
    func updateJobPosting(jobId: Int, request: CompanyJobPostingRequest, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let updatedJobPosting = try await apiService.updateJobPosting(jobId: jobId, request: request)
                DispatchQueue.main.async {
                    // 기존 공고를 업데이트된 공고로 교체
                    if let index = self.myJobPostings.firstIndex(where: { $0.id == jobId }) {
                        self.myJobPostings[index] = updatedJobPosting
                    }
                    self.isLoading = false
                    completion(true)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .unauthorized:
                            self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
                        case .forbidden:
                            self.errorMessage = "자신의 채용공고만 수정할 수 있습니다."
                        case .serverError(let message):
                            self.errorMessage = "서버 오류: \(message)"
                        default:
                            self.errorMessage = "채용공고 수정 중 오류가 발생했습니다."
                        }
                    } else {
                        self.errorMessage = "네트워크 오류가 발생했습니다."
                    }
                    completion(false)
                }
            }
        }
    }
    
    func deleteJobPosting(jobId: Int) {
        Task {
            do {
                try await apiService.deleteJobPosting(jobId: jobId)
                DispatchQueue.main.async {
                    self.myJobPostings.removeAll { $0.id == jobId }
                }
            } catch {
                DispatchQueue.main.async {
                    if let apiError = error as? APIError {
                        self.errorMessage = apiError.errorMessage
                    } else {
                        self.errorMessage = "채용공고 삭제 중 오류가 발생했습니다."
                    }
                }
            }
        }
    }
    
    private func calculateTotalApplications() {
        // TODO: 실제 지원자 수 API 연동
        // 현재는 Mock 데이터
        totalApplications = myJobPostings.count * 3
    }
}
