// HomeView.swift - 수정된 버전 (ResumeSelectionCard 문제 해결)
import SwiftUI

struct HomeView: View {
    @ObservedObject var jobViewModel: JobViewModel
    @ObservedObject var resumeViewModel: ResumeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isLoading = false
    @State private var searchText = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 환영 헤더
                WelcomeHeaderView()
                
                // 빠른 액션 버튼들
                QuickActionsView()
                
                // 내 이력서 섹션
                MyResumesSection(viewModel: resumeViewModel)
                
                // 최근 채용공고 섹션
                RecentJobsSection(jobViewModel: jobViewModel)
                
                // 추천 채용공고 섹션 (AI 매칭)
                ImprovedRecommendedJobsSection(jobViewModel: jobViewModel, resumeViewModel: resumeViewModel)
            }
            .padding()
        }
        .navigationTitle("홈")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isLoading = true
            
            Task {
                // 데이터 로드
                await withTaskGroup(of: Void.self) { group in
                    group.addTask {
                        if resumeViewModel.resumes.isEmpty {
                            await resumeViewModel.loadResumes()
                        }
                    }
                    
                    group.addTask {
                        if jobViewModel.jobs.isEmpty {
                            await jobViewModel.loadRecentJobs()
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

struct QuickActionsView: View {
    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "doc.text.fill",
                title: "이력서 작성",
                destination: AnyView(ResumesView(viewModel: ResumeViewModel()))
            )

            QuickActionButton(
                icon: "magnifyingglass",
                title: "채용공고 검색",
                destination: AnyView(JobsView(viewModel: JobViewModel()))
            )
        }
    }
}

// MARK: - WelcomeHeaderView
struct WelcomeHeaderView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("안녕하세요!")
                .heading2()
            
            Text("\(authViewModel.currentUser?.name ?? "사용자")님")
                .heading1()
                .foregroundColor(AppTheme.primary)
            
            Text("오늘도 좋은 기회를 찾아보세요!")
                .body2()
        }
        .padding(.vertical, 8)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let destination: AnyView

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
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundColor(AppTheme.textPrimary)
    }
}

// MARK: - MyResumesSection
struct MyResumesSection: View {
    @ObservedObject var viewModel: ResumeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("내 이력서")
                    .heading3()
                
                Spacer()
                
                NavigationLink(destination: ResumesView(viewModel: viewModel)) {
                    Text("모두 보기")
                        .caption()
                        .foregroundColor(AppTheme.primary)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if viewModel.resumes.isEmpty {
                EmptyStateView(
                    icon: "doc.text.badge.plus",
                    title: "이력서가 없습니다",
                    message: "첫 번째 이력서를 작성해보세요.",
                    buttonTitle: "이력서 작성하기",
                    buttonAction: nil
                )
                .frame(height: 150)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.resumes.prefix(2)) { resume in
                        NavigationLink(destination: ResumeDetailView(resume: resume)) {
                            HomeResumeRow(resume: resume)
                        }
                        .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
        }
        .onAppear {
            if viewModel.resumes.isEmpty {
                viewModel.loadResumes()
            }
        }
    }
}

// MARK: - RecentJobsSection
struct RecentJobsSection: View {
    @ObservedObject var jobViewModel: JobViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("최신 채용공고")
                    .heading3()
                
                Spacer()
                
                NavigationLink(destination: JobsView(viewModel: jobViewModel)) {
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
                    title: "채용공고가 없습니다",
                    message: "새로운 채용공고를 기다려주세요.",
                    buttonTitle: nil,
                    buttonAction: nil
                )
                .frame(height: 150)
            } else {
                VStack(spacing: 8) {
                    ForEach(jobViewModel.jobs.prefix(3)) { job in
                        NavigationLink(destination: JobDetailView(job: job)) {
                            HomeJobRow(job: job)
                        }
                        .foregroundColor(AppTheme.textPrimary)
                    }
                }
            }
        }
        .onAppear {
            if jobViewModel.jobs.isEmpty {
                jobViewModel.loadRecentJobs()
            }
        }
    }
}

// MARK: - 🔥 개선된 RecommendedJobsSection
struct ImprovedRecommendedJobsSection: View {
    @ObservedObject var jobViewModel: JobViewModel
    @ObservedObject var resumeViewModel: ResumeViewModel
    @State private var selectedResumeId: Int?
    @State private var showingResumeSelector = false
    @State private var showingAllRecommendations = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI 추천 채용공고")
                    .heading3()
                
                Spacer()
                
                if !jobViewModel.matchingJobs.isEmpty {
                    Button("새로고침") {
                        if let resumeId = selectedResumeId {
                            loadRecommendations(for: resumeId)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(AppTheme.primary)
                }
            }
            
            if resumeViewModel.resumes.isEmpty {
                EmptyStateView(
                    icon: "sparkles",
                    title: "AI 추천을 위해 이력서가 필요합니다",
                    message: "이력서를 작성하고 맞춤 추천을 받아보세요.",
                    buttonTitle: "이력서 작성하기",
                    buttonAction: {
                        // 이력서 작성 화면으로 이동하는 로직 추가 가능
                    }
                )
                .frame(height: 120)
            } else {
                VStack(spacing: 12) {
                    // 이력서 선택 카드 - 수정된 매개변수 타입
                    HomeResumeSelectionCard(
                        resumes: resumeViewModel.resumes,
                        selectedResumeId: $selectedResumeId,
                        onSelectionChanged: { resumeId in
                            loadRecommendations(for: resumeId)
                        }
                    )
                    
                    // AI 추천 결과
                    if jobViewModel.isLoading {
                        AILoadingView()
                    } else if let errorMessage = jobViewModel.errorMessage {
                        AIErrorView(message: errorMessage) {
                            if let resumeId = selectedResumeId {
                                loadRecommendations(for: resumeId)
                            }
                        }
                    } else if jobViewModel.matchingJobs.isEmpty {
                        AIEmptyStateView {
                            if let resumeId = selectedResumeId {
                                loadRecommendations(for: resumeId)
                            }
                        }
                    } else {
                        VStack(spacing: 8) {
                            // 매칭 통계
                            AIMatchingStatsView(jobs: jobViewModel.matchingJobs)
                            
                            // 추천 결과 (상위 2개)
                            ForEach(jobViewModel.matchingJobs.prefix(2)) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    HomeMatchingJobRow(job: job)
                                }
                                .foregroundColor(AppTheme.textPrimary)
                            }
                            
                            // 더보기 버튼
                            if jobViewModel.matchingJobs.count > 2 {
                                Button(action: {
                                    showingAllRecommendations = true
                                }) {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("모든 추천 공고 보기")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(AppTheme.primary)
                                            
                                            Text("\(jobViewModel.matchingJobs.count)개의 맞춤 채용공고")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(AppTheme.primary)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                AppTheme.primary.opacity(0.08),
                                                AppTheme.primary.opacity(0.12)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                                    )
                                }
                                .contentShape(Rectangle())
                                .scaleEffect(showingAllRecommendations ? 0.98 : 1.0)
                                .animation(.spring(response: 0.3), value: showingAllRecommendations)
                                .padding(.top, 8)
                                .background(
                                    NavigationLink(
                                        destination: AllRecommendationsView(
                                            jobs: jobViewModel.matchingJobs,
                                            resumeTitle: getSelectedResumeTitle()
                                        ),
                                        isActive: $showingAllRecommendations
                                    ) {
                                        EmptyView()
                                    }
                                    .opacity(0)
                                )
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // 초기 이력서 선택 (최신 이력서 우선)
            if selectedResumeId == nil && !resumeViewModel.resumes.isEmpty {
                selectedResumeId = getMostRecentResume()?.id
            }
        }
    }
    
    private func loadRecommendations(for resumeId: Int) {
        print("🤖 AI 추천 시작 - 이력서 ID: \(resumeId)")
        jobViewModel.loadMatchingJobs(resumeId: resumeId)
    }
    
    private func getMostRecentResume() -> ResumeResponse? {
        return resumeViewModel.resumes.max(by: { resume1, resume2 in
            // createdAt 문자열을 날짜로 변환해서 비교
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            
            let date1 = formatter.date(from: resume1.createdAt) ?? Date.distantPast
            let date2 = formatter.date(from: resume2.createdAt) ?? Date.distantPast
            
            return date1 < date2
        })
    }
    
    private func getSelectedResumeTitle() -> String {
        guard let selectedId = selectedResumeId,
              let selectedResume = resumeViewModel.resumes.first(where: { $0.id == selectedId }) else {
            return "내 이력서"
        }
        return selectedResume.title
    }
}

// MARK: - Home용 이력서 선택 카드 (이름 변경으로 중복 해결)
struct HomeResumeSelectionCard: View {
    let resumes: [ResumeResponse]
    @Binding var selectedResumeId: Int?
    let onSelectionChanged: (Int) -> Void
    @State private var showingPicker = false
    
    private var selectedResume: ResumeResponse? {
        guard let id = selectedResumeId else { return nil }
        return resumes.first { $0.id == id }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("분석할 이력서 선택")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("변경") {
                    showingPicker = true
                }
                .font(.caption)
                .foregroundColor(AppTheme.primary)
            }
            
            if let resume = selectedResume {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resume.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text("작성일: \(resume.createdAt.toShortDate())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.05))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            } else {
                Button("이력서 선택하기") {
                    showingPicker = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.primary.opacity(0.1))
                .foregroundColor(AppTheme.primary)
                .cornerRadius(8)
            }
        }
        .actionSheet(isPresented: $showingPicker) {
            ActionSheet(
                title: Text("AI 분석할 이력서를 선택하세요"),
                message: Text("선택한 이력서를 기준으로 맞춤 채용공고를 추천해드립니다"),
                buttons: createActionSheetButtons()
            )
        }
    }
    
    private func createActionSheetButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = resumes.map { resume in
            .default(Text("\(resume.title) (\(resume.createdAt.toShortDate()))")) {
                selectedResumeId = resume.id
                onSelectionChanged(resume.id)
            }
        }
        buttons.append(.cancel(Text("취소")))
        return buttons
    }
}

// MARK: - AI 관련 뷰 컴포넌트들
struct AILoadingView: View {
    @State private var animationOffset: CGFloat = -50
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // 애니메이션 로딩 인디케이터
                ZStack {
                    Circle()
                        .stroke(Color.purple.opacity(0.3), lineWidth: 3)
                        .frame(width: 30, height: 30)
                    
                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(Color.purple, lineWidth: 3)
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(animationOffset))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: animationOffset)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("🤖 AI가 분석 중...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("이력서와 가장 잘 맞는 채용공고를 찾고 있습니다")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.purple.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
            )
        }
        .onAppear {
            animationOffset = 360
        }
    }
}

struct AIErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI 추천 오류")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button("재시도") {
                    retryAction()
                }
                .font(.caption)
                .foregroundColor(.orange)
            }
            .padding()
            .background(Color.orange.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct AIEmptyStateView: View {
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: retryAction) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🤖 AI 추천 받기")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.purple)
                        
                        Text("선택한 이력서를 분석해서 맞춤 공고를 찾아드려요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.purple)
                }
                .padding()
                .background(Color.purple.opacity(0.05))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
}

struct AIMatchingStatsView: View {
    let jobs: [JobPostingResponse]
    
    private var averageMatchRate: Double {
        let rates = jobs.compactMap { $0.matchRate }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }
    
    private var topMatchRate: Double {
        jobs.compactMap { $0.matchRate }.max() ?? 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("\(jobs.count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Text("추천 공고")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("\(Int(averageMatchRate * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text("평균 일치도")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("\(Int(topMatchRate * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                
                Text("최고 일치도")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.05),
                    Color.blue.opacity(0.05)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Home Row Components

struct HomeResumeRow: View {
    let resume: ResumeResponse
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(resume.title)
                    .body1()
                    .lineLimit(1)
                
                Text("작성일: \(resume.createdAt.toShortDate())")
                    .caption()
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct HomeJobRow: View {
    let job: JobPostingResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(job.title)
                .body1()
                .lineLimit(2)
            
            HStack {
                Text(job.companyName ?? "기업명 없음")
                    .caption()
                    .foregroundColor(AppTheme.primary)
                
                Spacer()
                
                Text(job.createdAt.toShortDate())
                    .caption()
                    .foregroundColor(AppTheme.textTertiary)
            }
            
            HStack {
                InfoTag(icon: "location", text: job.location)
                InfoTag(icon: "briefcase", text: job.experienceLevel)
                
                Spacer()
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct HomeMatchingJobRow: View {
    let job: JobPostingResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(job.title)
                    .body1()
                    .lineLimit(2)
                
                Spacer()
                
                if let matchRate = job.matchRate {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                        
                        Text("\(Int(matchRate * 100))%")
                            .caption()
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            HStack {
                Text(job.companyName ?? "기업명 없음")
                    .caption()
                    .foregroundColor(AppTheme.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    
                    Text("AI 추천")
                        .caption()
                }
                .foregroundColor(.purple)
            }
        }
        .padding()
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
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Extensions for async loading

extension ResumeViewModel {
    func loadResumes() async {
        // 기존의 loadResumes() 메서드를 async 버전으로 래핑
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.loadResumes()
                // loadResumes가 완료되면 continuation을 resume
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    continuation.resume()
                }
            }
        }
    }
}

extension JobViewModel {
    func loadRecentJobs() async {
        // 기존의 loadRecentJobs() 메서드를 async 버전으로 래핑
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.loadRecentJobs()
                // loadRecentJobs가 완료되면 continuation을 resume
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    continuation.resume()
                }
            }
        }
    }
}
