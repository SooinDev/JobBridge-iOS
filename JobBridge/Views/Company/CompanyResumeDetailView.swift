// CompanyResumeDetailView.swift - 기업용 이력서 상세보기
import SwiftUI

struct CompanyResumeDetailView: View {
    let resume: CompanyMatchingResumeResponse
    let jobPosting: JobPostingResponse
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var showingContactInfo = false
    @State private var animateHeader = false
    @State private var animateContent = false
    
    var body: some View {
        ZStack {
            // 다크모드 적응형 그라데이션 배경
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.1, blue: 0.15),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ] : [
                    Color(red: 0.98, green: 0.99, blue: 1.0),
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // 헤더 섹션
                    CompanyResumeHeaderSection(resume: resume, jobPosting: jobPosting)
                        .offset(y: animateHeader ? 0 : -30)
                        .opacity(animateHeader ? 1 : 0)
                        .animation(.easeOut(duration: 0.6), value: animateHeader)
                    
                    // 메인 컨텐츠
                    VStack(spacing: 32) {
                        // 매칭 분석 카드
                        CompanyMatchingAnalysisSection(resume: resume, jobPosting: jobPosting)
                        
                        // 이력서 내용 섹션
                        CompanyResumeContentSection(resume: resume)
                        
                        // 지원자 정보 섹션
                        CompanyApplicantInfoSection(resume: resume, showingContactInfo: $showingContactInfo)
                        
                        // 액션 버튼들
                        CompanyResumeActionsSection(
                            resume: resume,
                            showingContactInfo: $showingContactInfo
                        )
                        
                        // 하단 여백
                        Spacer()
                            .frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .offset(y: animateContent ? 0 : 50)
                    .opacity(animateContent ? 1 : 0)
                    .animation(.easeOut(duration: 0.8).delay(0.3), value: animateContent)
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(
            // 커스텀 네비게이션 바
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // TODO: 즐겨찾기 기능
                    }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "heart")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateHeader = true
                animateContent = true
            }
        }
    }
}

// MARK: - 헤더 섹션
struct CompanyResumeHeaderSection: View {
    let resume: CompanyMatchingResumeResponse
    let jobPosting: JobPostingResponse
    @Environment(\.colorScheme) var colorScheme
    
    private var matchRateColor: Color {
        switch resume.matchRateColor {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // 매칭률 원형 표시
            ZStack {
                Circle()
                    .stroke(
                        colorScheme == .dark ?
                        matchRateColor.opacity(0.3) :
                        matchRateColor.opacity(0.2),
                        lineWidth: 12
                    )
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: resume.matchRate)
                    .stroke(
                        matchRateColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(resume.matchRatePercentage)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(matchRateColor)
                    
                    Text("%")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(matchRateColor)
                }
            }
            
            // 이력서 정보
            VStack(spacing: 12) {
                Text(resume.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.center)
                
                Text(resume.userName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.primary)
                
                // 매칭 설명
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(matchRateColor)
                    
                    Text(resume.matchRateDescription)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(matchRateColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(matchRateColor.opacity(0.15))
                .cornerRadius(20)
            }
            
            // 대상 채용공고 정보
            VStack(alignment: .leading, spacing: 8) {
                Text("매칭 대상 채용공고")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(jobPosting.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 80)
    }
}

// MARK: - 매칭 분석 섹션
struct CompanyMatchingAnalysisSection: View {
    let resume: CompanyMatchingResumeResponse
    let jobPosting: JobPostingResponse
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI 매칭 분석")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("이 지원자가 채용공고에 적합한 이유")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // 매칭 점수 카드
                CompanyMatchingScoreCard(resume: resume)
                
                // 강점 분석 (Mock 데이터)
                CompanyStrengthAnalysisCard(resume: resume, jobPosting: jobPosting)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    colorScheme == .dark ?
                    Color.white.opacity(0.1) :
                    Color.black.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - 이력서 내용 섹션
struct CompanyResumeContentSection: View {
    let resume: CompanyMatchingResumeResponse
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("이력서 내용")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("지원자의 경력 및 역량")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(resume.content)
                .font(.system(size: 16))
                .lineSpacing(6)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    colorScheme == .dark ?
                    Color.white.opacity(0.1) :
                    Color.black.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - 지원자 정보 섹션
struct CompanyApplicantInfoSection: View {
    let resume: CompanyMatchingResumeResponse
    @Binding var showingContactInfo: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("지원자 정보")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("기본 정보 및 연락처")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resume.userName)
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("이력서 작성일: \(resume.formattedCreatedDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                if showingContactInfo {
                    VStack(spacing: 12) {
                        CompanyInfoRow(icon: "envelope.fill", label: "이메일", value: "mock@email.com")
                        CompanyInfoRow(icon: "phone.fill", label: "연락처", value: "010-1234-5678")
                        CompanyInfoRow(icon: "location.fill", label: "거주지", value: "서울시 강남구")
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    colorScheme == .dark ?
                    Color.white.opacity(0.1) :
                    Color.black.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - 액션 버튼 섹션
struct CompanyResumeActionsSection: View {
    let resume: CompanyMatchingResumeResponse
    @Binding var showingContactInfo: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // 연락처 보기/숨기기 버튼
            Button(action: {
                withAnimation(.spring()) {
                    showingContactInfo.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: showingContactInfo ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(showingContactInfo ? "연락처 숨기기" : "연락처 보기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppTheme.primary,
                            AppTheme.primary.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // 추가 액션 버튼들
            HStack(spacing: 12) {
                Button(action: {
                    // TODO: 이메일 보내기
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                        Text("이메일")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: {
                    // TODO: 즐겨찾기 추가
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.fill")
                        Text("관심목록")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Button(action: {
                    // TODO: 메모 추가
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                        Text("메모")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
}

// MARK: - 보조 컴포넌트들
struct CompanyMatchingScoreCard: View {
    let resume: CompanyMatchingResumeResponse
    
    private var matchRateColor: Color {
        switch resume.matchRateColor {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("매칭 점수")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(resume.matchRatePercentage)%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(matchRateColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("적합도")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(resume.matchRateDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(matchRateColor)
            }
            
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundColor(matchRateColor)
        }
        .padding()
        .background(matchRateColor.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CompanyStrengthAnalysisCard: View {
    let resume: CompanyMatchingResumeResponse
    let jobPosting: JobPostingResponse
    
    // Mock 데이터 기반 강점 분석
    private var strengths: [String] {
        let rate = resume.matchRate
        if rate >= 0.9 {
            return [
                "요구 기술 스택과 완벽 일치",
                "경력 수준이 정확히 맞음",
                "프로젝트 경험이 풍부함"
            ]
        } else if rate >= 0.8 {
            return [
                "핵심 기술 보유",
                "관련 경험 다수",
                "학습 의지 높음"
            ]
        } else {
            return [
                "기본 기술 보유",
                "성장 가능성 있음",
                "열정적인 태도"
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("주요 강점")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(strengths, id: \.self) { strength in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        
                        Text(strength)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CompanyInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}
