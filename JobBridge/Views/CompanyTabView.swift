// CompanyTabView.swift - 기업회원용 메인 탭 뷰 (완전 수정 버전)
import SwiftUI

struct CompanyTabView: View {
    @State private var selectedTab = 0
    @AppStorage("companyOnboardingCompleted") private var onboardingCompleted = false
    @State private var showingOnboarding = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. 홈 - 대시보드
            CompanyHomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("홈")
                }
                .tag(0)
            
            // 2. 채용공고 관리
            CompanyJobManagementView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "briefcase.fill" : "briefcase")
                    Text("채용공고")
                }
                .tag(1)
            
            // 3. AI 인재 매칭
            CompanyResumeMatchingView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "sparkles" : "sparkles")
                    Text("AI 매칭")
                }
                .tag(2)
            
            // 4. 지원자 관리
            CompanyApplicationDashboardView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.3.fill" : "person.3")
                    Text("지원자")
                }
                .tag(3)
            
            // 5. 프로필
            CompanyProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.crop.circle.fill" : "person.crop.circle")
                    Text("프로필")
                }
                .tag(4)
        }
        .accentColor(AppTheme.primary)
        .onAppear {
            setupTabBarAppearance()
            
            // 온보딩 체크
            if !onboardingCompleted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingOnboarding = true
                }
            }
        }
        .sheet(isPresented: $showingOnboarding) {
            CompanyOnboardingView(isPresented: $showingOnboarding)
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        // 선택된 탭 색상
        appearance.selectionIndicatorTintColor = UIColor(AppTheme.primary)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - 기업 홈 뷰 (대시보드)
struct CompanyHomeView: View {
    @StateObject private var jobViewModel = CompanyJobViewModel()
    @StateObject private var applicationViewModel = CompanyApplicationViewModel()
    @State private var showingCreateJob = false
    @State private var currentDate = Date()
    
    // 타이머를 위한 속성
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 환영 헤더
                    CompanyWelcomeHeader(currentDate: currentDate)
                        .padding(.horizontal)
                    
                    // 빠른 액션 버튼들
                    CompanyQuickActionsView(showingCreateJob: $showingCreateJob)
                        .padding(.horizontal)
                    
                    // 통계 대시보드
                    CompanyStatsDashboard(jobViewModel: jobViewModel)
                        .padding(.horizontal)
                    
                    // 최근 채용공고
                    CompanyRecentJobsSection(jobViewModel: jobViewModel)
                        .padding(.horizontal)
                    
                    // AI 매칭 프로모션
                    CompanyAIMatchingPromotion()
                        .padding(.horizontal)
                    
                    // 팁 및 가이드
                    CompanyTipsSection()
                        .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .navigationTitle("기업 대시보드")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await refreshData()
            }
        }
        .onReceive(timer) { _ in
            currentDate = Date()
        }
        .onAppear {
            loadInitialData()
        }
        .sheet(isPresented: $showingCreateJob) {
            CreateJobPostingView(viewModel: jobViewModel)
        }
    }
    
    private func loadInitialData() {
        jobViewModel.loadMyJobPostings()
    }
    
    private func refreshData() async {
        jobViewModel.refresh()
    }
}

// MARK: - 환영 헤더
struct CompanyWelcomeHeader: View {
    let currentDate: Date
    @AppStorage("userName") private var userName = "기업"
    
    private var timeOfDayGreeting: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        switch hour {
        case 5..<12: return "좋은 아침이에요! ☀️"
        case 12..<18: return "좋은 오후예요! ☀️"
        case 18..<22: return "좋은 저녁이에요! 🌅"
        default: return "늦은 시간까지 수고하세요! 🌙"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: currentDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(timeOfDayGreeting)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(userName) 님")
                        .font(.title3)
                        .foregroundColor(AppTheme.primary)
                    
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 회사 아이콘
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 빠른 액션 뷰
struct CompanyQuickActionsView: View {
    @Binding var showingCreateJob: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("빠른 작업")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                // 채용공고 등록 버튼
                Button(action: { showingCreateJob = true }) {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.blue)
                        
                        Text("채용공고\n등록")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // AI 인재 매칭 버튼
                Button(action: {
                    // TODO: AI 매칭 탭으로 이동
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 24))
                            .foregroundColor(.purple)
                        
                        Text("AI 인재\n매칭")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // 지원자 관리 버튼
                Button(action: {
                    // TODO: 지원자 탭으로 이동
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                        
                        Text("지원자\n관리")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // 통계 보기 버튼
                Button(action: {
                    // TODO: 통계 화면으로 이동
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                        
                        Text("통계\n보기")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
}

// MARK: - 통계 대시보드
struct CompanyStatsDashboard: View {
    @ObservedObject var jobViewModel: CompanyJobViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("현황 요약")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                // 등록 공고 카드
                VStack(spacing: 8) {
                    Image(systemName: "briefcase.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("\(jobViewModel.myJobPostings.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("등록 공고")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                // 총 지원자 카드
                VStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("\(jobViewModel.totalApplications)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("총 지원자")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                // 평균 지원 카드
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text(String(format: "%.1f", jobViewModel.averageApplicationsPerJob))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("평균 지원")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
            
            // 로딩 상태 표시
            if jobViewModel.isLoadingApplicationCounts {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("지원자 수 집계 중...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - 최근 채용공고 섹션
struct CompanyRecentJobsSection: View {
    @ObservedObject var jobViewModel: CompanyJobViewModel
    
    var recentJobs: [JobPostingResponse] {
        return Array(jobViewModel.myJobPostings.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("최근 등록한 채용공고")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !jobViewModel.myJobPostings.isEmpty {
                    NavigationLink(destination: CompanyJobManagementView()) {
                        Text("전체보기")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if recentJobs.isEmpty {
                EmptyRecentJobsView()
            } else {
                VStack(spacing: 12) {
                    ForEach(recentJobs) { job in
                        NavigationLink(destination: CompanyJobDetailView(job: job, viewModel: jobViewModel)) {
                            CompanyRecentJobRow(
                                job: job,
                                applicationCount: jobViewModel.getApplicationCount(for: job.id)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

struct CompanyRecentJobRow: View {
    let job: JobPostingResponse
    let applicationCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(job.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                HStack {
                    Label(job.location, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("\(applicationCount)명 지원", systemImage: "person.3.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .cornerRadius(8)
    }
}

struct EmptyRecentJobsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "briefcase.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("등록된 채용공고가 없습니다")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("첫 번째 채용공고를 등록해보세요!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - AI 매칭 프로모션
struct CompanyAIMatchingPromotion: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("🤖 AI 인재 매칭")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("채용공고에 가장 적합한 인재를\nAI가 찾아드립니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)
            }
            
            NavigationLink(destination: CompanyResumeMatchingView()) {
                HStack {
                    Text("AI 매칭 시작하기")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.purple, .blue]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - 팁 섹션
struct CompanyTipsSection: View {
    private let tips = [
        CompanyTip(
            icon: "lightbulb.fill",
            title: "효과적인 채용공고 작성법",
            description: "구체적인 업무 내용과 요구 기술을 명시하세요",
            color: .yellow
        ),
        CompanyTip(
            icon: "person.crop.circle.badge.checkmark",
            title: "우수한 인재 발굴하기",
            description: "AI 매칭을 활용해 숨겨진 우수 인재를 찾아보세요",
            color: .green
        ),
        CompanyTip(
            icon: "chart.line.uptrend.xyaxis",
            title: "채용 성과 분석하기",
            description: "지원자 수와 매칭률을 분석하여 채용 전략을 개선하세요",
            color: .blue
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("💡 채용 팁")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(tips, id: \.title) { tip in
                    CompanyTipRow(tip: tip)
                }
            }
        }
    }
}

struct CompanyTip {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct CompanyTipRow: View {
    let tip: CompanyTip
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tip.icon)
                .font(.system(size: 20))
                .foregroundColor(tip.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(tip.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(12)
        .background(tip.color.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(tip.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 지원자 대시보드 뷰
struct CompanyApplicationDashboardView: View {
    @StateObject private var jobViewModel = CompanyJobViewModel()
    @State private var selectedJob: JobPostingResponse?
    @State private var showingApplicationManagement = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 헤더
                CompanyApplicationDashboardHeader()
                    .padding()
                    .background(AppTheme.secondaryBackground)
                
                if jobViewModel.myJobPostings.isEmpty {
                    EmptyJobPostingsForApplicationsView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 전체 통계
                            CompanyApplicationOverallStats(jobViewModel: jobViewModel)
                                .padding(.horizontal)
                            
                            // 채용공고별 지원자 수
                            CompanyApplicationsByJobSection(
                                jobViewModel: jobViewModel,
                                onJobSelected: { job in
                                    selectedJob = job
                                    showingApplicationManagement = true
                                }
                            )
                            .padding(.horizontal)
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("지원자 관리")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                jobViewModel.refresh()
            }
        }
        .onAppear {
            jobViewModel.loadMyJobPostings()
        }
        .sheet(isPresented: $showingApplicationManagement) {
            if let job = selectedJob {
                CompanyApplicationManagementView(job: job)
            }
        }
    }
}

struct CompanyApplicationDashboardHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("지원자 관리")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("채용공고별 지원자를 확인하고 관리하세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
}

struct CompanyApplicationOverallStats: View {
    @ObservedObject var jobViewModel: CompanyJobViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("전체 현황")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                OverallStatCard(
                    icon: "briefcase.fill",
                    title: "활성 공고",
                    value: "\(jobViewModel.myJobPostings.count)",
                    color: .blue
                )
                
                OverallStatCard(
                    icon: "person.3.fill",
                    title: "총 지원자",
                    value: jobViewModel.isLoadingApplicationCounts ? "..." : "\(jobViewModel.totalApplications)",
                    color: .green
                )
                
                OverallStatCard(
                    icon: "chart.bar.fill",
                    title: "평균 지원",
                    value: jobViewModel.isLoadingApplicationCounts ? "..." : String(format: "%.1f", jobViewModel.averageApplicationsPerJob),
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct OverallStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CompanyApplicationsByJobSection: View {
    @ObservedObject var jobViewModel: CompanyJobViewModel
    let onJobSelected: (JobPostingResponse) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("채용공고별 지원자")
                .font(.headline)
                .fontWeight(.bold)
            
            if jobViewModel.isLoadingApplicationCounts {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("지원자 수 집계 중...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(jobViewModel.myJobPostings) { job in
                        ApplicationJobRow(
                            job: job,
                            applicationCount: jobViewModel.getApplicationCount(for: job.id),
                            onTapped: { onJobSelected(job) }
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct ApplicationJobRow: View {
    let job: JobPostingResponse
    let applicationCount: Int
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(job.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Label(job.location, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("등록: \(job.createdAt.toShortDate())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(applicationCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(applicationCount > 0 ? .green : .gray)
                    
                    Text("지원자")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text("관리")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(16)
            .background(
                applicationCount > 0 ?
                Color.green.opacity(0.05) :
                Color.gray.opacity(0.05)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        applicationCount > 0 ?
                        Color.green.opacity(0.2) :
                        Color.gray.opacity(0.2),
                        lineWidth: 1
                    )
            )
        }
    }
}

struct EmptyJobPostingsForApplicationsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("등록된 채용공고가 없습니다")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("지원자를 관리하려면\n먼저 채용공고를 등록해주세요")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            
            NavigationLink(destination: CreateJobPostingView(viewModel: CompanyJobViewModel())) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    
                    Text("첫 채용공고 등록하기")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [AppTheme.primary, AppTheme.primary.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 기업 프로필 뷰
struct CompanyProfileView: View {
    @AppStorage("userName") private var userName = ""
    @AppStorage("userEmail") private var userEmail = ""
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // 프로필 헤더
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary)
                                .frame(width: 60, height: 60)
                            
                            Text(String(userName.prefix(1)))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userName)
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            Text(userEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("기업 회원")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppTheme.primary.opacity(0.2))
                                .foregroundColor(AppTheme.primary)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // 기업 정보
                Section("기업 정보") {
                    ProfileMenuItem(
                        icon: "building.2.fill",
                        title: "회사 정보 수정",
                        action: {
                            // TODO: 회사 정보 수정
                        }
                    )
                    
                    ProfileMenuItem(
                        icon: "person.badge.key.fill",
                        title: "계정 설정",
                        action: {
                            // TODO: 계정 설정
                        }
                    )
                }
                
                // 채용 관리
                Section("채용 관리") {
                    ProfileMenuItem(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "채용 통계",
                        action: {
                            // TODO: 채용 통계
                        }
                    )
                    
                    ProfileMenuItem(
                        icon: "bell.fill",
                        title: "알림 설정",
                        action: {
                            // TODO: 알림 설정
                        }
                    )
                }
                
                // 고객 지원
                Section("고객 지원") {
                    ProfileMenuItem(
                        icon: "questionmark.circle.fill",
                        title: "도움말",
                        action: {
                            // TODO: 도움말
                        }
                    )
                    
                    ProfileMenuItem(
                        icon: "envelope.fill",
                        title: "문의하기",
                        action: {
                            // TODO: 문의하기
                        }
                    )
                }
                
                // 로그아웃
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            
                            Text("로그아웃")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("프로필")
            .alert("로그아웃", isPresented: $showingLogoutAlert) {
                Button("취소", role: .cancel) { }
                Button("로그아웃", role: .destructive) {
                    logout()
                }
            } message: {
                Text("정말 로그아웃하시겠습니까?")
            }
        }
    }
    
    private func logout() {
        APIService.shared.logout()
        // TODO: 로그인 화면으로 돌아가기
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.primary)
                    .frame(width: 20)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 온보딩 뷰
struct CompanyOnboardingView: View {
    @Binding var isPresented: Bool
    @AppStorage("companyOnboardingCompleted") private var onboardingCompleted = false
    @State private var currentPage = 0
    
    private let pages = [
        OnboardingPage(
            icon: "building.2.fill",
            title: "기업 회원으로 환영합니다!",
            description: "JobBridge에서 최고의 인재를 찾아보세요.\n효율적인 채용 관리가 시작됩니다.",
            color: .blue
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "AI 인재 매칭",
            description: "인공지능이 분석하여\n채용공고에 가장 적합한 인재를 추천해드립니다.",
            color: .purple
        ),
        OnboardingPage(
            icon: "person.3.fill",
            title: "통합 지원자 관리",
            description: "모든 지원자를 한 곳에서 관리하고\n효율적으로 채용 프로세스를 진행하세요.",
            color: .green
        )
    ]
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // 페이지 인디케이터
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? pages[currentPage].color : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical)
            
            // 버튼들
            VStack(spacing: 16) {
                if currentPage < pages.count - 1 {
                    Button("다음") {
                        withAnimation {
                            currentPage += 1
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pages[currentPage].color)
                    .cornerRadius(12)
                } else {
                    Button("시작하기") {
                        onboardingCompleted = true
                        isPresented = false
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pages[currentPage].color)
                    .cornerRadius(12)
                }
                
                Button("건너뛰기") {
                    onboardingCompleted = true
                    isPresented = false
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundColor(page.color)
            }
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}
