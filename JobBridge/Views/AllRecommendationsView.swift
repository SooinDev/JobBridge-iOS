// AllRecommendationsView.swift
import SwiftUI

struct AllRecommendationsView: View {
    let jobs: [JobPostingResponse]
    let resumeTitle: String
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 헤더 정보
                    AIRecommendationHeaderView(
                        jobCount: jobs.count,
                        resumeTitle: resumeTitle,
                        averageMatchRate: averageMatchRate
                    )
                    .padding(.horizontal)
                    
                    // 매칭 통계
                    DetailedMatchingStatsView(jobs: jobs)
                        .padding(.horizontal)
                    
                    // 추천 공고 리스트
                    LazyVStack(spacing: 16) {
                        ForEach(Array(jobs.enumerated()), id: \.element.id) { index, job in
                            NavigationLink(destination: JobDetailView(job: job)) {
                                DetailedMatchingJobCard(job: job, rank: index + 1)
                            }
                            .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 하단 팁
                    AIRecommendationTipsView()
                        .padding(.horizontal)
                    
                    Spacer(minLength: 50)
                }
                .padding(.vertical)
            }
            .navigationTitle("AI 추천 공고")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("닫기") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("새로고침") {
                    // TODO: 새로고침 기능 구현
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var averageMatchRate: Double {
        let rates = jobs.compactMap { $0.matchRate }
        guard !rates.isEmpty else { return 0 }
        return rates.reduce(0, +) / Double(rates.count)
    }
}

// MARK: - AI 추천 헤더
struct AIRecommendationHeaderView: View {
    let jobCount: Int
    let resumeTitle: String
    let averageMatchRate: Double
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 메인 타이틀
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI 맞춤 추천")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("\(jobCount)개의 채용공고를 찾았습니다")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 기준 이력서 정보
            VStack(alignment: .leading, spacing: 8) {
                Text("📋 분석 기준")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("이력서: \(resumeTitle)")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Text("평균 일치도: \(Int(averageMatchRate * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                colorScheme == .dark ?
                Color.green.opacity(0.1) :
                Color.green.opacity(0.05)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - 상세 매칭 통계
struct DetailedMatchingStatsView: View {
    let jobs: [JobPostingResponse]
    
    private var matchRateDistribution: [(String, Int, Color)] {
        var distribution: [(String, Int, Color)] = []
        let rates = jobs.compactMap { $0.matchRate }
        
        let excellent = rates.filter { $0 >= 0.9 }.count
        let good = rates.filter { $0 >= 0.8 && $0 < 0.9 }.count
        let fair = rates.filter { $0 >= 0.7 && $0 < 0.8 }.count
        let poor = rates.filter { $0 >= 0.6 && $0 < 0.7 }.count
        
        if excellent > 0 { distribution.append(("🔥 90%+", excellent, .red)) }
        if good > 0 { distribution.append(("🟢 80-89%", good, .green)) }
        if fair > 0 { distribution.append(("🟡 70-79%", fair, .orange)) }
        if poor > 0 { distribution.append(("🔴 60-69%", poor, .blue)) }
        
        return distribution
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📊 매칭 분석")
                .font(.headline)
                .fontWeight(.bold)
            
            // 일치도 분포
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(matchRateDistribution, id: \.0) { category, count, color in
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(color)
                        
                        Text(category)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(color.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // 추가 통계
            HStack(spacing: 20) {
                StatItem(
                    title: "최고 매칭률",
                    value: "\(Int((jobs.compactMap { $0.matchRate }.max() ?? 0) * 100))%",
                    color: .green
                )
                
                StatItem(
                    title: "최저 매칭률",
                    value: "\(Int((jobs.compactMap { $0.matchRate }.min() ?? 0) * 100))%",
                    color: .orange
                )
                
                Spacer()
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

// MARK: - 상세 매칭 공고 카드
struct DetailedMatchingJobCard: View {
    let job: JobPostingResponse
    let rank: Int
    @Environment(\.colorScheme) var colorScheme
    
    private var rankColor: Color {
        switch rank {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4...5: return .green
        default: return .blue
        }
    }
    
    private var matchRateColor: Color {
        guard let rate = job.matchRate else { return .gray }
        if rate >= 0.9 { return .red }
        else if rate >= 0.8 { return .green }
        else if rate >= 0.7 { return .orange }
        else { return .blue }
    }
    
    private var matchRateDescription: String {
        guard let rate = job.matchRate else { return "알 수 없음" }
        if rate >= 0.9 { return "완벽 매치" }
        else if rate >= 0.8 { return "높은 적합도" }
        else if rate >= 0.7 { return "양호한 적합도" }
        else { return "기본 적합도" }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 상단: 순위와 매칭률
            HStack {
                // 순위 배지
                HStack(spacing: 6) {
                    Image(systemName: getRankIcon())
                        .font(.system(size: 14, weight: .bold))
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
                
                // 매칭률과 설명
                if let matchRate = job.matchRate {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(matchRateColor)
                            
                            Text("\(Int(matchRate * 100))%")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(matchRateColor)
                        }
                        
                        Text(matchRateDescription)
                            .font(.caption)
                            .foregroundColor(matchRateColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(matchRateColor.opacity(0.15))
                    .cornerRadius(20)
                }
            }
            
            // 중간: 채용공고 정보
            VStack(alignment: .leading, spacing: 12) {
                Text(job.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(2)
                
                if let companyName = job.companyName {
                    HStack {
                        Image(systemName: "building.2")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text(companyName)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                
                Text(job.description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .lineSpacing(2)
            }
            
            // 하단: 채용 정보
            VStack(spacing: 8) {
                HStack {
                    InfoChip(icon: "location.fill", text: job.location, color: .blue)
                    InfoChip(icon: "briefcase.fill", text: job.experienceLevel, color: .purple)
                    
                    Spacer()
                }
                
                HStack {
                    InfoChip(icon: "dollarsign.circle.fill", text: job.salary, color: .green)
                    
                    Spacer()
                    
                    Text("등록: \(job.createdAt.toShortDate())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // AI 분석 태그
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
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [rankColor.opacity(0.5), matchRateColor.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(
            color: rankColor.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    private func getRankIcon() -> String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "star.fill"
        default: return "trophy.fill"
        }
    }
}

struct InfoChip: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - AI 추천 팁
struct AIRecommendationTipsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("💡 AI 추천 활용 팁")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                AITipRow(tip: "높은 매칭률(80% 이상)의 공고에 우선 지원하세요")
                AITipRow(tip: "매칭률이 낮아도 관심 있는 분야라면 도전해보세요")
                AITipRow(tip: "부족한 스킬은 '경력 개발 가이드'에서 확인하세요")
                AITipRow(tip: "이력서를 업데이트하면 더 정확한 추천을 받을 수 있어요")
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

struct AITipRow: View {
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
