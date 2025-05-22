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
            
            // 해시태그 검색 탭 (버튼 방식으로 변경)
            NavigationView {
                HashtagFilterSearchView()
            }
            .tabItem {
                Label("해시태그", systemImage: "number")
            }
            .tag(2)
            
            // 이력서 탭
            NavigationView {
                ResumesView(viewModel: resumeViewModel)
            }
            .tabItem {
                Label("이력서", systemImage: "doc.text.fill")
            }
            .tag(3)
            
            // 지원 내역 탭
            NavigationView {
                MyApplicationsView()
            }
            .tabItem {
                Label("지원내역", systemImage: "paperplane.fill")
            }
            .tag(4)
            
            // 프로필 탭
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("내 정보", systemImage: "person.fill")
            }
            .tag(5)
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

// 홈 뷰에서 해시태그 빠른 선택 섹션 업데이트
struct HomeView: View {
    @ObservedObject var jobViewModel: JobViewModel
    @ObservedObject var resumeViewModel: ResumeViewModel
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더 (사용자 환영 메시지)
                WelcomeHeaderView()
                
                // 인기 해시태그 빠른 선택 섹션
                PopularHashtagsSection()
                
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

// MARK: - Popular Hashtags Section

struct PopularHashtagsSection: View {
    // 인기 해시태그 (홈 화면용 - 축약 버전)
    private let popularHashtags = [
        HashtagItem(hashtag: "#자바", icon: "cup.and.saucer.fill", color: .orange),
        HashtagItem(hashtag: "#Python", icon: "snake.fill", color: .green),
        HashtagItem(hashtag: "#JavaScript", icon: "globe", color: .yellow),
        HashtagItem(hashtag: "#Swift", icon: "swift", color: .blue),
        HashtagItem(hashtag: "#React", icon: "atom", color: .cyan),
        HashtagItem(hashtag: "#AI", icon: "brain.head.profile", color: .purple)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("인기 해시태그")
                    .heading3()
                
                Spacer()
                
                NavigationLink(destination: HashtagFilterSearchView()) {
                    Text("전체 보기")
                        .caption()
                        .foregroundColor(AppTheme.primary)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(popularHashtags, id: \.hashtag) { item in
                    NavigationLink(destination: HashtagFilterSearchView(preselectedHashtag: item.hashtag)) {
                        VStack(spacing: 8) {
                            Image(systemName: item.icon)
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(item.color)
                                .cornerRadius(12)
                            
                            Text(item.hashtag)
                                .caption()
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .cornerRadius(12)
    }
}

// MARK: - Hashtag Item Model

struct HashtagItem {
    let hashtag: String
    let icon: String
    let color: Color
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
            
            Text("해시태그로 원하는 채용공고를 쉽게 찾아보세요!")
                .body2()
        }
        .padding(.vertical, 8)
    }
}

struct QuickActionsView: View {
    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "doc.text.magnifyingglass",
                title: "이력서 작성",
                destination: AnyView(AddResumeView(viewModel: ResumeViewModel()))
            )
            
            QuickActionButton(
                icon: "number",
                title: "해시태그 검색",
                destination: AnyView(HashtagFilterSearchView())
            )
            
            QuickActionButton(
                icon: "briefcase.fill",
                title: "전체 공고",
                destination: AnyView(JobsView(viewModel: JobViewModel()))
            )
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
                    buttonTitle: "해시태그로 검색",
                    buttonAction: nil
                )
                .frame(height: 200)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(jobViewModel.jobs.prefix(5)) { job in
                            NavigationLink(destination: JobDetailView(job: job)) {
                                JobCardView(job: job)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Job Card View

struct JobCardView: View {
    let job: JobPostingResponse
    
    var body: some View {
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
            
            // 스킬 태그 미리보기
            if !job.requiredSkills.isEmpty {
                let skills = job.requiredSkills.components(separatedBy: ",")
                    .prefix(2)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                
                HStack {
                    ForEach(skills, id: \.self) { skill in
                        Text(skill.hasPrefix("#") ? skill : "#\(skill)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary.opacity(0.1))
                            .foregroundColor(AppTheme.primary)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
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
        .frame(width: 280, height: 200)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .foregroundColor(AppTheme.textPrimary)
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
                    message: "해시태그로 관심 공고를 찾아 지원해보세요.",
                    buttonTitle: "해시태그 검색",
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
        let formatters: [DateFormatter] = [
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }()
        ]
        
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
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
                    message: "이력서를 작성하고 해시태그로 맞춤 공고를 찾아보세요.",
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
