// MARK: - CompanyJobManagementView.swift
import SwiftUI

struct CompanyJobManagementView: View {
    @StateObject private var viewModel = CompanyJobViewModel()
    @State private var showingCreateJob = false
    @State private var selectedFilter = JobFilter.all
    
    enum JobFilter: String, CaseIterable {
        case all = "전체"
        case active = "진행중"
        case expired = "마감"
        
        var description: String {
            switch self {
            case .all: return "모든 채용공고"
            case .active: return "현재 진행중인 공고"
            case .expired: return "마감된 공고"
            }
        }
    }
    
    var filteredJobs: [JobPostingResponse] {
        switch selectedFilter {
        case .all:
            return viewModel.myJobPostings
        case .active:
            return viewModel.myJobPostings.filter { job in
                guard let deadline = job.deadline else { return true }
                return !isExpired(deadline)
            }
        case .expired:
            return viewModel.myJobPostings.filter { job in
                guard let deadline = job.deadline else { return false }
                return isExpired(deadline)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상단 통계 카드
                CompanyJobStatsView(
                    totalJobs: viewModel.myJobPostings.count,
                    activeJobs: viewModel.myJobPostings.filter { job in
                        guard let deadline = job.deadline else { return true }
                        return !isExpired(deadline)
                    }.count,
                    totalApplications: viewModel.totalApplications
                )
                .padding()
                
                // 필터 선택
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(JobFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
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
                    if viewModel.isLoading && viewModel.myJobPostings.isEmpty {
                        LoadingView(message: "채용공고를 불러오는 중...")
                    } else if let errorMessage = viewModel.errorMessage, viewModel.myJobPostings.isEmpty {
                        ErrorView(
                            message: errorMessage,
                            retryAction: { viewModel.loadMyJobPostings() }
                        )
                    } else if filteredJobs.isEmpty {
                        EmptyCompanyJobsView(
                            filter: selectedFilter,
                            onCreateAction: { showingCreateJob = true }
                        )
                    } else {
                        List {
                            ForEach(filteredJobs) { job in
                                NavigationLink(destination: CompanyJobDetailView(job: job, viewModel: viewModel)) {
                                    CompanyJobRow(job: job)
                                }
                            }
                            .onDelete(perform: deleteJobs)
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
            }
            .navigationTitle("채용공고 관리")
            .navigationBarItems(trailing: Button(action: {
                showingCreateJob = true
            }) {
                Image(systemName: "plus")
                    .font(.title2)
            })
            .sheet(isPresented: $showingCreateJob) {
                CreateJobPostingView(viewModel: viewModel)
            }
            .refreshable {
                viewModel.loadMyJobPostings()
            }
            .onAppear {
                viewModel.loadMyJobPostings()
            }
        }
    }
    
    private func deleteJobs(offsets: IndexSet) {
        for index in offsets {
            let job = filteredJobs[index]
            viewModel.deleteJobPosting(jobId: job.id)
        }
    }
    
    private func isExpired(_ deadlineString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        guard let deadline = formatter.date(from: deadlineString) else { return false }
        return deadline < Date()
    }
}
