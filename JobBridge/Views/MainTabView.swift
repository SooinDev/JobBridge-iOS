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
                    CompanyHomeView(jobViewModel: jobViewModel)
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

// MARK: - CompanyHomeView (기업용 홈 화면)
struct CompanyHomeView: View {
    @ObservedObject var jobViewModel: JobViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var companyJobViewModel = CompanyJobViewModel()
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 기업 환영 헤더
                CompanyWelcomeHeaderView()
                
                // 빠른 액션 버튼들 (기업용)
                CompanyQuickActionsView()
                
                // 내 채용공고 현황
                MyJobPostingsSection(viewModel: companyJobViewModel)
                
                // 최근 지원자 현황 (추후 구현)
                RecentApplicationsSection()
                
                // 인재 매칭 추천 (추후 구현)
                RecommendedTalentsSection()
            }
            .padding()
        }
        .navigationTitle("기업 대시보드")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isLoading = true
            
            Task {
                // 기업 데이터 로드
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        if companyJobViewModel.myJobPostings.isEmpty {
                            await companyJobViewModel.loadMyJobPostings()
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    isLoading = false
                }
            }
        }
        .overlay {
            if isLoading {
                LoadingView(message: "데이터를 불러오는 중...")
            }
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

// MARK: - CompanyQuickActionsView
struct CompanyQuickActionsView: View {
    var body: some View {
        HStack(spacing: 12) {
            CompanyQuickActionButton(
                icon: "plus.circle.fill",
                title: "채용공고 등록",
                destination: AnyView(CreateJobPostingView(viewModel: CompanyJobViewModel()))
            )
            
            CompanyQuickActionButton(
                icon: "person.3.sequence.fill",
                title: "채용공고 관리",
                destination: AnyView(CompanyJobManagementView())
            )
            
            CompanyQuickActionButton(
                icon: "sparkles",
                title: "인재 매칭",
                destination: AnyView(CompanyResumeMatchingView())
            )
        }
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

// MARK: - CompanyResumeMatchingView (추후 구현)
struct CompanyResumeMatchingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.purple)
            
            Text("AI 인재 매칭")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("이 기능은 곧 출시될 예정입니다.\nAI 기반 인재 매칭 시스템을 준비 중입니다.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
        .navigationTitle("인재 매칭")
    }
}

// MARK: - CompanyProfileView (기업용 프로필)
struct CompanyProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogoutAlert = false
    
    var body: some View {
        Form {
            // 기업 정보 섹션
            Section(header: Text("기업 정보")) {
                HStack {
                    Image(systemName: "building.2.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                        .padding(.trailing, 10)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(authViewModel.currentUser?.name ?? "기업")
                            .font(.headline)
                        
                        Text(authViewModel.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("기업 회원")
                            .font(.caption)
                            .padding(5)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                }
                .padding(.vertical, 5)
            }
            
            // 채용 관리 섹션
            Section(header: Text("채용 관리")) {
                NavigationLink(destination: CompanyJobManagementView()) {
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .foregroundColor(.blue)
                        Text("채용공고 관리")
                    }
                }
                
                NavigationLink(destination: CompanyResumeMatchingView()) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("인재 매칭")
                    }
                }
            }
            
            // 앱 정보 섹션
            Section(header: Text("앱 정보")) {
                HStack {
                    Text("버전")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://yourapp.com/privacy")!) {
                    HStack {
                        Text("개인정보 처리방침")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }
                
                Link(destination: URL(string: "https://yourapp.com/terms")!) {
                    HStack {
                        Text("이용약관")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }
            }
            
            // 로그아웃 섹션
            Section {
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    HStack {
                        Spacer()
                        Text("로그아웃")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("기업 프로필")
        .alert(isPresented: $showingLogoutAlert) {
            Alert(
                title: Text("로그아웃"),
                message: Text("정말 로그아웃 하시겠습니까?"),
                primaryButton: .destructive(Text("로그아웃")) {
                    authViewModel.logout()
                },
                secondaryButton: .cancel(Text("취소"))
            )
        }
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
