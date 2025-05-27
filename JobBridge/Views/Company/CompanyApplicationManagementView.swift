// CompanyApplicationManagementView.swift - 실제 API만 사용
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
                            // 실제 API만 사용
                            viewModel.refresh(for: job.id)
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
                    // 실제 API로 새로고침
                    viewModel.refresh(for: job.id)
                }) {
                    Label("새로고침", systemImage: "arrow.clockwise")
                }
                
                Button(action: {
                    // TODO: 지원자 내보내기 기능
                }) {
                    Label("지원자 목록 내보내기", systemImage: "square.and.arrow.up")
                }
                
                Button(action: {
                    // 디버그 정보 출력
                    viewModel.debugLogCurrentState()
                }) {
                    Label("디버그 정보", systemImage: "info.circle")
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
            // 화면 진입 시 실제 API로 데이터 로드
            print("🔵 지원자 관리 화면 진입 - 실제 API 사용")
            viewModel.refresh(for: job.id)
        }
        .refreshable {
            // 당겨서 새로고침 시에도 실제 API 사용
            viewModel.refresh(for: job.id)
        }
    }
}

// MARK: - 실제 API 사용 안내 메시지
struct RealAPIInfoBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("실제 API 연동")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("서버에서 실제 지원자 데이터를 불러옵니다")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 기존 컴포넌트들 (수정 없음)
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
            
            // 실제 API 사용 배너 추가
            RealAPIInfoBanner()
            
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

// MARK: - 나머지 컴포넌트들은 기존과 동일
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
            
            // 실제 API 사용 안내
            VStack(spacing: 8) {
                Text("💡 실제 서버 데이터 연동 중")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text("Mock 데이터 대신 실제 백엔드 API에서 지원자 정보를 불러옵니다")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding()
    }
}
