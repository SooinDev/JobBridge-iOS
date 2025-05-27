// CompanyResumeMatchingView.swift - 완성된 기업용 AI 이력서 매칭 메인 화면
import SwiftUI

struct CompanyResumeMatchingView: View {
    @StateObject private var viewModel = CompanyResumeMatchingViewModel()
    @State private var selectedJobPosting: JobPostingResponse?
    @State private var showingJobSelector = false
    @State private var showingAllMatches = false
    @State private var currentStep: MatchingStep = .selectJob
    
    enum MatchingStep {
        case selectJob
        case matching
        case results
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더
                    CompanyMatchingHeaderView()
                        .padding(.horizontal)
                    
                    // 메인 컨텐츠
                    VStack(spacing: 20) {
                        // 1. 채용공고 선택 카드
                        JobSelectionCard(
                            jobPostings: viewModel.myJobPostings,
                            selectedJob: selectedJobPosting,
                            onSelectJob: {
                                showingJobSelector = true
                            }
                        )
                        .padding(.horizontal)
                        
                        // 2. AI 매칭 실행 카드
                        if selectedJobPosting != nil {
                            AIMatchingActionCard(
                                job: selectedJobPosting!,
                                isLoading: viewModel.isMatchingInProgress,
                                onStartMatching: {
                                    startMatching()
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        // 3. 매칭 결과 섹션
                        if viewModel.hasMatchingResults {
                            MatchedResumesSection(
                                resumes: viewModel.matchedResumes,
                                selectedJob: selectedJobPosting,
                                onViewAllMatches: {
                                    showingAllMatches = true
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        // 에러 표시
                        if let errorMessage = viewModel.errorMessage {
                            ErrorMessageCard(
                                message: errorMessage,
                                retryAction: {
                                    if let job = selectedJobPosting {
                                        viewModel.startResumeMatching(for: job)
                                    }
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        // 빈 상태 가이드
                        if !viewModel.hasJobPostings {
                            EmptyJobPostingsView()
                                .padding(.horizontal)
                        } else if selectedJobPosting == nil {
                            // 가이드 카드는 채용공고가 있지만 선택하지 않은 경우에만 표시
                            AIMatchingGuideCard()
                                .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("AI 인재 매칭")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.loadJobPostings()
        }
        .sheet(isPresented: $showingJobSelector) {
            JobSelectorSheet(
                jobPostings: viewModel.myJobPostings,
                selectedJob: $selectedJobPosting
            )
        }
        .sheet(isPresented: $showingAllMatches) {
            if let job = selectedJobPosting, !viewModel.matchedResumes.isEmpty {
                AllMatchedResumesView(
                    resumes: viewModel.matchedResumes,
                    jobPosting: job
                )
            }
        }
    }
    
    private func startMatching() {
        guard let job = selectedJobPosting else { return }
        currentStep = .matching
        viewModel.startResumeMatching(for: job)
        
        // 매칭 완료 후 결과 단계로 전환
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if viewModel.hasMatchingResults {
                currentStep = .results
            }
        }
    }
}

// MARK: - 채용공고 선택 시트
struct JobSelectorSheet: View {
    let jobPostings: [JobPostingResponse]
    @Binding var selectedJob: JobPostingResponse?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(jobPostings) { job in
                    Button(action: {
                        selectedJob = job
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(job.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            Text(job.position)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Label(job.location, systemImage: "location.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Text("등록: \(job.createdAt.toShortDate())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if selectedJob?.id == job.id {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("채용공고 선택")
            .navigationBarItems(
                leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - 헤더 뷰
struct CompanyMatchingHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // AI 아이콘
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("AI 인재 매칭")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("채용공고와 가장 적합한 인재를 찾아드려요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // 기능 소개
            HStack(spacing: 20) {
                FeatureBadge(
                    icon: "brain.head.profile",
                    text: "AI 분석",
                    color: .purple
                )
                
                FeatureBadge(
                    icon: "target",
                    text: "정확한 매칭",
                    color: .blue
                )
                
                FeatureBadge(
                    icon: "clock.fill",
                    text: "빠른 추천",
                    color: .green
                )
                
                Spacer()
            }
        }
    }
}

struct FeatureBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 채용공고 선택 카드
struct JobSelectionCard: View {
    let jobPostings: [JobPostingResponse]
    let selectedJob: JobPostingResponse?
    let onSelectJob: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("1️⃣ 채용공고 선택")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if jobPostings.isEmpty {
                    Text("공고 없음")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Text("\(jobPostings.count)개 공고")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if let job = selectedJob {
                // 선택된 공고 표시
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(job.title)
                                .font(.body)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                            
                            Text(job.position)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        InfoChip(icon: "location.fill", text: job.location, color: .blue)
                        InfoChip(icon: "briefcase.fill", text: job.experienceLevel, color: .purple)
                        
                        Spacer()
                        
                        Button("변경") {
                            onSelectJob()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(
                    colorScheme == .dark ?
                    Color.green.opacity(0.15) :
                    Color.green.opacity(0.05)
                )
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            } else {
                // 선택 버튼
                Button(action: onSelectJob) {
                    HStack(spacing: 16) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("채용공고 선택하기")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("매칭을 진행할 채용공고를 선택하세요")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        colorScheme == .dark ?
                        Color.blue.opacity(0.15) :
                        Color.blue.opacity(0.05)
                    )
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }
                .disabled(jobPostings.isEmpty)
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - AI 매칭 실행 카드
struct AIMatchingActionCard: View {
    let job: JobPostingResponse
    let isLoading: Bool
    let onStartMatching: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("2️⃣ AI 매칭 실행")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                Text("🤖 AI가 분석합니다")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("선택한 채용공고의 요구사항과\n가장 적합한 이력서를 찾아드립니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                // 매칭 단계 표시
                VStack(spacing: 12) {
                    MatchingStepRow(
                        icon: "doc.text.magnifyingglass",
                        text: "이력서 분석",
                        isActive: isLoading
                    )
                    
                    MatchingStepRow(
                        icon: "brain.head.profile",
                        text: "AI 유사도 계산",
                        isActive: isLoading
                    )
                    
                    MatchingStepRow(
                        icon: "list.number",
                        text: "순위별 정렬",
                        isActive: isLoading
                    )
                }
                .padding(.vertical, 8)
                
                Button(action: onStartMatching) {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.9)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text("AI가 분석 중...")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("매칭 시작하기")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .purple,
                                .blue
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.purple.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .disabled(isLoading)
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct MatchingStepRow: View {
    let icon: String
    let text: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.purple.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isActive ? .purple : .gray)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(isActive ? .primary : .secondary)
            
            Spacer()
            
            if isActive {
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: .purple))
            }
        }
    }
}

// MARK: - 매칭 결과 섹션
struct MatchedResumesSection: View {
    let resumes: [ResumeMatchResponse]
    let selectedJob: JobPostingResponse?
    let onViewAllMatches: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("3️⃣ 추천 결과")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("🎯 \(resumes.count)명의 적합한 인재를 찾았습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if resumes.count > 3 {
                    Button("전체보기") {
                        onViewAllMatches()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // 상위 3명 미리보기
            VStack(spacing: 16) {
                ForEach(Array(resumes.prefix(3).enumerated()), id: \.element.id) { index, resume in
                    NavigationLink(
                        destination: CompanyResumeDetailView(
                            resume: CompanyMatchingResumeResponse(
                                id: resume.id,
                                title: resume.title,
                                content: resume.content,
                                userName: resume.userName,
                                createdAt: resume.createdAt,
                                updatedAt: resume.updatedAt,
                                matchRate: resume.matchRate
                            ),
                            jobPosting: selectedJob ?? JobPostingResponse(
                                id: 0, title: "", description: "", position: "",
                                requiredSkills: "", experienceLevel: "", location: "",
                                salary: "", deadline: nil, companyName: nil,
                                companyEmail: nil, createdAt: ""
                            )
                        )
                    ) {
                        MatchedResumeRow(resume: resume, rank: index + 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if resumes.count > 3 {
                Button(action: onViewAllMatches) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        
                        Text("추가 \(resumes.count - 3)명 더 보기")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(.blue)
                    }
                    .padding(16)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
                }
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 매칭된 이력서 행
struct MatchedResumeRow: View {
    let resume: ResumeMatchResponse
    let rank: Int
    @Environment(\.colorScheme) var colorScheme
    
    private var rankColor: Color {
        switch rank {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .purple
        }
    }
    
    private var matchRateColor: Color {
        if resume.matchRate >= 0.8 { return .green }
        else if resume.matchRate >= 0.6 { return .orange }
        else { return .red }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "star.fill"
        default: return "trophy.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 순위 배지
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 44, height: 44)
                
                VStack(spacing: 2) {
                    Image(systemName: rankIcon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("\(rank)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // 이력서 정보
            VStack(alignment: .leading, spacing: 6) {
                Text(resume.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(resume.userName)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                HStack(spacing: 12) {
                    Text("작성일: \(resume.formattedCreatedDate)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let skills = extractSkills(from: resume.content) {
                        Text("• \(skills)")
                            .font(.caption2)
                            .foregroundColor(.purple)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // 매칭률
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(matchRateColor)
                    
                    Text("\(resume.matchRatePercentage)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(matchRateColor)
                }
                
                Text(resume.matchRateDescription)
                    .font(.caption2)
                    .foregroundColor(matchRateColor)
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    
                    Text("상세보기")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(
            colorScheme == .dark ?
            Color(UIColor.tertiarySystemBackground) :
            Color.white
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            rankColor.opacity(0.4),
                            matchRateColor.opacity(0.4)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: rankColor.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func extractSkills(from content: String) -> String? {
        let keywords = ["Swift", "iOS", "Android", "React", "Python", "Java", "JavaScript", "SwiftUI", "UIKit"]
        let foundKeywords = keywords.filter { content.contains($0) }
        return foundKeywords.isEmpty ? nil : foundKeywords.prefix(2).joined(separator: ", ")
    }
}

// MARK: - 빈 상태 뷰
struct EmptyJobPostingsView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "briefcase.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("등록된 채용공고가 없습니다")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("AI 인재 매칭을 사용하려면\n먼저 채용공고를 등록해주세요")
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineSpacing(4)
            }
            
            NavigationLink(destination: CreateJobPostingView(viewModel: CompanyJobViewModel())) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    
                    Text("채용공고 등록하기")
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

// MARK: - 오류 메시지 카드
struct ErrorMessageCard: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("매칭 중 오류가 발생했습니다")
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            
            Button("다시 시도") {
                retryAction()
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.orange)
            .cornerRadius(20)
            .shadow(color: Color.orange.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .padding(24)
        .background(Color.orange.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - AI 매칭 가이드 카드
struct AIMatchingGuideCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("💡 AI 매칭 가이드")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                GuideRow(
                    icon: "1.circle.fill",
                    tip: "채용공고의 필요 기술과 경험을 구체적으로 작성하세요",
                    color: .blue
                )
                
                GuideRow(
                    icon: "2.circle.fill",
                    tip: "AI가 분석하여 가장 적합한 인재를 추천해드립니다",
                    color: .purple
                )
                
                GuideRow(
                    icon: "3.circle.fill",
                    tip: "매칭률이 높은 이력서부터 우선 검토해보세요",
                    color: .green
                )
                
                GuideRow(
                    icon: "4.circle.fill",
                    tip: "연락처 정보를 통해 직접 컨택이 가능합니다",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(Color.yellow.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

struct GuideRow: View {
    let icon: String
    let tip: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(tip)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
    }
}

// MARK: - 보조 컴포넌트
struct InfoChip: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
