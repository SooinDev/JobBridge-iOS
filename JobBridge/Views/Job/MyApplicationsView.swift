import SwiftUI

struct MyApplicationsView: View {
    @StateObject private var viewModel = ApplicationViewModel()
    @State private var isRefreshing = false
    @State private var showRetryAlert = false
    
    var body: some View {
        ZStack {
            // 배경
            AppTheme.background
                .ignoresSafeArea()
            
            // 컨텐츠
            if viewModel.isLoading && viewModel.applications.isEmpty {
                // 로딩 중
                LoadingView(message: "지원 내역을 불러오는 중...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.applications.isEmpty {
                // 오류 발생
                ErrorView(
                    message: errorMessage,
                    retryAction: { viewModel.loadMyApplications() }
                )
            } else if viewModel.applications.isEmpty {
                // 데이터 없음
                EmptyStateView(
                    icon: "paperplane",
                    title: "지원 내역 없음",
                    message: "채용공고 탭에서 관심있는 채용공고에 지원해보세요.",
                    buttonTitle: "채용공고 보기",
                    buttonAction: nil
                )
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
                .foregroundColor(AppTheme.textPrimary)
            
            Text(application.companyName)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
            
            HStack {
                Text("지원일: \(formatDate(application.appliedAt))")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
                
                Spacer()
                
                Text("지원 완료")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppTheme.success.opacity(0.2))
                    .foregroundColor(AppTheme.success)
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
