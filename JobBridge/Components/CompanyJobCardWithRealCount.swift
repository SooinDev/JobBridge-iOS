// CompanyJobCardWithRealCount.swift - 실제 지원자 수 표시
import SwiftUI

struct CompanyJobCardWithRealCount: View {
    let job: JobPostingResponse
    let applicationCount: Int
    let isLoadingCount: Bool
    let onTapped: () -> Void
    let onManageApplications: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 상단: 제목과 상태
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .lineLimit(2)
                    
                    Text(job.position)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 채용공고 상태
                JobStatusBadge(job: job)
            }
            
            // 중간: 기본 정보
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(job.location, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Label(job.experienceLevel, systemImage: "briefcase.fill")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                
                if !job.requiredSkills.isEmpty {
                    Text("필요 기술: \(job.requiredSkills)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            // 🔥 지원자 수 표시 (실제 API 데이터)
            HStack {
                RealApplicationCountView(
                    count: applicationCount,
                    isLoading: isLoadingCount
                )
                
                Spacer()
                
                Text("등록: \(job.createdAt.toShortDate())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 하단: 액션 버튼들
            HStack(spacing: 12) {
                // 지원자 관리 버튼
                Button(action: onManageApplications) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.3.fill")
                            .font(.caption)
                        
                        Text("지원자 관리")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                
                // 수정 버튼
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                }
                
                // 삭제 버튼
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                // 상세보기 버튼
                Button(action: onTapped) {
                    HStack(spacing: 4) {
                        Text("상세보기")
                            .font(.caption)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(20)
        .background(
            colorScheme == .dark ?
            Color(UIColor.secondarySystemBackground) :
            Color.white
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 실제 지원자 수 표시 컴포넌트
struct RealApplicationCountView: View {
    let count: Int
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.3.fill")
                .font(.caption)
                .foregroundColor(countColor)
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 12, height: 12)
                
                Text("로딩중...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("지원자 \(count)명")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(countColor)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(countColor.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var countColor: Color {
        if isLoading {
            return .gray
        } else if count == 0 {
            return .gray
        } else if count <= 5 {
            return .green
        } else if count <= 15 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - 채용공고 상태 배지
struct JobStatusBadge: View {
    let job: JobPostingResponse
    
    private var statusInfo: (text: String, color: Color) {
        if job.isExpired {
            return ("마감", .red)
        } else if let days = job.daysUntilDeadline {
            if days <= 0 {
                return ("오늘 마감", .orange)
            } else if days <= 3 {
                return ("D-\(days)", .orange)
            } else {
                return ("진행중", .green)
            }
        } else {
            return ("상시채용", .blue)
        }
    }
    
    var body: some View {
        Text(statusInfo.text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusInfo.color)
            .cornerRadius(8)
    }
}

// MARK: - 사용 예시를 위한 컨테이너 뷰
struct CompanyJobListWithRealCount: View {
    @ObservedObject var viewModel: CompanyJobViewModel
    @State private var showingCreateJob = false
    @State private var showingApplicationManagement = false
    @State private var selectedJob: JobPostingResponse?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("내 채용공고")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if viewModel.isLoadingApplicationCounts {
                        Text("지원자 수 집계 중...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("총 \(viewModel.totalApplications)명이 지원했습니다")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingCreateJob = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            
            // 채용공고 목록
            if viewModel.isLoading {
                LoadingView(message: "채용공고를 불러오는 중...")
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage) {
                    viewModel.refresh()
                }
            } else if viewModel.myJobPostings.isEmpty {
                EmptyStateView(
                    icon: "doc.text.fill",
                    title: "등록된 채용공고가 없습니다",
                    message: "첫 번째 채용공고를 등록하고 인재를 찾아보세요!",
                    buttonTitle: "채용공고 등록",
                    buttonAction: {
                        showingCreateJob = true
                    }
                )
                .padding(.horizontal)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.myJobPostings) { job in
                            CompanyJobCardWithRealCount(
                                job: job,
                                applicationCount: viewModel.getApplicationCount(for: job.id),
                                isLoadingCount: viewModel.isLoadingApplicationCounts,
                                onTapped: {
                                    // TODO: 상세보기
                                },
                                onManageApplications: {
                                    selectedJob = job
                                    showingApplicationManagement = true
                                },
                                onEdit: {
                                    // TODO: 수정
                                },
                                onDelete: {
                                    viewModel.deleteJobPosting(jobId: job.id)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 오류 메시지 (지원자 수 조회 실패 시)
            if let applicationCountsError = viewModel.applicationCountsError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("지원자 수 조회 실패: \(applicationCountsError)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("다시 시도") {
                        viewModel.loadRealApplicationCounts()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingCreateJob) {
            // TODO: CreateJobPostingView
            Text("채용공고 등록")
        }
        .sheet(isPresented: $showingApplicationManagement) {
            if let job = selectedJob {
                CompanyApplicationManagementView(job: job)
            }
        }
        .onAppear {
            viewModel.refresh()
        }
        .refreshable {
            viewModel.refresh()
        }
    }
}
