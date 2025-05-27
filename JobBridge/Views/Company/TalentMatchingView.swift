// TalentMatchingView.swift - 수정된 기업회원용 AI 인재 매칭 메인 화면
import SwiftUI

struct TalentMatchingView: View {
    @StateObject private var viewModel = TalentMatchingViewModel()
    @State private var selectedJobPosting: JobPostingResponse?
    @State private var showingJobSelector = false
    @State private var showingAllMatches = false
    @State private var currentStep: TalentMatchingStep = .selectJob
    
    enum TalentMatchingStep {
        case selectJob
        case matching
        case results
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 헤더
                    TalentMatchingHeaderView()
                        .padding(.horizontal)
                    
                    // 메인 컨텐츠
                    VStack(spacing: 20) {
                        // 1. 채용공고 선택 카드
                        TalentJobSelectionCard(
                            jobPostings: viewModel.myJobPostings,
                            selectedJob: selectedJobPosting,
                            onSelectJob: {
                                showingJobSelector = true
                            }
                        )
                        .padding(.horizontal)
                        
                        // 2. AI 매칭 실행 카드
                        if selectedJobPosting != nil {
                            AITalentMatchingActionCard(
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
                            MatchedTalentsSection(
                                talents: viewModel.matchedTalents,
                                selectedJob: selectedJobPosting,
                                onViewAllMatches: {
                                    showingAllMatches = true
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        // 에러 표시
                        if let errorMessage = viewModel.errorMessage {
                            TalentMatchingErrorCard(
                                message: errorMessage,
                                retryAction: {
                                    if let job = selectedJobPosting {
                                        viewModel.startTalentMatching(for: job)
                                    }
                                }
                            )
                            .padding(.horizontal)
                        }
                        
                        // 빈 상태 가이드
                        if !viewModel.hasJobPostings {
                            TalentMatchingEmptyJobPostingsView()
                                .padding(.horizontal)
                        } else if selectedJobPosting == nil {
                            AITalentMatchingGuideCard()
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
            viewModel.loadMyJobPostings()
        }
        .sheet(isPresented: $showingJobSelector) {
            TalentJobSelectorSheet(
                jobPostings: viewModel.myJobPostings,
                selectedJob: $selectedJobPosting
            )
        }
        .sheet(isPresented: $showingAllMatches) {
            if let job = selectedJobPosting, !viewModel.matchedTalents.isEmpty {
                AllMatchedTalentsView(
                    talents: viewModel.matchedTalents,
                    jobPosting: job
                )
            }
        }
    }
    
    private func startMatching() {
        guard let job = selectedJobPosting else { return }
        currentStep = .matching
        viewModel.startTalentMatching(for: job)
        
        // 매칭 완료 후 결과 단계로 전환
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if viewModel.hasMatchingResults {
                currentStep = .results
            }
        }
    }
}

// MARK: - 채용공고 선택 시트
struct TalentJobSelectorSheet: View {
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
struct TalentMatchingHeaderView: View {
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
                    
                    Image(systemName: "person.2.fill")
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
                TalentMatchingFeatureBadge(
                    icon: "brain.head.profile",
                    text: "AI 분석",
                    color: .purple
                )
                
                TalentMatchingFeatureBadge(
                    icon: "target",
                    text: "정확한 매칭",
                    color: .blue
                )
                
                TalentMatchingFeatureBadge(
                    icon: "clock.fill",
                    text: "빠른 추천",
                    color: .green
                )
                
                Spacer()
            }
        }
    }
}

// MARK: - 기능 배지 (TalentMatching용)
struct TalentMatchingFeatureBadge: View {
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

// MARK: - 채용공고 선택 카드 (TalentMatching용)
struct TalentJobSelectionCard: View {
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
                        TalentMatchingInfoChip(icon: "location.fill", text: job.location, color: .blue)
                        TalentMatchingInfoChip(icon: "briefcase.fill", text: job.experienceLevel, color: .purple)
                        
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

// MARK: - 정보 칩 (TalentMatching용)
struct TalentMatchingInfoChip: View {
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

// MARK: - AI 인재 매칭 실행 카드
struct AITalentMatchingActionCard: View {
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
                Text("🎯 AI가 분석합니다")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text("선택한 채용공고의 요구사항과\n가장 적합한 인재를 찾아드립니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                // 매칭 단계 표시
                VStack(spacing: 12) {
                    TalentMatchingStepRow(
                        icon: "person.text.rectangle",
                        text: "이력서 데이터 수집",
                        isActive: isLoading
                    )
                    
                    TalentMatchingStepRow(
                        icon: "brain.head.profile",
                        text: "AI 적합도 계산",
                        isActive: isLoading
                    )
                    
                    TalentMatchingStepRow(
                        icon: "list.number",
                        text: "매칭도 순 정렬",
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

struct TalentMatchingStepRow: View {
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
struct MatchedTalentsSection: View {
    let talents: [TalentMatchResponse]
    let selectedJob: JobPostingResponse?
    let onViewAllMatches: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("3️⃣ 추천 결과")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("🎯 \(talents.count)명의 적합한 인재를 찾았습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if talents.count > 3 {
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
                ForEach(Array(talents.prefix(3).enumerated()), id: \.element.id) { index, talent in
                    NavigationLink(
                        destination: TalentDetailView(
                            talent: talent,
                            jobPosting: selectedJob ?? JobPostingResponse(
                                id: 0, title: "", description: "", position: "",
                                requiredSkills: "", experienceLevel: "", location: "",
                                salary: "", deadline: nil, companyName: nil,
                                companyEmail: nil, createdAt: ""
                            )
                        )
                    ) {
                        MatchedTalentRow(talent: talent, rank: index + 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if talents.count > 3 {
                Button(action: onViewAllMatches) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                        
                        Text("추가 \(talents.count - 3)명 더 보기")
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

// MARK: - 매칭된 인재 행
struct MatchedTalentRow: View {
    let talent: TalentMatchResponse
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
    
    private var fitmentColor: Color {
        switch talent.fitmentLevel {
        case "EXCELLENT": return .red
        case "VERY_GOOD": return .green
        case "GOOD": return .blue
        case "FAIR": return .orange
        case "POTENTIAL": return .purple
        default: return .gray
        }
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
            
            // 인재 정보
            VStack(alignment: .leading, spacing: 6) {
                Text(talent.resumeTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(talent.candidateName)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    if let age = talent.candidateAge {
                        Text("• \(age)세")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    if let location = talent.candidateLocation {
                        Text("📍 \(location)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Text("📅 \(talent.formattedUpdatedDate)")
                        .font(.caption2)
                        .foregroundColor(talent.isRecentlyUpdated ? .green : .secondary)
                }
                
                HStack(spacing: 8) {
                    Text(talent.fitmentLevelKorean)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(fitmentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(fitmentColor.opacity(0.1))
                        .cornerRadius(6)
                    
                    if talent.isRecentlyUpdated {
                        Text("최근활동")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
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
                        .foregroundColor(fitmentColor)
                    
                    Text("\(talent.matchScorePercentage)%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(fitmentColor)
                }
                
                Text(talent.recommendationReason.prefix(15) + "...")
                    .font(.caption2)
                    .foregroundColor(fitmentColor)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "envelope.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    
                    Text("연락하기")
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
                            fitmentColor.opacity(0.4)
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

// MARK: - 에러 메시지 카드
struct TalentMatchingErrorCard: View {
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

// MARK: - 빈 상태 뷰
struct TalentMatchingEmptyJobPostingsView: View {
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

// MARK: - AI 인재 매칭 가이드 카드
struct AITalentMatchingGuideCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("💡 AI 인재 매칭 가이드")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                TalentMatchingGuideRow(
                    icon: "1.circle.fill",
                    tip: "채용공고의 필요 기술과 경험을 구체적으로 작성하세요",
                    color: .blue
                )
                
                TalentMatchingGuideRow(
                    icon: "2.circle.fill",
                    tip: "AI가 분석하여 가장 적합한 인재를 추천해드립니다",
                    color: .purple
                )
                
                TalentMatchingGuideRow(
                    icon: "3.circle.fill",
                    tip: "매칭률이 높은 인재부터 우선 검토해보세요",
                    color: .green
                )
                
                TalentMatchingGuideRow(
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

struct TalentMatchingGuideRow: View {
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

// MARK: - 전체 매칭 결과 뷰
struct AllMatchedTalentsView: View {
    let talents: [TalentMatchResponse]
    let jobPosting: JobPostingResponse
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 통계 카드
                    TalentMatchingStatsCard(talents: talents)
                        .padding(.horizontal)
                    
                    // 전체 매칭 목록
                    LazyVStack(spacing: 12) {
                        ForEach(Array(talents.enumerated()), id: \.element.id) { index, talent in
                            NavigationLink(
                                destination: TalentDetailView(talent: talent, jobPosting: jobPosting)
                            ) {
                                MatchedTalentRow(talent: talent, rank: index + 1)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .navigationTitle("전체 매칭 결과")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("닫기") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct TalentMatchingStatsCard: View {
    let talents: [TalentMatchResponse]
    
    private var excellentCount: Int {
        talents.filter { $0.fitmentLevel == "EXCELLENT" }.count
    }
    
    private var veryGoodCount: Int {
        talents.filter { $0.fitmentLevel == "VERY_GOOD" }.count
    }
    
    private var recentlyUpdatedCount: Int {
        talents.filter { $0.isRecentlyUpdated }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📊 매칭 통계")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                TalentMatchingStatItem(
                    title: "완벽 매치",
                    count: excellentCount,
                    color: .red,
                    icon: "crown.fill"
                )
                
                TalentMatchingStatItem(
                    title: "매우 좋음",
                    count: veryGoodCount,
                    color: .green,
                    icon: "star.fill"
                )
                
                TalentMatchingStatItem(
                    title: "최근 활동",
                    count: recentlyUpdatedCount,
                    color: .orange,
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

// MARK: - 통계 아이템 (TalentMatching용)
struct TalentMatchingStatItem: View {
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

// MARK: - 인재 상세 뷰
struct TalentDetailView: View {
    let talent: TalentMatchResponse
    let jobPosting: JobPostingResponse
    @Environment(\.presentationMode) var presentationMode
    @State private var showingContactAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 인재 정보 헤더
                TalentHeaderCard(talent: talent)
                    .padding(.horizontal)
                
                // 매칭 분석
                MatchingAnalysisCard(talent: talent, jobPosting: jobPosting)
                    .padding(.horizontal)
                
                // 이력서 내용
                ResumeContentCard(talent: talent)
                    .padding(.horizontal)
                
                // 연락하기 버튼
                ContactTalentCard(talent: talent, showingAlert: $showingContactAlert)
                    .padding(.horizontal)
                
                Spacer(minLength: 100)
            }
            .padding(.vertical)
        }
        .navigationTitle("인재 상세")
        .navigationBarTitleDisplayMode(.inline)
        .alert("연락처 정보", isPresented: $showingContactAlert) {
            Button("메일 보내기") {
                openEmailApp()
            }
            Button("복사하기") {
                copyToClipboard()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("이메일: \(talent.candidateEmail)")
        }
    }
    
    private func openEmailApp() {
        let email = talent.candidateEmail
        let subject = "[\(jobPosting.title)] 채용 관련 문의"
        let body = "안녕하세요, \(talent.candidateName)님.\n\n\(jobPosting.title) 포지션에 관심이 있어 연락드립니다."
        
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = talent.candidateEmail
    }
}

struct TalentHeaderCard: View {
    let talent: TalentMatchResponse
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(talent.candidateName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(talent.resumeTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(talent.matchScorePercentage)%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(talent.matchScoreColor))
                    
                    Text("적합도")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 16) {
                if let location = talent.candidateLocation {
                    TalentMatchingInfoChip(icon: "location.fill", text: location, color: .blue)
                }
                
                TalentMatchingInfoChip(icon: "person.fill", text: talent.candidateAgeString, color: .purple)
                TalentMatchingInfoChip(icon: "calendar", text: talent.formattedUpdatedDate, color: .green)
                
                Spacer()
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct MatchingAnalysisCard: View {
    let talent: TalentMatchResponse
    let jobPosting: JobPostingResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎯 매칭 분석")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                AnalysisRow(
                    title: "적합도 등급",
                    value: talent.fitmentLevelKorean,
                    color: Color(talent.fitmentLevelColor)
                )
                
                AnalysisRow(
                    title: "매칭 점수",
                    value: "\(talent.matchScorePercentage)%",
                    color: Color(talent.matchScoreColor)
                )
                
                AnalysisRow(
                    title: "추천 이유",
                    value: talent.recommendationReason,
                    color: .secondary
                )
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct AnalysisRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ResumeContentCard: View {
    let talent: TalentMatchResponse
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("📄 이력서 내용")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(isExpanded ? "접기" : "더보기") {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            Text(talent.resumeTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.bottom, 8)
            
            // 이력서 내용은 실제로는 talent.resumeContent가 있어야 하지만
            // 현재 모델에는 없으므로 placeholder 사용
            Text("이력서 상세 내용이 여기에 표시됩니다. AI 매칭 시스템이 분석한 내용을 바탕으로 적합도를 평가했습니다.")
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(isExpanded ? nil : 3)
                .animation(.easeInOut, value: isExpanded)
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct ContactTalentCard: View {
    let talent: TalentMatchResponse
    @Binding var showingAlert: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📞 연락하기")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("이 인재에게 관심이 있으시면 직접 연락해보세요!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAlert = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 18))
                    
                    Text("연락하기")
                        .font(.system(size: 17, weight: .semibold))
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 18))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
