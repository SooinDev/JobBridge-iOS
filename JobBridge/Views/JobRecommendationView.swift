// JobRecommendationView.swift - 수정된 개인회원용 AI 채용공고 추천 파일 (오류 수정)
import SwiftUI

struct JobRecommendationView: View {
    @StateObject private var viewModel = JobRecommendationViewModel()
    @State private var selectedResume: ResumeResponse?
    @State private var showingResumeSelector = false
    @State private var showingAllRecommendations = false
    @State private var currentStep: RecommendationStep = .selectResume
    
    enum RecommendationStep {
        case selectResume
        case recommending
        case results
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더
                    JobRecommendationHeaderView()
                        .padding(.horizontal)
                    
                    // 메인 컨텐츠
                    VStack(spacing: 20) {
                        // 1. 이력서 선택 카드
                        JobRecommendationResumeSelectionCard(
                            resumes: viewModel.myResumes,
                            selectedResume: selectedResume,
                            onSelectResume: {
                                showingResumeSelector = true
                            }
                        )
                        .padding(.horizontal)
                        
                        // 2. AI 추천 실행 카드
                        if selectedResume != nil {
                            AIRecommendationActionCard(
                                resume: selectedResume!,
                                isLoading: viewModel.isRecommendationInProgress,
                                onStartRecommendation: {
                                    startRecommendation()
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        // 3. 추천 결과 섹션
                        if viewModel.hasRecommendationResults {
                            RecommendedJobsSection(
                                jobs: viewModel.recommendedJobs,
                                selectedResume: selectedResume,
                                onViewAllRecommendations: {
                                    showingAllRecommendations = true
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        // 에러 표시
                        if let errorMessage = viewModel.errorMessage {
                            JobRecommendationErrorCard(
                                message: errorMessage,
                                retryAction: {
                                    if let resume = selectedResume {
                                        viewModel.startJobRecommendation(for: resume)
                                    }
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        // 빈 상태 가이드
                        if !viewModel.hasResumes {
                            JobRecommendationEmptyResumesView()
                                .padding(.horizontal)
                        } else if selectedResume == nil {
                            AIRecommendationGuideCard()
                                .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("AI 채용공고 추천")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refresh()
            }
        }
        .onAppear {
            viewModel.loadMyResumes()
        }
        .sheet(isPresented: $showingResumeSelector) {
            ResumeSelectorSheet(
                resumes: viewModel.myResumes,
                selectedResume: $selectedResume
            )
        }
        .sheet(isPresented: $showingAllRecommendations) {
            if let resume = selectedResume, !viewModel.recommendedJobs.isEmpty {
                AllRecommendedJobsView(
                    jobs: viewModel.recommendedJobs,
                    resume: resume
                )
            }
        }
    }
    
    private func startRecommendation() {
        guard let resume = selectedResume else { return }
        currentStep = .recommending
        viewModel.startJobRecommendation(for: resume)
        
        // 추천 완료 후 결과 단계로 전환
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if viewModel.hasRecommendationResults {
                currentStep = .results
            }
        }
    }
}

// MARK: - 이력서 선택 시트
struct ResumeSelectorSheet: View {
    let resumes: [ResumeResponse]
    @Binding var selectedResume: ResumeResponse?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(resumes) { resume in
                    Button(action: {
                        selectedResume = resume
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(resume.title)
                                .font(.headline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                            
                            Text(resume.content.prefix(100) + "...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            
                            HStack {
                                // 기존 DateFormatter.swift의 toShortDate() 사용
                                Text("작성: \(resume.createdAt.toShortDate())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("수정: \(resume.updatedAt.toShortDate())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if selectedResume?.id == resume.id {
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
            .navigationTitle("이력서 선택")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// MARK: - 헤더 뷰
struct JobRecommendationHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // AI 아이콘
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .green],
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
                    Text("AI 채용공고 추천")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("당신의 이력서와 가장 적합한 채용공고를 찾아드려요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // 기능 소개
            HStack(spacing: 20) {
                JobRecommendationFeatureBadge(
                    icon: "brain.head.profile",
                    text: "AI 분석",
                    color: .blue
                )
                
                JobRecommendationFeatureBadge(
                    icon: "target",
                    text: "정확한 매칭",
                    color: .green
                )
                
                JobRecommendationFeatureBadge(
                    icon: "clock.fill",
                    text: "빠른 추천",
                    color: .orange
                )
                
                Spacer()
            }
        }
    }
}

// MARK: - 기능 배지
struct JobRecommendationFeatureBadge: View {
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

// MARK: - JobRecommendation용 이력서 선택 카드
struct JobRecommendationResumeSelectionCard: View {
    let resumes: [ResumeResponse]
    let selectedResume: ResumeResponse?
    let onSelectResume: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("1️⃣ 이력서 선택")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if resumes.isEmpty {
                    Text("이력서 없음")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Text("\(resumes.count)개 이력서")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            if let resume = selectedResume {
                // 선택된 이력서 표시
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(resume.title)
                                .font(.body)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                            
                            Text(resume.content.prefix(80) + "...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                    
                    HStack {
                        JobRecommendationInfoChip(icon: "calendar", text: "작성: \(resume.createdAt.toShortDate())", color: .blue)
                        JobRecommendationInfoChip(icon: "pencil", text: "수정: \(resume.updatedAt.toShortDate())", color: .purple)
                        
                        Spacer()
                        
                        Button("변경") {
                            onSelectResume()
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
                Button(action: onSelectResume) {
                    HStack(spacing: 16) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("이력서 선택하기")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("추천을 받을 이력서를 선택하세요")
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
                .disabled(resumes.isEmpty)
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 정보 칩
struct JobRecommendationInfoChip: View {
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

// MARK: - AI 추천 실행 카드
struct AIRecommendationActionCard: View {
    let resume: ResumeResponse
    let isLoading: Bool
    let onStartRecommendation: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("2️⃣ AI 추천 실행")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                Text("🤖 AI가 분석합니다")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("선택한 이력서의 내용을 분석하여\n가장 적합한 채용공고를 찾아드립니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                // 추천 단계 표시
                VStack(spacing: 12) {
                    RecommendationStepRow(
                        icon: "doc.text.magnifyingglass",
                        text: "이력서 내용 분석",
                        isActive: isLoading
                    )
                    
                    RecommendationStepRow(
                        icon: "brain.head.profile",
                        text: "AI 매칭 점수 계산",
                        isActive: isLoading
                    )
                    
                    RecommendationStepRow(
                        icon: "list.number",
                        text: "적합도 순 정렬",
                        isActive: isLoading
                    )
                }
                .padding(.vertical, 8)
                
                Button(action: onStartRecommendation) {
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
                            
                            Text("추천 시작하기")
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
                                .blue,
                                .green
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 6)
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

struct RecommendationStepRow: View {
    let icon: String
    let text: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isActive ? .blue : .gray)
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(isActive ? .primary : .secondary)
            
            Spacer()
            
            if isActive {
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            }
        }
    }
}

// MARK: - 추천 결과 섹션
struct RecommendedJobsSection: View {
    let jobs: [JobRecommendationResponse]
    let selectedResume: ResumeResponse?
    let onViewAllRecommendations: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("3️⃣ 추천 결과")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("🎯 \(jobs.count)개의 적합한 채용공고를 찾았습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if jobs.count > 3 {
                    Button("전체보기") {
                        onViewAllRecommendations()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // 상위 3개 미리보기
            VStack(spacing: 16) {
                ForEach(Array(jobs.prefix(3).enumerated()), id: \.element.id) { index, job in
                    NavigationLink(
                        destination: JobRecommendationDetailView(jobId: job.jobId)
                    ) {
                        RecommendedJobRow(job: job, rank: index + 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if jobs.count > 3 {
                Button(action: onViewAllRecommendations) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        
                        Text("추가 \(jobs.count - 3)개 더 보기")
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

// MARK: - 추천된 채용공고 행
struct RecommendedJobRow: View {
    let job: JobRecommendationResponse
    let rank: Int
    @Environment(\.colorScheme) var colorScheme
    
    private var rankColor: Color {
        switch rank {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        default: return .blue
        }
    }
    
    private var matchScoreColor: Color {
        if job.matchScore >= 0.8 { return .green }
        else if job.matchScore >= 0.6 { return .orange }
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
            
            // 채용공고 정보
            VStack(alignment: .leading, spacing: 6) {
                Text(job.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                HStack {
                    Image(systemName: "building.2.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(job.companyName)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                HStack(spacing: 12) {
                    if let location = job.location {
                        Text("📍 \(location)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let salary = job.salary {
                        Text("💰 \(salary)")
                            .font(.caption2)
                            .foregroundColor(.purple)
                            .lineLimit(1)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(job.formattedDeadline)
                        .font(.caption2)
                        .foregroundColor(job.isDeadlineSoon ? .red : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(job.isDeadlineSoon ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(4)
                    
                    if job.isDeadlineSoon {
                        Text("마감임박")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            // 매칭률
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(matchScoreColor)
                    
                    Text("\(job.matchScorePercentage)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(matchScoreColor)
                }
                
                Text(job.matchReason)
                    .font(.caption2)
                    .foregroundColor(matchScoreColor)
                
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
                            matchScoreColor.opacity(0.4)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: rankColor.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 나머지 컴포넌트들 (에러 카드, 빈 상태 뷰 등)
struct JobRecommendationErrorCard: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("추천 중 오류가 발생했습니다")
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

struct JobRecommendationEmptyResumesView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("등록된 이력서가 없습니다")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("AI 채용공고 추천을 받으려면\n먼저 이력서를 작성해주세요")
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.textSecondary)
                    .lineSpacing(4)
            }
            
            // 🔧 수정: CreateResumeView 대신 ResumeCreateView 사용하거나 더미 뷰로 변경
            NavigationLink(destination: Text("이력서 작성 화면").navigationTitle("이력서 작성")) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                    
                    Text("이력서 작성하기")
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

struct AIRecommendationGuideCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("💡 AI 추천 가이드")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                JobRecommendationGuideRow(
                    icon: "1.circle.fill",
                    tip: "이력서의 기술 스택과 경험을 자세히 작성하세요",
                    color: .blue
                )
                
                JobRecommendationGuideRow(
                    icon: "2.circle.fill",
                    tip: "AI가 분석하여 가장 적합한 채용공고를 추천해드립니다",
                    color: .green
                )
                
                JobRecommendationGuideRow(
                    icon: "3.circle.fill",
                    tip: "매칭률이 높은 공고부터 우선 지원해보세요",
                    color: .orange
                )
                
                JobRecommendationGuideRow(
                    icon: "4.circle.fill",
                    tip: "마감임박 공고는 빠르게 지원하는 것이 좋습니다",
                    color: .red
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

struct JobRecommendationGuideRow: View {
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

struct AllRecommendedJobsView: View {
    let jobs: [JobRecommendationResponse]
    let resume: ResumeResponse
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    JobRecommendationStatsCard(jobs: jobs)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(Array(jobs.enumerated()), id: \.element.id) { index, job in
                            NavigationLink(
                                destination: JobRecommendationDetailView(jobId: job.jobId)
                            ) {
                                RecommendedJobRow(job: job, rank: index + 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .navigationTitle("전체 추천 결과")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("닫기") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct JobRecommendationStatsCard: View {
    let jobs: [JobRecommendationResponse]
    
    private var highMatchCount: Int {
        jobs.filter { $0.matchScore >= 0.8 }.count
    }
    
    private var mediumMatchCount: Int {
        jobs.filter { $0.matchScore >= 0.6 && $0.matchScore < 0.8 }.count
    }
    
    private var urgentJobsCount: Int {
        jobs.filter { $0.isDeadlineSoon }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📊 추천 통계")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                JobRecommendationStatItem(
                    title: "높은 적합도",
                    count: highMatchCount,
                    color: .green,
                    icon: "star.fill"
                )
                
                JobRecommendationStatItem(
                    title: "보통 적합도",
                    count: mediumMatchCount,
                    color: .orange,
                    icon: "star.leadinghalf.filled"
                )
                
                JobRecommendationStatItem(
                    title: "마감임박",
                    count: urgentJobsCount,
                    color: .red,
                    icon: "clock.fill"
                )
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct JobRecommendationStatItem: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct JobRecommendationDetailView: View {
    let jobId: Int
    @State private var job: JobPostingResponse?
    @State private var isLoading = true
    @State private var errorMessage = "" // 🔧 수정: String 타입으로 변경하고 빈 문자열로 초기화
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("채용공고를 불러오는 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let job = job {
                JobRecommendationDetailContentView(job: job)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("채용공고를 불러올 수 없습니다")
                        .font(.headline)
                    
                    // 수정된 부분: Optional 바인딩 → isEmpty 체크
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button("다시 시도") {
                        loadJobDetail()
                    }
                    .padding()
                    .background(AppTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .navigationTitle("채용공고 상세")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if job == nil {
                loadJobDetail()
            }
        }
    }
    
    private func loadJobDetail() {
        isLoading = true
        errorMessage = "" // 🔧 수정: 빈 문자열로 초기화
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.job = JobPostingResponse(
                id: jobId,
                title: "iOS 개발자 채용",
                description: "iOS 앱 개발 경험이 있는 개발자를 모집합니다.",
                position: "iOS Developer",
                requiredSkills: "Swift, iOS, Xcode, UIKit, SwiftUI",
                experienceLevel: "경력 2-5년",
                location: "서울 강남구",
                salary: "연봉 4000-6000만원",
                deadline: nil,
                companyName: "테크 스타트업",
                companyEmail: "hr@techstartup.com",
                createdAt: "2025-05-27T10:00:00"
            )
            self.isLoading = false
        }
    }
}

struct JobRecommendationDetailContentView: View {
    let job: JobPostingResponse
    @State private var showingApplicationSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(job.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(job.companyName ?? "기업명 없음")
                        .font(.headline)
                        .foregroundColor(AppTheme.primary)
                    
                    HStack(spacing: 16) {
                        JobRecommendationInfoChip(icon: "location", text: job.location, color: .blue)
                        JobRecommendationInfoChip(icon: "briefcase", text: job.experienceLevel, color: .green)
                        
                        if !job.salary.isEmpty {
                            JobRecommendationInfoChip(icon: "dollarsign.circle", text: job.salary, color: .purple)
                        }
                    }
                }
                
                Divider()
                
                if !job.description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📋 채용 상세")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(job.description)
                            .font(.body)
                            .lineSpacing(4)
                    }
                    
                    Divider()
                }
                
                if !job.requiredSkills.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("💻 필요 기술")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        let skills = job.requiredSkills.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(skills, id: \.self) { skill in
                                Text(skill)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    Divider()
                }
                
                Button(action: {
                    showingApplicationSheet = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18))
                        
                        Text("지원하기")
                            .font(.system(size: 17, weight: .semibold))
                        
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [AppTheme.primary, AppTheme.primary.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Spacer(minLength: 100)
            }
            .padding()
        }
        .sheet(isPresented: $showingApplicationSheet) {
            JobApplicationSheet(job: job)
        }
    }
}

struct JobApplicationSheet: View {
    let job: JobPostingResponse
    @Environment(\.presentationMode) var presentationMode
    @State private var coverLetter = ""
    @State private var isSubmitting = false
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("지원 정보")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(job.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(job.companyName ?? "기업명 없음")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("자기소개서")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        TextEditor(text: $coverLetter)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        if coverLetter.isEmpty {
                            Text("지원 동기와 포부를 작성해주세요")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: submitApplication) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                
                                Text("지원 중...")
                                    .fontWeight(.semibold)
                            } else {
                                Image(systemName: "paperplane.fill")
                                
                                Text("지원 완료")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primary)
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitting)
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("지원서 작성")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("지원 완료", isPresented: $showingSuccess) {
            Button("확인") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("지원이 성공적으로 완료되었습니다.")
        }
    }
    
    private func submitApplication() {
        isSubmitting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSubmitting = false
            showingSuccess = true
        }
    }
}
