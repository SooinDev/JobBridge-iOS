import SwiftUI

struct JobDetailView: View {
    @StateObject var viewModel: JobDetailViewModel
    @State private var showingApplyAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    
    init(job: JobPostingResponse) {
        self._viewModel = StateObject(wrappedValue: JobDetailViewModel(job: job))
    }
    
    init(jobId: Int) {
        self._viewModel = StateObject(wrappedValue: JobDetailViewModel(jobId: jobId))
    }
    
    var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.job == nil {
                ProgressView("채용공고를 불러오는 중...")
                    .padding(.top, 40)
            } else if let errorMessage = viewModel.errorMessage, viewModel.job == nil {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("채용공고를 불러올 수 없습니다")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        viewModel.loadJob()
                    }) {
                        Text("다시 시도")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            } else if let job = viewModel.job {
                VStack(alignment: .leading, spacing: 20) {
                    // 헤더 섹션
                    VStack(alignment: .leading, spacing: 10) {
                        Text(job.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(job.companyName ?? "기업명 없음")
                            .font(.headline)
                        
                        HStack {
                            Label(job.location, systemImage: "mappin.and.ellipse")
                            Spacer()
                            Label(job.experienceLevel, systemImage: "person.fill")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        if let matchRate = job.matchRate {
                            HStack {
                                Spacer()
                                Label("일치도: \(Int(matchRate * 100))%", systemImage: "star.fill")
                                    .padding(8)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(20)
                            }
                        }
                        
                        Divider()
                    }
                    .padding(.horizontal)
                    
                    // 상세 정보 섹션
                    VStack(alignment: .leading, spacing: 15) {
                        DetailRow(title: "직무", content: job.position)
                        DetailRow(title: "필요 기술", content: job.requiredSkills)
                        DetailRow(title: "급여", content: job.salary)
                        
                        if let deadline = job.deadline {
                            DetailRow(title: "마감일", content: deadline.toFormattedDate())
                        }
                        
                        DetailRow(title: "등록일", content: job.createdAt.toFormattedDate())
                    }
                    .padding(.horizontal)
                    
                    // 직무 설명 섹션
                    VStack(alignment: .leading, spacing: 15) {
                        Text("직무 설명")
                            .font(.headline)
                        
                        Text(job.description)
                            .lineSpacing(5)
                    }
                    .padding(.horizontal)
                    
                    // 지원 상태 메시지 (있는 경우)
                    if let errorMessage = viewModel.applicationErrorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)
                    }
                    
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
                                Text(viewModel.isApplied ? "지원 완료" : "지원하기")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.isApplied ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .disabled(viewModel.isLoading || viewModel.isCheckingApplication)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("채용공고 상세")
        .navigationBarTitleDisplayMode(.inline)
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

struct DetailRow: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(content)
                .font(.body)
        }
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

// String 확장 메서드가 없다면 추가
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
