import SwiftUI

struct CareerDevelopmentView: View {
    let resume: ResumeResponse
    let jobPosting: JobPostingResponse
    @StateObject private var viewModel = CareerDevelopmentViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더 섹션
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.yellow)
                        
                        Text("AI 경력 개발 가이드")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("목표 직무에 합격하기 위한 맞춤형 성장 로드맵")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // 목표 공고 카드
                JobTargetCard(job: jobPosting)
                    .padding(.horizontal)
                
                // AI 추천 결과
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("AI가 경력 개발 계획을 분석 중...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorCard(message: errorMessage) {
                        viewModel.loadCareerRecommendations(
                            resumeId: resume.id,
                            jobPostingId: jobPosting.id
                        )
                    }
                    .padding(.horizontal)
                    
                } else if viewModel.recommendations.isEmpty {
                    EmptyRecommendationCard()
                        .padding(.horizontal)
                    
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("📋 개선 추천 사항")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 16) {
                            ForEach(Array(viewModel.recommendations.enumerated()), id: \.offset) { index, recommendation in
                                RecommendationCard(
                                    step: index + 1,
                                    recommendation: recommendation
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // 하단 팁
                CareerTipsCard()
                    .padding(.horizontal)
                
                Spacer(minLength: 100)
            }
            .padding(.vertical)
        }
        .navigationTitle("경력 개발")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadCareerRecommendations(
                resumeId: resume.id,
                jobPostingId: jobPosting.id
            )
        }
    }
}

// MARK: - 서브 컴포넌트들

struct JobTargetCard: View {
    let job: JobPostingResponse
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🎯 목표 직무")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(job.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                if let companyName = job.companyName {
                    Text(companyName)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                HStack {
                    Label(job.location, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label(job.experienceLevel, systemImage: "briefcase.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
        .shadow(
            color: Color.blue.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

struct RecommendationCard: View {
    let step: Int
    let recommendation: String
    @Environment(\.colorScheme) var colorScheme
    
    private var stepColor: Color {
        switch step {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .green
        case 5: return .blue
        default: return .purple
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 단계 번호
            ZStack {
                Circle()
                    .fill(stepColor)
                    .frame(width: 32, height: 32)
                
                Text("\(step)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // 추천 내용
            VStack(alignment: .leading, spacing: 8) {
                Text("Step \(step)")
                    .font(.caption)
                    .foregroundColor(stepColor)
                    .fontWeight(.semibold)
                
                Text(recommendation)
                    .font(.body)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineSpacing(4)
            }
            
            Spacer()
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
                .stroke(stepColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: stepColor.opacity(0.1),
            radius: 6,
            x: 0,
            y: 3
        )
    }
}

struct EmptyRecommendationCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("완벽한 이력서입니다! 🎉")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("현재 이력서로도 이 직무에 충분히 경쟁력이 있습니다.\n바로 지원해보세요!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(32)
        .background(
            colorScheme == .dark ?
            Color.green.opacity(0.1) :
            Color.green.opacity(0.05)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CareerTipsCard: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("💡 추가 팁")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TipRow(tip: "추천 사항을 참고하여 이력서를 업데이트해보세요")
                TipRow(tip: "관련 온라인 강의나 자격증을 찾아보세요")
                TipRow(tip: "개인 프로젝트를 통해 부족한 스킬을 연습해보세요")
                TipRow(tip: "업계 트렌드를 지속적으로 학습하세요")
            }
        }
        .padding(20)
        .background(
            colorScheme == .dark ?
            Color.yellow.opacity(0.1) :
            Color.yellow.opacity(0.05)
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}
