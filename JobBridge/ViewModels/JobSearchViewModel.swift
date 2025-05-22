import Foundation
import SwiftUI

class JobSearchViewModel: ObservableObject {
    @Published var searchResults: [JobPostingResponse] = []
    @Published var recentJobs: [JobPostingResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    
    private let apiService = APIService.shared
    
    // MARK: - Public Methods
    
    func searchJobs(request: JobSearchRequest) {
        isLoading = true
        errorMessage = nil
        hasSearched = true
        
        Task {
            do {
                // 기존 getRecentJobs를 사용하여 모든 공고를 가져온 후 클라이언트에서 필터링
                let allJobs = try await apiService.getRecentJobs()
                let filteredJobs = filterJobs(allJobs, with: request)
                
                DispatchQueue.main.async {
                    self.searchResults = filteredJobs
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.handleError(error)
                }
            }
        }
    }
    
    func loadRecentJobs() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let jobs = try await apiService.getRecentJobs()
                DispatchQueue.main.async {
                    self.recentJobs = jobs
                    if !self.hasSearched {
                        self.searchResults = []
                    }
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.handleError(error)
                }
            }
        }
    }
    
    func quickSearch(keyword: String) {
        let request = JobSearchRequest(
            keyword: keyword,
            location: nil,
            experienceLevel: nil,
            activeOnly: true
        )
        searchJobs(request: request)
    }
    
    func clearSearch() {
        searchResults = []
        errorMessage = nil
        hasSearched = false
    }
    
    // MARK: - Private Methods
    
    private func filterJobs(_ jobs: [JobPostingResponse], with request: JobSearchRequest) -> [JobPostingResponse] {
        return jobs.filter { job in
            var matches = true
            
            // 키워드 필터링 (해시태그 포함)
            if let keyword = request.keyword, !keyword.isEmpty {
                let keywords = keyword.lowercased().components(separatedBy: " ")
                    .filter { !$0.isEmpty }
                
                let jobText = [
                    job.title,
                    job.companyName ?? "",
                    job.position,
                    job.requiredSkills,
                    job.description
                ].joined(separator: " ").lowercased()
                
                matches = matches && keywords.allSatisfy { keyword in
                    // # 제거해서 검색
                    let cleanKeyword = keyword.replacingOccurrences(of: "#", with: "")
                    return jobText.contains(cleanKeyword) || jobText.contains(keyword)
                }
            }
            
            // 지역 필터링
            if let location = request.location, !location.isEmpty {
                matches = matches && job.location.lowercased().contains(location.lowercased())
            }
            
            // 경험 수준 필터링
            if let experience = request.experienceLevel, !experience.isEmpty {
                matches = matches && job.experienceLevel.lowercased().contains(experience.lowercased())
            }
            
            return matches
        }
    }
    
    private func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                self.errorMessage = "인증이 필요합니다. 다시 로그인해주세요."
            case .serverError(let message):
                self.errorMessage = "서버 오류: \(message)"
            default:
                self.errorMessage = "검색 중 오류가 발생했습니다."
            }
        } else {
            self.errorMessage = "네트워크 오류가 발생했습니다."
        }
    }
}
