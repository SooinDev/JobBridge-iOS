import SwiftUI

struct JobsView: View {
    @ObservedObject var viewModel: JobViewModel
    @State private var searchText = ""
    @State private var showAllJobs = false
    @State private var selectedFilter = JobFilter.recent
    
    enum JobFilter: String, CaseIterable {
        case recent = "최신순"
        case all = "전체"
        case saramin = "사람인"
        case user = "일반"
        
        var description: String {
            switch self {
            case .recent: return "최근 10개 채용공고"
            case .all: return "모든 채용공고"
            case .saramin: return "사람인 채용공고"
            case .user: return "일반 채용공고"
            }
        }
    }
    
    var filteredJobs: [JobPostingResponse] {
        let jobs = showAllJobs ? viewModel.allJobs : viewModel.jobs
        
        if searchText.isEmpty {
            return jobs
        } else {
            return jobs.filter { job in
                job.title.lowercased().contains(searchText.lowercased()) ||
                (job.companyName?.lowercased().contains(searchText.lowercased()) ?? false) ||
                job.position.lowercased().contains(searchText.lowercased()) ||
                job.requiredSkills.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 검색 및 필터 영역
            VStack(spacing: 12) {
                // 검색 바
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("채용공고 검색", text: $searchText)
                        .disableAutocorrection(true)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // 필터 선택
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(JobFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                action: {
                                    selectedFilter = filter
                                    loadJobsForFilter(filter)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .background(Color(.systemBackground))
            
            // 현재 선택된 필터 정보
            HStack {
                Text(selectedFilter.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !filteredJobs.isEmpty {
                    Text("\(filteredJobs.count)개")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // 메인 컨텐츠
            Group {
                if viewModel.isLoading && filteredJobs.isEmpty {
                    LoadingView(message: "채용공고를 불러오는 중...")
                } else if let errorMessage = viewModel.errorMessage, filteredJobs.isEmpty {
                    ErrorView(
                        message: errorMessage,
                        retryAction: { loadJobsForFilter(selectedFilter) }
                    )
                } else if filteredJobs.isEmpty {
                    EmptyStateView(
                        icon: searchText.isEmpty ? "doc.text.magnifyingglass" : "magnifyingglass",
                        title: searchText.isEmpty ? "채용공고가 없습니다" : "검색 결과가 없습니다",
                        message: searchText.isEmpty ?
                            "아직 등록된 채용공고가 없습니다." :
                            "'\(searchText)'에 대한 검색 결과가 없습니다."
                    )
                } else {
                    List {
                        ForEach(filteredJobs) { job in
                            NavigationLink(destination: JobDetailView(job: job)) {
                                EnhancedJobRow(job: job)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
        }
        .navigationTitle("채용공고")
        .refreshable {
            loadJobsForFilter(selectedFilter)
        }
        .onAppear {
            if viewModel.jobs.isEmpty && viewModel.allJobs.isEmpty {
                loadJobsForFilter(selectedFilter)
            }
        }
    }
    
    private func loadJobsForFilter(_ filter: JobFilter) {
        switch filter {
        case .recent:
            viewModel.loadRecentJobs()
            showAllJobs = false
        case .all:
            viewModel.loadAllJobs()
            showAllJobs = true
        case .saramin:
            // TODO: 사람인 공고만 필터링하는 기능 추가
            viewModel.loadAllJobs()
            showAllJobs = true
        case .user:
            // TODO: 일반 공고만 필터링하는 기능 추가
            viewModel.loadAllJobs()
            showAllJobs = true
        }
    }
}

// MARK: - 필터 버튼
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : AppTheme.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? AppTheme.primary : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppTheme.primary, lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - 향상된 채용공고 행
struct EnhancedJobRow: View {
    let job: JobPostingResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 제목과 회사명
            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
                
                HStack {
                    Text(job.companyName ?? "기업명 없음")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primary)
                    
                    Spacer()
                    
                    // 출처 표시
                    if job.companyName == "SARAMIN" {
                        Text("사람인")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
            }
            
            // 기본 정보
            HStack(spacing: 16) {
                InfoTag(icon: "location", text: job.location)
                InfoTag(icon: "briefcase", text: job.experienceLevel)
                
                Spacer()
                
                Text(job.createdAt.toShortDate())
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            
            // 급여 정보
            if !job.salary.isEmpty {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text(job.salary)
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                }
            }
            
            // 스킬 태그
            if !job.requiredSkills.isEmpty {
                let skills = job.requiredSkills.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .prefix(3)
                
                HStack {
                    ForEach(Array(skills), id: \.self) { skill in
                        Text(skill.hasPrefix("#") ? skill : "#\(skill)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary.opacity(0.1))
                            .foregroundColor(AppTheme.primary)
                            .cornerRadius(4)
                    }
                    
                    if skills.count < job.requiredSkills.components(separatedBy: ",").count {
                        Text("...")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            
            // 매칭률 (있는 경우)
            if let matchRate = job.matchRate {
                HStack {
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        
                        Text("일치도 \(Int(matchRate * 100))%")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 정보 태그
struct InfoTag: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(AppTheme.textSecondary)
            
            Text(text)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
    }
}

struct JobsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            JobsView(viewModel: JobViewModel())
        }
    }
}
