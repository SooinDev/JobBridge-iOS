import SwiftUI

struct ResumeDetailView: View {
    let resume: ResumeResponse
    @StateObject private var jobViewModel = JobViewModel()
    @StateObject private var resumeViewModel = ResumeViewModel()
    @State private var showingMatchingJobs = false
    @State private var showEditResume = false
    @State private var animateMatchingButton = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더 섹션
                VStack(alignment: .leading, spacing: 10) {
                    Text(resume.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("작성자: \(resume.userName)")
                        Spacer()
                        Text("작성일: \(resume.createdAt.toShortDate())")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Divider()
                }
                .padding(.horizontal)
                
                // 내용 섹션
                VStack(alignment: .leading, spacing: 15) {
                    Text("이력서 내용")
                        .font(.headline)
                    
                    Text(resume.content)
                        .lineSpacing(5)
                }
                .padding(.horizontal)
                
                // 🔥 매칭 버튼
                VStack(spacing: 16) {
                    Button(action: performMatching) {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("AI 추천 채용공고 보기")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue,
                                    Color.purple.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        .scaleEffect(animateMatchingButton ? 0.95 : 1.0)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(jobViewModel.isLoading)
                    
                    // 로딩 상태 표시
                    if jobViewModel.isLoading && showingMatchingJobs {
                        HStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            
                            Text("AI가 최적의 채용공고를 찾고 있습니다...")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // 🔥 매칭 결과 섹션
                if showingMatchingJobs {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI 추천 채용공고")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if !jobViewModel.matchingJobs.isEmpty {
                                    Text("\(jobViewModel.matchingJobs.count)개의 맞춤 공고를 찾았습니다")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if jobViewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        // 개발자 디버그 정보
                        MatchingDebugInfoView(matchingJobs: jobViewModel.matchingJobs)
                        
                        if let error = jobViewModel.errorMessage {
                            ErrorCard(message: error) {
                                performMatching()
                            }
                        } else if jobViewModel.matchingJobs.isEmpty && !jobViewModel.isLoading {
                            VStack(spacing: 16) {
                                EmptyMatchingCard()
                                MatchingTipsView(hasResults: false)
                            }
                        } else {
                            VStack(spacing: 16) {
                                // 매칭 통계
                                MatchingStatsView(jobs: jobViewModel.matchingJobs)
                                
                                // 매칭 결과 리스트
                                LazyVStack(spacing: 16) {
                                    ForEach(Array(jobViewModel.matchingJobs.enumerated()), id: \.element.id) { index, job in
                                        NavigationLink(destination: JobDetailView(job: job)) {
                                            MatchingJobCard(job: job, rank: index + 1)
                                        }
                                    }
                                }
                                
                                // 매칭 팁
                                MatchingTipsView(hasResults: true)
                            }
                        }
                        
                        // 개발자 설정 (DEBUG 모드에서만)
                        DeveloperSettingsView()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("이력서 상세")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("수정") {
            showEditResume = true
        })
        .sheet(isPresented: $showEditResume) {
            EditResumeView(viewModel: resumeViewModel, resume: resume)
        }
        .onDisappear {
            jobViewModel.clearMatchingResults()
            showingMatchingJobs = false
        }
    }
    
    // 🔥 매칭 실행 함수
    private func performMatching() {
        MatchingPerformanceTracker.shared.startTracking()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            animateMatchingButton = true
        }
        
        // 🔥 실제 AI API 호출
        jobViewModel.loadMatchingJobs(resumeId: resume.id)
        
        showingMatchingJobs = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateMatchingButton = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            MatchingPerformanceTracker.shared.endTracking(resultCount: jobViewModel.matchingJobs.count)
        }
    }
}

// MARK: - 매칭 채용공고 카드
struct MatchingJobCard: View {
    let job: JobPostingResponse
    let rank: Int
    @Environment(\.colorScheme) var colorScheme
    
    private var rankColor: Color {
        switch rank {
        case 1: return .orange
        case 2: return .blue
        case 3: return .green
        default: return .purple
        }
    }
    
    private var matchRateColor: Color {
        guard let rate = job.matchRate else { return .gray }
        if rate >= 0.8 { return .green }
        else if rate >= 0.6 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 상단: 순위와 매칭률
            HStack {
                // 순위 배지
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14))
                        .foregroundColor(rankColor)
                    
                    Text("#\(rank)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(rankColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(rankColor.opacity(0.15))
                .cornerRadius(20)
                
                Spacer()
                
                // 매칭률
                if let matchRate = job.matchRate {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(matchRateColor)
                        
                        Text("\(Int(matchRate * 100))%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(matchRateColor)
                        
                        Text("일치")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(matchRateColor.opacity(0.15))
                    .cornerRadius(20)
                }
            }
            
            // 중간: 채용공고 정보
            VStack(alignment: .leading, spacing: 8) {
                Text(job.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(2)
                
                if let companyName = job.companyName {
                    Text(companyName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                } else {
                    Text("외부 채용공고")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.orange)
                }
                
                Text(job.description.prefix(80) + (job.description.count > 80 ? "..." : ""))
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // 하단: 추가 정보
            HStack {
                Label("AI 추천", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundColor(.purple)
                
                Spacer()
                
                Label("상세보기", systemImage: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(20)
        .background(
            colorScheme == .dark ?
            Color(UIColor.secondarySystemBackground) :
            Color.white
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(rankColor.opacity(0.3), lineWidth: 2)
        )
        .shadow(
            color: rankColor.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - 에러 카드
struct ErrorCard: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("추천을 불러올 수 없습니다")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: retryAction) {
                Text("다시 시도")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(20)
            }
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

// MARK: - 빈 상태 카드
struct EmptyMatchingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("추천 채용공고가 없습니다")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("현재 이력서와 일치하는 채용공고를 찾을 수 없습니다.\n이력서를 더 구체적으로 작성해보세요.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(32)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 매칭 통계 정보
struct MatchingStatsView: View {
    let jobs: [JobPostingResponse]
    
    private var averageMatchRate: Double {
        let rates = jobs.compactMap { $0.matchRate }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }
    
    private var topMatchRate: Double {
        jobs.compactMap { $0.matchRate }.max() ?? 0
    }
    
    private var matchRateDistribution: [String: Int] {
        var distribution = ["🔥 90%+": 0, "🟢 80-89%": 0, "🟡 70-79%": 0, "🔴 60-69%": 0]
        
        jobs.compactMap { $0.matchRate }.forEach { rate in
            let percentage = Int(rate * 100)
            switch percentage {
            case 90...100: distribution["🔥 90%+"]! += 1
            case 80...89: distribution["🟢 80-89%"]! += 1
            case 70...79: distribution["🟡 70-79%"]! += 1
            case 60...69: distribution["🔴 60-69%"]! += 1
            default: break
            }
        }
        
        return distribution
    }
    
    var body: some View {
        if !jobs.isEmpty && jobs.contains(where: { $0.matchRate != nil }) {
            VStack(alignment: .leading, spacing: 12) {
                Text("📊 매칭 분석")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("평균 일치도")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(averageMatchRate * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("최고 일치도")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(topMatchRate * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("일치도 분포")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(Array(matchRateDistribution.keys.sorted(by: >)), id: \.self) { key in
                        if let count = matchRateDistribution[key], count > 0 {
                            HStack {
                                Text(key)
                                    .font(.caption)
                                
                                Spacer()
                                
                                Text("\(count)개")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - 매칭 팁 제공
struct MatchingTipsView: View {
    let hasResults: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("💡 매칭 팁")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            if hasResults {
                VStack(alignment: .leading, spacing: 6) {
                    TipRow(tip: "높은 일치도의 공고에 우선 지원해보세요")
                    TipRow(tip: "경력 추천 기능으로 부족한 스킬을 확인하세요")
                    TipRow(tip: "이력서를 더 구체적으로 작성하면 정확도가 높아집니다")
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    TipRow(tip: "이력서에 더 많은 기술과 경험을 추가해보세요")
                    TipRow(tip: "구체적인 프로젝트 경험을 포함해보세요")
                    TipRow(tip: "관심있는 직무 키워드를 이력서에 포함해보세요")
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TipRow: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.yellow)
                .frame(width: 4, height: 4)
                .padding(.top, 6)
            
            Text(tip)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
    }
}

// MARK: - 디버그 정보 표시
struct MatchingDebugInfoView: View {
    let matchingJobs: [JobPostingResponse]
    
    var body: some View {
        if MatchingDebugSettings.enableDetailedLogging {
            VStack(alignment: .leading, spacing: 8) {
                Text("🔧 개발자 정보")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .fontWeight(.bold)
                
                Text("Mock 데이터: \(MatchingDebugSettings.useMockData ? "ON" : "OFF")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("매칭 결과: \(matchingJobs.count)개")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if !matchingJobs.isEmpty {
                    Text("최고 매칭률: \(Int((matchingJobs.first?.matchRate ?? 0) * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)
        }
    }
}

// MARK: - 개발자 설정 토글
struct DeveloperSettingsView: View {
    @State private var showSettings = false
    
    var body: some View {
        #if DEBUG
        VStack {
            Button("🔧 개발자 설정") {
                showSettings.toggle()
            }
            .font(.caption)
            .foregroundColor(.orange)
            
            if showSettings {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Mock 데이터 사용", isOn: .constant(MatchingDebugSettings.useMockData))
                        .font(.caption)
                    
                    Toggle("상세 로깅", isOn: .constant(MatchingDebugSettings.enableDetailedLogging))
                        .font(.caption)
                    
                    HStack {
                        Text("응답 지연:")
                        Text("\(MatchingDebugSettings.mockResponseDelay, specifier: "%.1f")초")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        #endif
    }
}
