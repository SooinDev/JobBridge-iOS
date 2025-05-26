// CompanyApplicationManagementView.swift - 기업용 지원자 관리 메인 화면
import SwiftUI

struct CompanyApplicationManagementView: View {
    let job: JobPostingResponse
    @StateObject private var viewModel = CompanyApplicationViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showingApplicationDetail = false
    @State private var selectedApplication: CompanyApplicationResponse?
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더 섹션
            CompanyApplicationHeaderView(job: job, stats: viewModel.stats)
                .padding()
                .background(AppTheme.secondaryBackground)
            
            // 필터 섹션
            ApplicationFilterView(
                selectedFilter: $viewModel.selectedFilter,
                filterCounts: viewModel.filterCounts,
                onFilterChanged: { filter in
                    viewModel.changeFilter(to: filter)
                }
            )
            .padding(.horizontal)
            .padding(.bottom)
            
            // 메인 컨텐츠
            Group {
                if viewModel.isLoading && viewModel.applications.isEmpty {
                    LoadingView(message: "지원자를 불러오는 중...")
                } else if let errorMessage = viewModel.errorMessage, viewModel.applications.isEmpty {
                    ErrorView(
                        message: errorMessage,
                        retryAction: {
                            viewModel.refresh(for: job.id, useMockData: true)
                        }
                    )
                } else if viewModel.filteredApplications.isEmpty {
                    EmptyApplicationsView(filter: viewModel.selectedFilter)
                } else {
                    ApplicationsListView(
                        applications: viewModel.filteredApplications,
                        onApplicationTapped: { application in
                            selectedApplication = application
                            showingApplicationDetail = true
                        }
                    )
                }
            }
            
            Spacer()
        }
        .navigationTitle("지원자 관리")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("닫기") {
                presentationMode.wrappedValue.dismiss()
            },
            trailing: Menu {
                Button(action: {
                    viewModel.refresh(for: job.id, useMockData: true)
                }) {
                    Label("새로고침", systemImage: "arrow.clockwise")
                }
                
                Button(action: {
                    // TODO: 지원자 내보내기 기능
                }) {
                    Label("지원자 목록 내보내기", systemImage: "square.and.arrow.up")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        )
        .sheet(isPresented: $showingApplicationDetail) {
            if let application = selectedApplication {
                CompanyApplicationDetailView(
                    application: application,
                    job: job,
                    viewModel: viewModel
                )
            }
        }
        .onAppear {
            viewModel.refresh(for: job.id, useMockData: true)
        }
    }
}

// MARK: - 헤더 뷰
struct CompanyApplicationHeaderView: View {
    let job: JobPostingResponse
    let stats: CompanyApplicationStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 채용공고 정보
            VStack(alignment: .leading, spacing: 8) {
                Text(job.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                
                HStack {
                    Text(job.position)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Spacer()
                    
                    Text("등록: \(job.createdAt.toShortDate())")
                        .font(.caption)
                        .foregroundColor(AppTheme.textTertiary)
                }
            }
            
            // 통계 정보
            if let stats = stats {
                HStack(spacing: 16) {
                    ApplicationStatCard(
                        title: "총 지원자",
                        value: "\(stats.totalApplications)",
                        icon: "person.3.fill",
                        color: .blue
                    )
                    
                    ApplicationStatCard(
                        title: "대기중",
                        value: "\(stats.pendingApplications)",
                        icon: "clock.fill",
                        color: .orange
                    )
                    
                    ApplicationStatCard(
                        title: "이번 달",
                        value: "\(stats.thisMonthApplications)",
                        icon: "calendar",
                        color: .green
                    )
                }
            }
        }
    }
}

// MARK: - 통계 카드
struct ApplicationStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 필터 뷰
struct ApplicationFilterView: View {
    @Binding var selectedFilter: ApplicationFilter
    let filterCounts: [ApplicationFilter: Int]
    let onFilterChanged: (ApplicationFilter) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ApplicationFilter.allCases, id: \.self) { filter in
                    ApplicationFilterButton(
                        filter: filter,
                        count: filterCounts[filter] ?? 0,
                        isSelected: selectedFilter == filter,
                        action: {
                            selectedFilter = filter
                            onFilterChanged(filter)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - 필터 버튼
struct ApplicationFilterButton: View {
    let filter: ApplicationFilter
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.systemImageName)
                    .font(.system(size: 14, weight: .medium))
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .medium))
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .foregroundColor(isSelected ? .white : filter.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? filter.color : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(filter.color, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - 지원자 목록 뷰
struct ApplicationsListView: View {
    let applications: [CompanyApplicationResponse]
    let onApplicationTapped: (CompanyApplicationResponse) -> Void
    
    var body: some View {
        List {
            ForEach(applications) { application in
                Button(action: {
                    onApplicationTapped(application)
                }) {
                    CompanyApplicationRow(application: application)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - 지원자 행
struct CompanyApplicationRow: View {
    let application: CompanyApplicationResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 상단: 지원자 이름과 상태
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(application.applicantName)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(application.applicantEmail)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                // 상태 배지
                Text(application.statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(application.statusColor.opacity(0.2))
                    .foregroundColor(application.statusColor)
                    .cornerRadius(8)
            }
            
            // 하단: 지원 정보
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("지원일: \(application.formattedAppliedDate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("상세보기")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 빈 상태 뷰
struct EmptyApplicationsView: View {
    let filter: ApplicationFilter
    
    private var emptyMessage: (icon: String, title: String, message: String) {
        switch filter {
        case .all:
            return (
                "person.3.sequence.fill",
                "지원자가 없습니다",
                "아직 이 채용공고에 지원한 사람이 없습니다.\n시간이 지나면 지원자들이 나타날 것입니다."
            )
        case .pending:
            return (
                "clock.fill",
                "대기중인 지원자가 없습니다",
                "모든 지원자의 검토가 완료되었습니다."
            )
        case .reviewed:
            return (
                "eye.fill",
                "검토 완료된 지원자가 없습니다",
                "아직 검토를 완료한 지원자가 없습니다."
            )
        case .accepted:
            return (
                "checkmark.circle.fill",
                "합격한 지원자가 없습니다",
                "아직 합격 처리된 지원자가 없습니다."
            )
        case .rejected:
            return (
                "xmark.circle.fill",
                "불합격한 지원자가 없습니다",
                "아직 불합격 처리된 지원자가 없습니다."
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: emptyMessage.icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(emptyMessage.title)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(emptyMessage.message)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if filter == .all {
                // 채용공고 홍보 팁
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        
                        Text("지원자 모집 팁")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        CompanyTipRow(tip: "채용공고 제목을 구체적으로 작성하세요")
                        CompanyTipRow(tip: "요구 기술을 명확히 명시하세요")
                        CompanyTipRow(tip: "급여 정보를 투명하게 공개하세요")
                        CompanyTipRow(tip: "회사 문화와 복지를 어필하세요")
                    }
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

// MARK: - 팁 행
struct CompanyTipRow: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.yellow)
                .frame(width: 4, height: 4)
                .padding(.top, 6)
            
            Text(tip)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
    }
}
