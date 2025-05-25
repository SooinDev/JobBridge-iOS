import SwiftUI

struct JobDetailView: View {
    @StateObject var viewModel: JobDetailViewModel
    @State private var showingApplyAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var isScrolled = false
    @State private var headerHeight: CGFloat = 0
    @State private var animateContent = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    init(job: JobPostingResponse) {
        self._viewModel = StateObject(wrappedValue: JobDetailViewModel(job: job))
    }
    
    init(jobId: Int) {
        self._viewModel = StateObject(wrappedValue: JobDetailViewModel(jobId: jobId))
    }
    
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
            
            if viewModel.isLoading && viewModel.job == nil {
                ModernLoadingView()
            } else if let errorMessage = viewModel.errorMessage, viewModel.job == nil {
                ModernErrorView(
                    message: errorMessage,
                    retryAction: { viewModel.loadJob() }
                )
            } else if let job = viewModel.job {
                GeometryReader { geometry in
                    ScrollView {
                        VStack(spacing: 0) {
                            // 헤더 섹션 - 더 임팩트 있게
                            ModernJobHeader(job: job)
                                .background(
                                    GeometryReader { headerGeometry in
                                        Color.clear
                                            .onAppear {
                                                headerHeight = headerGeometry.size.height
                                            }
                                    }
                                )
                            
                            // 메인 컨텐츠
                            VStack(spacing: 32) {
                                // 핵심 정보 카드들
                                ModernInfoCardsSection(job: job)
                                
                                // 스킬 및 요구사항
                                ModernSkillsSection(job: job)
                                
                                // 상세 설명
                                ModernDescriptionSection(job: job)
                                
                                // 회사 정보
                                if job.companyEmail != nil {
                                    ModernCompanyInfoSection(job: job)
                                }
                                
                                // 지원 상태 메시지
                                if let errorMessage = viewModel.applicationErrorMessage {
                                    ModernStatusMessage(message: errorMessage, isError: true)
                                }
                                
                                // 하단 여백
                                Spacer()
                                    .frame(height: 120)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        }
                    }
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: animateContent)
                }
                
                // 하단 고정 버튼들 - 플로팅 스타일
                VStack {
                    Spacer()
                    
                    // AI 경력 개발 가이드 버튼 (개인 회원만)
                    if getCurrentUser()?.userType == "INDIVIDUAL" {
                        NavigationLink(destination: CareerDevelopmentView(
                            resume: getCurrentUserResume(),
                            jobPosting: job
                        )) {
                            HStack(spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("AI 경력 개발 가이드")
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
                                        Color.purple,
                                        Color.blue.opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                    
                    // 지원 버튼
                    ModernFloatingApplyButton(
                        isApplied: viewModel.isApplied,
                        isLoading: viewModel.isLoading,
                        isCheckingApplication: viewModel.isCheckingApplication,
                        onApplyTap: {
                            if viewModel.isApplied {
                                viewModel.applicationErrorMessage = "이미 지원한 공고입니다."
                            } else {
                                showingApplyAlert = true
                            }
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.checkIfAlreadyApplied()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateContent = true
            }
        }
        // 알림 처리
        .alert(isPresented: $showingApplyAlert) {
            Alert(
                title: Text("지원 확인"),
                message: Text("이 채용공고에 지원하시겠습니까?"),
                primaryButton: .default(Text("지원하기")) {
                    viewModel.applyToJob { success in
                        if success {
                            showingSuccessAlert = true
                        } else {
                            showingErrorAlert = true
                        }
                    }
                },
                secondaryButton: .cancel(Text("취소"))
            )
        }
        .alert("지원 완료", isPresented: $showingSuccessAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("채용공고 지원이 완료되었습니다.")
        }
        .alert("지원 실패", isPresented: $showingErrorAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.applicationErrorMessage ?? "지원 중 오류가 발생했습니다.")
        }
    }
    
    // MARK: - 도우미 함수들
    
    private func getCurrentUser() -> LoginResponse? {
        guard let userName = UserDefaults.standard.string(forKey: "userName"),
              let userEmail = UserDefaults.standard.string(forKey: "userEmail"),
              let userType = UserDefaults.standard.string(forKey: "userType"),
              let token = UserDefaults.standard.string(forKey: "authToken") else {
            return nil
        }
        
        return LoginResponse(
            token: token,
            name: userName,
            email: userEmail,
            userType: userType
        )
    }
    
    private func getCurrentUserResume() -> ResumeResponse {
        return ResumeResponse(
            id: 1,
            title: "내 이력서",
            content: "iOS 개발자로서 3년간의 경험을 쌓아왔습니다. Swift, SwiftUI, UIKit을 활용한 앱 개발 경험이 있으며, MVVM 패턴과 Combine을 활용한 반응형 프로그래밍에 익숙합니다.",
            userName: getCurrentUser()?.name ?? "사용자",
            createdAt: "2024-01-01 10:00",
            updatedAt: "2024-01-01 10:00"
        )
    }
}

// MARK: - Modern Components

struct ModernJobHeader: View {
    let job: JobPostingResponse
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 네비게이션
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(colorScheme == .dark ?
                                           Color.white.opacity(0.1) :
                                           Color.black.opacity(0.05), lineWidth: 1)
                            )
                        
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(colorScheme == .dark ?
                                           Color.white.opacity(0.1) :
                                           Color.black.opacity(0.05), lineWidth: 1)
                            )
                        
                        Image(systemName: "heart")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // 메인 헤더 컨텐츠
            VStack(spacing: 24) {
                // 회사 로고 및 정보
                HStack(spacing: 20) {
                    // 3D 스타일 회사 로고
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: colorScheme == .dark ? [
                                        AppTheme.primary.opacity(0.9),
                                        AppTheme.primary.opacity(0.7)
                                    ] : [
                                        AppTheme.primary.opacity(0.8),
                                        AppTheme.primary
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: AppTheme.primary.opacity(colorScheme == .dark ? 0.4 : 0.3),
                                   radius: 10, x: 0, y: 8)
                        
                        Text(String((job.companyName ?? "C").prefix(1)))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(job.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .lineLimit(2)
                        
                        Text(job.companyName ?? "기업명 없음")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                        
                        // 인증 배지 (예시)
                        HStack(spacing: 8) {
                            ModernBadge(text: "인증기업", color: .green, icon: "checkmark.shield")
                            ModernBadge(text: "신속채용", color: .orange, icon: "bolt")
                        }
                    }
                    
                    Spacer()
                }
                
                // 매치 정보 (있는 경우)
                if let matchRate = job.matchRate {
                    ModernMatchCard(matchRate: matchRate)
                }
                
                // 기본 태그들
                ModernTagsRow(job: job)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 30)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(colorScheme == .dark ?
                           Color.white.opacity(0.1) :
                           Color.black.opacity(0.05), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }
}

struct ModernBadge: View {
    let text: String
    let color: Color
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            
            Text(text)
                .font(.system(size: 11, weight: .bold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            colorScheme == .dark ?
            color.opacity(0.25) :
            color.opacity(0.15)
        )
        .foregroundColor(
            colorScheme == .dark ?
            color.opacity(0.9) :
            color
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    colorScheme == .dark ?
                    color.opacity(0.3) :
                    color.opacity(0.2),
                    lineWidth: 0.5
                )
        )
    }
}

struct ModernMatchCard: View {
    let matchRate: Double
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // 원형 진행률 표시
            ZStack {
                Circle()
                    .stroke(
                        colorScheme == .dark ?
                        Color.green.opacity(0.3) :
                        Color.green.opacity(0.2),
                        lineWidth: 8
                    )
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: matchRate)
                    .stroke(
                        colorScheme == .dark ?
                        Color.green.opacity(0.9) :
                        Color.green,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(matchRate * 100))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(
                        colorScheme == .dark ?
                        Color.green.opacity(0.9) :
                        Color.green
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("매칭률")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                
                Text("당신과 \(Int(matchRate * 100))% 일치")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text("높은 적합도로 합격 가능성이 높습니다")
                    .font(.system(size: 12))
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    colorScheme == .dark ?
                    Color.green.opacity(0.1) :
                    Color.green.opacity(0.05)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            colorScheme == .dark ?
                            Color.green.opacity(0.3) :
                            Color.green.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
}

struct ModernTagsRow: View {
    let job: JobPostingResponse
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ModernInfoTag(icon: "location.fill", text: job.location, color: .blue)
                ModernInfoTag(icon: "briefcase.fill", text: job.experienceLevel, color: .purple)
                ModernInfoTag(icon: "person.fill", text: job.position, color: .orange)
                ModernInfoTag(icon: "calendar", text: formatDateShort(job.createdAt), color: .gray)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func formatDateShort(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        if let date = formatter.date(from: dateString) {
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
        return dateString
    }
}

struct ModernInfoTag: View {
    let icon: String
    let text: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(
                    colorScheme == .dark ?
                    color.opacity(0.9) :
                    color
                )
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
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

struct ModernInfoCardsSection: View {
    let job: JobPostingResponse
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("채용 정보")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ModernInfoCard(
                    icon: "briefcase.fill",
                    title: "직무",
                    value: job.position,
                    color: .blue,
                    gradient: colorScheme == .dark ?
                        [.blue.opacity(0.2), .blue.opacity(0.1)] :
                        [.blue.opacity(0.1), .blue.opacity(0.05)]
                )
                
                ModernInfoCard(
                    icon: "dollarsign.circle.fill",
                    title: "급여",
                    value: job.salary,
                    color: .green,
                    gradient: colorScheme == .dark ?
                        [.green.opacity(0.2), .green.opacity(0.1)] :
                        [.green.opacity(0.1), .green.opacity(0.05)]
                )
                
                ModernInfoCard(
                    icon: "clock.fill",
                    title: "마감일",
                    value: job.deadline?.toFormattedDate() ?? "상시채용",
                    color: .orange,
                    gradient: colorScheme == .dark ?
                        [.orange.opacity(0.2), .orange.opacity(0.1)] :
                        [.orange.opacity(0.1), .orange.opacity(0.05)]
                )
                
                ModernInfoCard(
                    icon: "calendar.badge.plus",
                    title: "등록일",
                    value: job.createdAt.toFormattedDate(),
                    color: .purple,
                    gradient: colorScheme == .dark ?
                        [.purple.opacity(0.2), .purple.opacity(0.1)] :
                        [.purple.opacity(0.1), .purple.opacity(0.05)]
                )
            }
        }
    }
}

struct ModernInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let gradient: [Color]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            colorScheme == .dark ?
                            color.opacity(0.3) :
                            color.opacity(0.2)
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(
                            colorScheme == .dark ?
                            color.opacity(0.9) :
                            color
                        )
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(2)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: gradient),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    colorScheme == .dark ?
                    color.opacity(0.2) :
                    color.opacity(0.1),
                    lineWidth: 1
                )
        )
    }
}

struct ModernSkillsSection: View {
    let job: JobPostingResponse
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("필요 기술")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("이 포지션에서 사용하는 기술 스택")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                }
                
                Spacer()
            }
            
            ModernSkillTags(skills: job.requiredSkills.components(separatedBy: ","))
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

struct ModernSkillTags: View {
    let skills: [String]
    @Environment(\.colorScheme) var colorScheme
    
    private var skillColors: [Color] {
        colorScheme == .dark ?
        [.blue, .green, .purple, .orange, .pink, .indigo] :
        [.blue, .green, .purple, .orange, .pink, .indigo]
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 100), spacing: 12)
        ], spacing: 12) {
            ForEach(Array(skills.enumerated()), id: \.offset) { index, skill in
                let trimmedSkill = skill.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedSkill.isEmpty {
                    ModernSkillTag(
                        skill: trimmedSkill,
                        color: skillColors[index % skillColors.count]
                    )
                }
            }
        }
    }
}

struct ModernSkillTag: View {
    let skill: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(
                    colorScheme == .dark ?
                    color.opacity(0.8) :
                    color
                )
                .frame(width: 8, height: 8)
            
            Text(skill.hasPrefix("#") ? skill : "#\(skill)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            colorScheme == .dark ?
            color.opacity(0.15) :
            color.opacity(0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    colorScheme == .dark ?
                    color.opacity(0.4) :
                    color.opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

struct ModernDescriptionSection: View {
    let job: JobPostingResponse
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("상세 내용")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("업무 내용 및 요구사항")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                }
                
                Spacer()
            }
            
            Text(job.description)
                .font(.system(size: 16, weight: .regular))
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

struct ModernCompanyInfoSection: View {
    let job: JobPostingResponse
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("회사 정보")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("채용 담당자 연락처")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                }
                
                Spacer()
            }
            
            if let companyEmail = job.companyEmail {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                colorScheme == .dark ?
                                AppTheme.primary.opacity(0.3) :
                                AppTheme.primary.opacity(0.2)
                            )
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 20))
                            .foregroundColor(
                                colorScheme == .dark ?
                                AppTheme.primary.opacity(0.9) :
                                AppTheme.primary
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("이메일")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                        
                        Text(companyEmail)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Spacer()
                }
                .padding(20)
                .background(
                    colorScheme == .dark ?
                    AppTheme.primary.opacity(0.1) :
                    AppTheme.primary.opacity(0.05)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            colorScheme == .dark ?
                            AppTheme.primary.opacity(0.3) :
                            AppTheme.primary.opacity(0.2),
                            lineWidth: 1
                        )
                )
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

// MARK: - 실제 누락된 컴포넌트들만 추가

struct ModernStatusMessage: View {
    let message: String
    let isError: Bool
    @Environment(\.colorScheme) var colorScheme
    
    private var iconColor: Color {
        let baseColor = isError ? Color.red : Color.green
        return colorScheme == .dark ?
            baseColor.opacity(0.9) :
            baseColor
    }
    
    private var textColor: Color {
        let baseColor = isError ? Color.red : Color.green
        return colorScheme == .dark ?
            baseColor.opacity(0.9) :
            baseColor
    }
    
    private var backgroundColor: Color {
        let baseColor = isError ? Color.red : Color.green
        let opacity = colorScheme == .dark ? 0.15 : 0.1
        return baseColor.opacity(opacity)
    }
    
    private var strokeColor: Color {
        let baseColor = isError ? Color.red : Color.green
        let opacity = colorScheme == .dark ? 0.4 : 0.3
        return baseColor.opacity(opacity)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(iconColor)
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textColor)
        }
        .padding(20)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(strokeColor, lineWidth: 1)
        )
    }
}

struct ModernFloatingApplyButton: View {
    let isApplied: Bool
    let isLoading: Bool
    let isCheckingApplication: Bool
    let onApplyTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    private var buttonGradientColors: [Color] {
        if isApplied {
            return colorScheme == .dark ?
                [Color.gray.opacity(0.8), Color.gray.opacity(0.6)] :
                [Color.gray, Color.gray.opacity(0.8)]
        } else {
            return colorScheme == .dark ?
                [AppTheme.primary.opacity(0.9), AppTheme.primary.opacity(0.7)] :
                [AppTheme.primary, AppTheme.primary.opacity(0.8)]
        }
    }
    
    private var shadowColor: Color {
        let baseColor = isApplied ? Color.gray : AppTheme.primary
        let opacity = colorScheme == .dark ? 0.5 : 0.4
        return baseColor.opacity(opacity)
    }
    
    var body: some View {
        Button(action: onApplyTap) {
            HStack(spacing: 12) {
                if isCheckingApplication {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("확인 중...")
                        .font(.system(size: 17, weight: .semibold))
                } else {
                    Image(systemName: isApplied ? "checkmark.circle.fill" : "paperplane.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text(isApplied ? "지원 완료" : "지원하기")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: buttonGradientColors),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(
                color: shadowColor,
                radius: 15,
                x: 0,
                y: 8
            )
            .scaleEffect(isLoading ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: isLoading)
        }
        .disabled(isLoading || isCheckingApplication)
    }
}

struct ModernLoadingView: View {
    @State private var rotation = 0.0
    @Environment(\.colorScheme) var colorScheme
    
    private var strokeColor: Color {
        let opacity = colorScheme == .dark ? 0.3 : 0.2
        return AppTheme.primary.opacity(opacity)
    }
    
    private var trimStrokeColor: Color {
        let opacity = colorScheme == .dark ? 0.9 : 1.0
        return AppTheme.primary.opacity(opacity)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(strokeColor, lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        trimStrokeColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotation))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: rotation)
            }
            
            Text("채용공고를 불러오는 중...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textColor)
        }
        .onAppear {
            rotation = 360
        }
    }
}

struct ModernErrorView: View {
    let message: String
    let retryAction: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    private var circleBackgroundColor: Color {
        colorScheme == .dark ?
            Color.red.opacity(0.15) :
            Color.red.opacity(0.1)
    }
    
    private var iconColor: Color {
        colorScheme == .dark ?
            Color.red.opacity(0.9) :
            .red
    }
    
    private var titleColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var messageColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    private var buttonGradientColors: [Color] {
        colorScheme == .dark ?
            [AppTheme.primary.opacity(0.9), AppTheme.primary.opacity(0.7)] :
            [AppTheme.primary, AppTheme.primary.opacity(0.8)]
    }
    
    private var buttonShadowColor: Color {
        let opacity = colorScheme == .dark ? 0.5 : 0.3
        return AppTheme.primary.opacity(opacity)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(circleBackgroundColor)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(iconColor)
            }
            
            VStack(spacing: 8) {
                Text("오류가 발생했습니다")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(titleColor)
                
                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(messageColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: retryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("다시 시도")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: buttonGradientColors),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(
                    color: buttonShadowColor,
                    radius: 10,
                    x: 0,
                    y: 5
                )
            }
        }
        .padding()
    }
}

// MARK: - Extensions

extension String {
    func toFormattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if let date = dateFormatter.date(from: self) {
            dateFormatter.dateFormat = "yyyy년 M월 d일"
            dateFormatter.locale = Locale(identifier: "ko_KR")
            return dateFormatter.string(from: date)
        }
        
        return self
    }
}
