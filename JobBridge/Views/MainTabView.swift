// MARK: - 업데이트된 MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var resumeViewModel = ResumeViewModel()
    @StateObject private var jobViewModel = JobViewModel()
    @State private var selectedTab = 0
    
    // 사용자 타입 확인
    private var userType: String {
        authViewModel.currentUser?.userType ?? "INDIVIDUAL"
    }
    
    private var isCompany: Bool {
        userType == "COMPANY"
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 홈 탭 (공통)
            NavigationView {
                if isCompany {
                    CompanyHomeView()
                } else {
                    HomeView(jobViewModel: jobViewModel, resumeViewModel: resumeViewModel)
                }
            }
            .tabItem {
                Label("홈", systemImage: "house.fill")
            }
            .tag(0)
            
            // 채용공고 탭 (공통)
            NavigationView {
                JobsView(viewModel: jobViewModel)
            }
            .tabItem {
                Label("채용공고", systemImage: "briefcase.fill")
            }
            .tag(1)
            
            // 조건부 탭들
            if isCompany {
                // 기업용 탭들
                NavigationView {
                    CompanyJobManagementView()
                }
                .tabItem {
                    Label("채용관리", systemImage: "person.3.sequence.fill")
                }
                .tag(2)
                
                NavigationView {
                    CompanyResumeMatchingView()
                }
                .tabItem {
                    Label("인재매칭", systemImage: "sparkles")
                }
                .tag(3)
                
                NavigationView {
                    CompanyProfileView()
                }
                .tabItem {
                    Label("내 정보", systemImage: "building.2.fill")
                }
                .tag(4)
            } else {
                // 개인용 탭들
                NavigationView {
                    HashtagFilterSearchView()
                }
                .tabItem {
                    Label("해시태그", systemImage: "number")
                }
                .tag(2)
                
                NavigationView {
                    ResumesView(viewModel: resumeViewModel)
                }
                .tabItem {
                    Label("이력서", systemImage: "doc.text.fill")
                }
                .tag(3)
                
                NavigationView {
                    MyApplicationsView()
                }
                .tabItem {
                    Label("지원내역", systemImage: "paperplane.fill")
                }
                .tag(4)
                
                NavigationView {
                    ProfileView()
                }
                .tabItem {
                    Label("내 정보", systemImage: "person.fill")
                }
                .tag(5)
            }
        }
        .accentColor(AppTheme.primary)
        .onAppear {
            setupTabBarAppearance()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor.gray
        itemAppearance.selected.iconColor = UIColor(AppTheme.primary)
        
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

// MARK: - CompanyWelcomeHeaderView
struct CompanyWelcomeHeaderView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("안녕하세요!")
                .heading2()
            
            Text("\(authViewModel.currentUser?.name ?? "기업")님")
                .heading1()
                .foregroundColor(AppTheme.primary)
            
            Text("우수한 인재를 찾고 채용공고를 효율적으로 관리하세요!")
                .body2()
        }
        .padding(.vertical, 8)
    }
}

struct CompanyQuickActionButton<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(AppTheme.primary)
                    .cornerRadius(10)
                
                Text(title)
                    .caption()
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundColor(AppTheme.textPrimary)
    }
}

// MARK: - MyJobPostingsSection
struct MyJobPostingsSection: View {
    @ObservedObject var viewModel: CompanyJobViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("내 채용공고")
                    .heading3()
                
                Spacer()
                
                NavigationLink(destination: CompanyJobManagementView()) {
                    Text("모두 보기")
                        .caption()
                        .foregroundColor(AppTheme.primary)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.myJobPostings.isEmpty {
                EmptyStateView(
                    icon: "briefcase.badge.plus",
                    title: "등록된 채용공고 없음",
                    message: "첫 번째 채용공고를 등록해보세요.",
                    buttonTitle: "채용공고 등록하기",
                    buttonAction: nil
                )
                .frame(height: 200)
            } else {
                VStack(spacing: 12) {
                    // 통계 요약
                    HStack(spacing: 16) {
                        CompanyStatCard(
                            title: "총 공고",
                            value: "\(viewModel.myJobPostings.count)",
                            color: .blue
                        )
                        
                        CompanyStatCard(
                            title: "진행중",
                            value: "\(getActiveJobsCount())",
                            color: .green
                        )
                        
                        CompanyStatCard(
                            title: "지원자",
                            value: "\(viewModel.totalApplications)",
                            color: .orange
                        )
                    }
                    
                    // 최근 공고 미리보기
                    VStack(spacing: 8) {
                        ForEach(viewModel.myJobPostings.prefix(3)) { job in
                            NavigationLink(destination: CompanyJobDetailView(job: job, viewModel: viewModel)) {
                                CompanyJobPreviewRow(job: job)
                            }
                            .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
            }
        }
        .onAppear {
            if viewModel.myJobPostings.isEmpty {
                viewModel.loadMyJobPostings()
            }
        }
    }
    
    private func getActiveJobsCount() -> Int {
        viewModel.myJobPostings.filter { job in
            guard let deadline = job.deadline else { return true }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            guard let deadlineDate = formatter.date(from: deadline) else { return true }
            return deadlineDate >= Date()
        }.count
    }
}

// MARK: - CompanyStatCard
struct CompanyStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - CompanyJobPreviewRow
struct CompanyJobPreviewRow: View {
    let job: JobPostingResponse
    
    private var statusColor: Color {
        guard let deadline = job.deadline else { return .green }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        guard let deadlineDate = formatter.date(from: deadline) else { return .green }
        
        if deadlineDate < Date() {
            return .red
        } else {
            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: deadlineDate).day ?? 0
            return daysLeft <= 3 ? .orange : .green
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .body1()
                    .lineLimit(1)
                
                HStack {
                    Text(job.location)
                        .caption()
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text("•")
                        .caption()
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text(job.experienceLevel)
                        .caption()
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(job.createdAt.toShortDate())
                    .caption()
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 추후 구현할 섹션들
struct RecentApplicationsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최근 지원자")
                    .heading3()
                
                Spacer()
                
                Text("모두 보기")
                    .caption()
                    .foregroundColor(AppTheme.primary)
            }
            
            EmptyStateView(
                icon: "person.3.sequence.fill",
                title: "지원자 관리",
                message: "지원자 관리 기능을 준비 중입니다.",
                buttonTitle: nil,
                buttonAction: nil
            )
            .frame(height: 150)
        }
    }
}

struct RecommendedTalentsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("추천 인재")
                    .heading3()
                
                Spacer()
                
                Text("모두 보기")
                    .caption()
                    .foregroundColor(AppTheme.primary)
            }
            
            EmptyStateView(
                icon: "sparkles",
                title: "AI 인재 추천",
                message: "AI 기반 인재 추천 기능을 준비 중입니다.",
                buttonTitle: nil,
                buttonAction: nil
            )
            .frame(height: 150)
        }
    }
}
