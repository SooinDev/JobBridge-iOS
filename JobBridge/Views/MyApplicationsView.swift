
import SwiftUI

struct MyApplicationsView: View {
    @StateObject private var viewModel = ApplicationViewModel()
    @State private var isRefreshing = false
    @State private var showRetryAlert = false
    
    var body: some View {
        ZStack {
            // 배경
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // 컨텐츠
            if viewModel.isLoading && viewModel.applications.isEmpty {
                // 로딩 중
                VStack(spacing: 15) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding(.bottom, 10)
                    
                    Text("지원 내역을 불러오는 중...")
                        .font(.headline)
                    
                    Text("잠시만 기다려주세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 2)
                )
            } else if let errorMessage = viewModel.errorMessage, viewModel.applications.isEmpty {
                // 오류 발생
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("지원 내역을 불러올 수 없습니다")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        viewModel.loadMyApplications()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("다시 시도")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // 추가: 서버 응답 확인 버튼
                    Button(action: {
                        showRetryAlert = true
                    }) {
                        Text("서버 응답 확인하기")
                            .font(.footnote)
                            .padding(.top, 8)
                    }
                    .alert(isPresented: $showRetryAlert) {
                        Alert(
                            title: Text("문제 해결 안내"),
                            message: Text("1. 인터넷 연결을 확인하세요\n2. 계정이 개인 회원인지 확인하세요\n3. 로그아웃 후 다시 로그인 해보세요"),
                            dismissButton: .default(Text("확인"))
                        )
                    }
                }
                .padding()
            } else if viewModel.applications.isEmpty {
                // 데이터 없음
                VStack(spacing: 20) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("지원한 채용공고가 없습니다")
                        .font(.headline)
                    
                    Text("채용공고 탭에서 관심있는 채용공고에 지원해보세요")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    NavigationLink(destination: JobsView(viewModel: JobViewModel())) {
                        HStack {
                            Image(systemName: "briefcase.fill")
                            Text("채용공고 보기")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding()
            } else {
                // 지원 내역 목록
                List {
                    ForEach(viewModel.applications) { application in
                        NavigationLink(destination: JobDetailView(jobId: application.jobPostingId)) {
                            ApplicationRow(application: application)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    isRefreshing = true
                    viewModel.loadMyApplications()
                    isRefreshing = false
                }
            }
        }
        .navigationTitle("지원 내역")
        .onAppear {
            viewModel.loadMyApplications()
        }
    }
}

struct ApplicationRow: View {
    let application: ApplicationResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(application.jobTitle)
                .font(.headline)
            
            Text(application.companyName)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("지원일: \(formatDate(application.appliedAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("지원 완료")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ dateString: String) -> String {
        // 다양한 날짜 형식을 처리할 수 있도록 여러 포맷터 준비
        let formatters: [DateFormatter] = [
            // ISO 8601 형식 (yyyy-MM-dd'T'HH:mm:ss)
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                return formatter
            }(),
            // yyyy-MM-dd HH:mm 형식
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                return formatter
            }(),
            // yyyy-MM-dd 형식
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }()
        ]
        
        // 모든 포맷터로 파싱 시도
        for formatter in formatters {
            if let date = formatter.date(from: dateString) {
                // 출력용 포맷터
                let outputFormatter = DateFormatter()
                outputFormatter.dateFormat = "yyyy년 M월 d일"
                outputFormatter.locale = Locale(identifier: "ko_KR")
                return outputFormatter.string(from: date)
            }
        }
        
        // 파싱 실패 시 원본 반환
        print("❌ 날짜 파싱 실패: \(dateString)")
        return dateString
    }
}

struct MyApplicationsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MyApplicationsView()
        }
    }
}
