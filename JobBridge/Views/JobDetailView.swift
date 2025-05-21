import SwiftUI

struct JobDetailView: View {
    @StateObject var viewModel: JobDetailViewModel
    @State private var showingApplyAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var isScrolled = false
    @Environment(\.presentationMode) var presentationMode
    
    init(job: JobPostingResponse) {
        self._viewModel = StateObject(wrappedValue: JobDetailViewModel(job: job))
    }
    
    init(jobId: Int) {
        self._viewModel = StateObject(wrappedValue: JobDetailViewModel(jobId: jobId))
    }
    
    var body: some View {
        ZStack {
            // 배경색
            AppTheme.background
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.job == nil {
                LoadingView(message: "채용공고를 불러오는 중...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.job == nil {
                ErrorView(
                    message: errorMessage,
                    retryAction: { viewModel.loadJob() }
                )
            } else if let job = viewModel.job {
                // 메인 컨텐츠
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // 헤더 섹션
                        VStack(alignment: .leading, spacing: 16) {
                            // 회사 로고 (실제로는 네트워크 이미지를 사용할 수 있음)
                            CompanyLogoView(companyName: job.companyName ?? "기업")
                            
                            // 제목 및 회사 정보
                            Text(job.title)
                                .heading2()
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(job.companyName ?? "기업명 없음")
                                .heading3()
                                .foregroundColor(AppTheme.primary)
                            
                            // 태그 목록
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    TagView(text: job.location, icon: "mappin.and.ellipse")
                                    TagView(text: job.experienceLevel, icon: "person.fill")
                                    TagView(text: job.position, icon: "briefcase.fill")
                                    
                                    if let matchRate = job.matchRate {
                                        TagView(
                                            text: "일치도: \(Int(matchRate * 100))%",
                                            icon: "star.fill",
                                            color: .green
                                        )
                                    }
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                        }
                        
                        // 정보 섹션
                        VStack(alignment: .leading, spacing: 8) {
                            SectionHeaderView(title: "직무 정보")
                            
                            DetailGrid(items: [
                                DetailItem(icon: "briefcase.fill", title: "직무", value: job.position),
                                DetailItem(icon: "creditcard.fill", title: "급여", value: job.salary),
                                DetailItem(icon: "calendar", title: "등록일", value: job.createdAt.toFormattedDate()),
                                DetailItem(icon: "clock.fill", title: "마감일", value: job.deadline?.toFormattedDate() ?? "상시채용")
                            ])
                        }
                        
                        // 스킬 섹션
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "필요 기술")
                            
                            SkillTagsView(skills: job.requiredSkills.components(separatedBy: ","))
                        }
                        
                        // 직무 설명 섹션
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: "직무 설명")
                            
                            Text(job.description)
                                .body1()
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // 회사 정보 섹션 (있는 경우)
                        if let companyEmail = job.companyEmail {
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeaderView(title: "회사 정보")
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(AppTheme.primary)
                                    
                                    Text(companyEmail)
                                        .body1()
                                }
                                .padding()
                                .background(AppTheme.secondaryBackground)
                                .cornerRadius(10)
                            }
                        }
                        
                        // 지원 상태 메시지 (있는 경우)
                        if let errorMessage = viewModel.applicationErrorMessage {
                            Text(errorMessage)
                                .foregroundColor(AppTheme.error)
                                .font(.footnote)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .background(AppTheme.error.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        // 추가 공간 (하단 지원 버튼을 가리지 않게)
                        Spacer()
                            .frame(height: 80)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                // 하단 고정 지원 버튼
                VStack {
                    Spacer()
                    
                    // 지원 버튼
                    Button(action: {
                        // 이미 지원한 경우 경고 표시
                        if viewModel.isApplied {
                            viewModel.applicationErrorMessage = "이미 지원한 공고입니다."
                        } else {
                            // 처음 지원하는 경우 지원 확인 다이얼로그 표시
                            showingApplyAlert = true
                        }
                    }) {
                        HStack {
                            // 지원 확인 중인 경우 로딩 아이콘 표시
                            if viewModel.isCheckingApplication {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 5)
                                Text("확인 중...")
                            } else {
                                Image(systemName: viewModel.isApplied ? "checkmark.circle.fill" : "paperplane.fill")
                                    .font(.system(size: 18))
                                Text(viewModel.isApplied ? "지원 완료" : "지원하기")
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.isApplied ? Color.gray : AppTheme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding()
                    .background(
                        Rectangle()
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: -3)
                    )
                    .disabled(viewModel.isLoading || viewModel.isCheckingApplication)
                }
            }
        }
        .navigationTitle("채용공고 상세")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(leading: BackButton())
        .onAppear {
            // 화면이 나타날 때마다 지원 여부 다시 확인
            viewModel.checkIfAlreadyApplied()
        }
        // 지원 확인 알림
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
        // 지원 성공 알림
        .alert("지원 완료", isPresented: $showingSuccessAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("채용공고 지원이 완료되었습니다.")
        }
        // 지원 실패 알림
        .alert("지원 실패", isPresented: $showingErrorAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(viewModel.applicationErrorMessage ?? "지원 중 오류가 발생했습니다.")
        }
    }
}

// MARK: - 컴포넌트
struct BackButton: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.primary)
                .padding(8)
                .background(Circle().fill(AppTheme.secondaryBackground))
        }
    }
}

struct CompanyLogoView: View {
    let companyName: String
    
    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.primary.opacity(0.1))
                .frame(width: 70, height: 70)
            
            Text(String(companyName.prefix(1)))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.primary)
        }
    }
}

struct TagView: View {
    let text: String
    let icon: String
    var color: Color = AppTheme.primary
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12))
            
            Text(text)
                .font(.system(size: 13))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(16)
    }
}

struct SectionHeaderView: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .heading3()
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct DetailItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let value: String
}

struct DetailGrid: View {
    let items: [DetailItem]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: item.icon)
                            .foregroundColor(AppTheme.primary)
                            .frame(width: 20)
                        
                        Text(item.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    
                    Text(item.value)
                        .body1()
                        .lineLimit(1)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.secondaryBackground)
                .cornerRadius(10)
            }
        }
    }
}

struct SkillTagsView: View {
    let skills: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(skills.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { skill in
                    Text(skill.trimmingCharacters(in: .whitespacesAndNewlines))
                        .font(.system(size: 14))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(AppTheme.primary)
                        .cornerRadius(20)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

extension String {
    func toFormattedDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if let date = dateFormatter.date(from: self) {
            dateFormatter.dateFormat = "yyyy년 M월 d일"
            return dateFormatter.string(from: date)
        }
        
        return self
    }
}

struct JobDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            JobDetailView(job: JobPostingResponse(
                id: 1,
                title: "iOS 개발자 (경력 3년 이상)",
                description: "당사는 혁신적인 모바일 앱을 개발하는 기업으로, 경험 많은 iOS 개발자를 찾고 있습니다.",
                position: "iOS 개발자",
                requiredSkills: "Swift, SwiftUI, Objective-C, UIKit",
                experienceLevel: "경력 3년 이상",
                location: "서울시 강남구",
                salary: "6000만원 이상",
                deadline: "2023-06-30 23:59",
                companyName: "테크 이노베이션",
                companyEmail: "recruit@techinnovation.com",
                createdAt: "2023-05-01 09:00",
                matchRate: 0.85
            ))
        }
    }
}
