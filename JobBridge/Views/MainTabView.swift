import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var resumeViewModel = ResumeViewModel()
    @StateObject private var jobViewModel = JobViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 홈 탭
            NavigationView {
                HomeView(jobViewModel: jobViewModel, resumeViewModel: resumeViewModel)
            }
            .tabItem {
                Label("홈", systemImage: "house.fill")
            }
            .tag(0)
            
            // 채용공고 탭
            NavigationView {
                JobsView(viewModel: jobViewModel)
            }
            .tabItem {
                Label("채용공고", systemImage: "briefcase.fill")
            }
            .tag(1)
            
            // 이력서 탭
            NavigationView {
                ResumesView(viewModel: resumeViewModel)
            }
            .tabItem {
                Label("이력서", systemImage: "doc.text.fill")
            }
            .tag(2)
            
            // 지원 내역 탭
            NavigationView {
                MyApplicationsView()
            }
            .tabItem {
                Label("지원내역", systemImage: "paperplane.fill")
            }
            .tag(3)
            
            // 프로필 탭
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("내 정보", systemImage: "person.fill")
            }
            .tag(4)
        }
        .accentColor(AppTheme.primary)
        .onAppear {
            // 탭 바 외관 설정
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // 선택/미선택 아이템 컬러 설정
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
}

struct HomeView: View {
    @ObservedObject var jobViewModel: JobViewModel
    @ObservedObject var resumeViewModel: ResumeViewModel
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더 (사용자 환영 메시지)
                WelcomeHeaderView()
                
                // 빠른 액션 버튼들
                QuickActionsView()
                
                // 추천 채용공고
                RecommendedJobsSection(jobViewModel: jobViewModel)
                
                // 최근 지원 내역
                RecentApplicationsSection()
                
                // 이력서 관리
                ResumesSection(resumeViewModel: resumeViewModel)
            }
            .padding()
        }
        .navigationTitle("JobBridge")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isLoading = true
            // 데이터 로드
            Task {
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        if jobViewModel.jobs.isEmpty {
                            await jobViewModel.loadRecentJobs()
                        }
                    }
                    
                    group.addTask {
                        if resumeViewModel.resumes.isEmpty {
                            await resumeViewModel.loadResumes()
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

struct WelcomeHeaderView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("안녕하세요!")
                .heading2()
            
            Text("\(authViewModel.currentUser?.name ?? "회원")님")
                .heading1()
                .foregroundColor(AppTheme.primary)
            
            Text("오늘도 좋은 기회를 찾아보세요!")
                .body2()
        }
        .padding(.vertical, 8)
    }
}

struct QuickActionsView: View {
    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(icon: "doc.text.magnifyingglass", title: "이력서 작성", destination: AnyView(AddResumeView(viewModel: ResumeViewModel())))
            
            QuickActionButton(icon: "briefcase.fill", title: "채용공고 검색", destination: AnyView(JobsView(viewModel: JobViewModel())))
            
            QuickActionButton(icon: "bell.fill", title: "추천공고", destination: AnyView(JobsView(viewModel: JobViewModel())))
        }
    }
}

struct QuickActionButton<Destination: View>: View {
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
    }
}

struct RecommendedJobsSection: View {
    @ObservedObject var jobViewModel: JobViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("추천 채용공고")
                    .heading3()
                
                Spacer()
                
                NavigationLink(destination: JobsView(viewModel: JobViewModel())) {
                    Text("모두 보기")
                        .caption()
                        .foregroundColor(AppTheme.primary)
                }
            }
            
            if jobViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if jobViewModel.jobs.isEmpty {
                EmptyStateView(
                    icon: "briefcase",
                    title: "추천 공고 없음",
                    message: "맞춤 채용공고를 준비 중입니다.",
                    buttonTitle: "채용공고 보기",
                    buttonAction: { jobViewModel.loadRecentJobs() }
                )
                .frame(height: 200)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(jobViewModel.jobs.prefix(5)) { job in
                            NavigationLink(destination: JobDetailView(job: job)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(job.title)
                                        .heading3()
                                        .lineLimit(1)
                                    
                                    Text(job.companyName ?? "기업명 없음")
                                        .body2()
                                    
                                    Divider()
                                    
                                    HStack {
                                        Text(job.location)
                                            .caption()
                                        
                                        Spacer()
                                        
                                        Text(job.experienceLevel)
                                            .caption()
                                    }
                                    
                                    if let matchRate = job.matchRate {
                                        HStack {
                                            Spacer()
                                            Text("일치도: \(Int(matchRate * 100))%")
                                                .caption()
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.green.opacity(0.2))
                                                .foregroundColor(.green)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                                .padding()
                                .frame(width: 280, height: 180)
                                .background(AppTheme.secondaryBackground)
                                .cornerRadius(12)
                                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                .foregroundColor(AppTheme.textPrimary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

struct RecentApplicationsSection: View {
    @StateObject private var viewModel = ApplicationViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최근 지원 내역")
                    .heading3()
                
                Spacer()
                
                NavigationLink(destination: MyApplicationsView()) {
                    Text("모두 보기")
                        .caption()
                        .foregroundColor(AppTheme.primary)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if let errorMessage = viewModel.errorMessage {
                ErrorView(
                    message: errorMessage,
                    retryAction: { viewModel.loadMyApplications() }
                )
                .frame(height: 150)
            } else if viewModel.applications.isEmpty {
                EmptyStateView(
                    icon: "paperplane",
                    title: "지원 내역 없음",
                    message: "아직 지원한 공고가 없습니다.",
                    buttonTitle: "채용공고 보기",
                    buttonAction: nil
                )
                .frame(height: 150)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.applications.prefix(3)) { application in
                        NavigationLink(destination: JobDetailView(jobId: application.jobPostingId)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(application.jobTitle)
                                        .body1()
                                        .lineLimit(1)
                                    
                                    Text(application.companyName)
                                        .body2()
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("지원 완료")
                                        .caption()
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundColor(.green)
                                        .cornerRadius(20)
                                    
                                    Text(formatDate(application.appliedAt))
                                        .caption()
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                            }
                            .padding()
                            .background(AppTheme.secondaryBackground)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadMyApplications()
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // 다양한 날짜 형식을 처리할 수 있도록 여러 포맷터 준비
        let formatters: [DateFormatter] = [
            // ISO 8601 형식 (yyyy-MM-dd'T'HH:mm:ss)
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }(),
            // yyyy-MM-dd HH:mm 형식
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                return formatter
            }(),
            // yyyy-MM-dd 형식
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }()
        ]
        
        // 모든 포맷터로 파싱 시도
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                // 출력용 포맷터
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "yyyy년 M월 d일"
                outputFormatter.locale = Locale(identifier: "ko_KR")
                return outputFormatter.string(from: date)
            }
        }
        
        return dateString
    }
}

struct ResumesSection: View {
    @ObservedObject var resumeViewModel: ResumeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("내 이력서")
                    .heading3()
                
                Spacer()
                
                NavigationLink(destination: ResumesView(viewModel: resumeViewModel)) {
                    Text("모두 보기")
                        .caption()
                        .foregroundColor(AppTheme.primary)
                }
            }
            
            if resumeViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if resumeViewModel.resumes.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "이력서 없음",
                    message: "이력서를 작성하고 맞춤 채용공고를 추천받으세요.",
                    buttonTitle: "이력서 작성하기",
                    buttonAction: nil
                )
                .frame(height: 150)
            } else {
                VStack(spacing: 12) {
                    ForEach(resumeViewModel.resumes.prefix(2)) { resume in
                        NavigationLink(destination: ResumeDetailView(resume: resume)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(resume.title)
                                        .body1()
                                        .lineLimit(1)
                                    
                                    HStack {
                                        Image(systemName: "calendar")
                                            .font(.caption)
                                        
                                        Text(formatDate(resume.createdAt))
                                            .caption()
                                    }
                                    .foregroundColor(AppTheme.textTertiary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppTheme.textTertiary)
                            }
                            .padding()
                            .background(AppTheme.secondaryBackground)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "yyyy년 MM월 dd일"
            return dateFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
    }
}
