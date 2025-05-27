// JobApplicationsView.swift
import SwiftUI

struct JobApplicationsView: View {
    let job: JobPostingResponse
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = JobApplicationsViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 헤더 정보
                JobApplicationsHeaderView(job: job)
                    .padding()
                    .background(AppTheme.secondaryBackground)
                
                // 메인 컨텐츠
                if viewModel.isLoading {
                    LoadingView(message: "지원자를 불러오는 중...")
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(
                        message: errorMessage,
                        retryAction: { viewModel.loadApplications(for: job.id) }
                    )
                } else if viewModel.applications.isEmpty {
                    JobApplicationsEmptyView()
                } else {
                    JobApplicationsList(applications: viewModel.applications, viewModel: viewModel)
                }
                
                Spacer()
            }
            .navigationTitle("지원자 관리")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("닫기") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                viewModel.loadApplications(for: job.id)
            }
        }
    }
}

// MARK: - JobApplicationsHeaderView
struct JobApplicationsHeaderView: View {
    let job: JobPostingResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(job.position)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                // 상태 배지
                Text(job.statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(job.statusColor.opacity(0.2))
                    .foregroundColor(job.statusColor)
                    .cornerRadius(8)
            }
            
            // 기본 정보
            HStack {
                InfoTag(icon: "location", text: job.location)
                InfoTag(icon: "calendar", text: "등록: \(job.createdAt.toShortDate())")
                
                Spacer()
            }
        }
    }
}

// MARK: - JobApplicationsEmptyView (고유한 이름)
struct JobApplicationsEmptyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("아직 지원자가 없습니다")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
            
            Text("이 채용공고에 지원한 사람이 없습니다.\n시간이 지나면 지원자들이 나타날 것입니다.")
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal)
            
            // 팁 카드
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text("지원자 모집 팁")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    JobApplicationsTipRow(tip: "채용공고 제목을 구체적으로 작성하세요")
                    JobApplicationsTipRow(tip: "요구 기술을 명확히 명시하세요")
                    JobApplicationsTipRow(tip: "급여 정보를 투명하게 공개하세요")
                    JobApplicationsTipRow(tip: "회사 문화와 복지를 어필하세요")
                }
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - JobApplicationsList
struct JobApplicationsList: View {
    let applications: [JobApplicationResponse]
    @ObservedObject var viewModel: JobApplicationsViewModel
    
    var body: some View {
        List {
            // 통계 섹션
            Section {
                JobApplicationsStatsView(applications: applications)
            }
            
            // 지원자 목록
            Section(header: Text("지원자 목록 (\(applications.count)명)")) {
                ForEach(applications) { application in
                    JobApplicationsRow(application: application, viewModel: viewModel)
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - JobApplicationsStatsView
struct JobApplicationsStatsView: View {
    let applications: [JobApplicationResponse]
    
    private var stats: (pending: Int, reviewed: Int, accepted: Int, rejected: Int) {
        let pending = applications.filter { $0.status == "PENDING" }.count
        let reviewed = applications.filter { $0.status == "REVIEWED" }.count
        let accepted = applications.filter { $0.status == "ACCEPTED" }.count
        let rejected = applications.filter { $0.status == "REJECTED" }.count
        
        return (pending, reviewed, accepted, rejected)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("지원자 현황")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                JobApplicationsStatCard(title: "대기", count: stats.pending, color: .blue)
                JobApplicationsStatCard(title: "검토", count: stats.reviewed, color: .orange)
                JobApplicationsStatCard(title: "합격", count: stats.accepted, color: .green)
                JobApplicationsStatCard(title: "불합격", count: stats.rejected, color: .red)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - JobApplicationsStatCard (고유한 이름)
struct JobApplicationsStatCard: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - JobApplicationsRow (고유한 이름)
struct JobApplicationsRow: View {
    let application: JobApplicationResponse
    @ObservedObject var viewModel: JobApplicationsViewModel
    @State private var showingDetailView = false
    
    private var statusColor: Color {
        switch application.status {
        case "PENDING": return .blue
        case "REVIEWED": return .orange
        case "ACCEPTED": return .green
        case "REJECTED": return .red
        default: return .gray
        }
    }
    
    private var statusText: String {
        switch application.status {
        case "PENDING": return "대기"
        case "REVIEWED": return "검토"
        case "ACCEPTED": return "합격"
        case "REJECTED": return "불합격"
        default: return "알 수 없음"
        }
    }
    
    var body: some View {
        Button(action: {
            showingDetailView = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // 지원자 정보
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(application.applicantName)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text(application.resumeTitle)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // 상태 배지
                    Text(statusText)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                }
                
                // 지원 정보
                HStack {
                    Text("지원일: \(application.applicationDate.toShortDate())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("이력서 ID: \(application.resumeId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .sheet(isPresented: $showingDetailView) {
            JobApplicationDetailView(application: application, viewModel: viewModel)
        }
    }
}

// MARK: - JobApplicationDetailView
struct JobApplicationDetailView: View {
    let application: JobApplicationResponse
    @ObservedObject var viewModel: JobApplicationsViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 지원자 정보 카드
                VStack(alignment: .leading, spacing: 12) {
                    Text("지원자 정보")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("이름:")
                                .fontWeight(.medium)
                            Text(application.applicantName)
                        }
                        
                        HStack {
                            Text("이메일:")
                                .fontWeight(.medium)
                            Text(application.applicantEmail)
                        }
                        
                        HStack {
                            Text("이력서:")
                                .fontWeight(.medium)
                            Text(application.resumeTitle)
                        }
                        
                        HStack {
                            Text("지원일:")
                                .fontWeight(.medium)
                            Text(application.applicationDate.toJobApplicationFormattedDate())
                        }
                    }
                }
                .padding()
                .background(AppTheme.secondaryBackground)
                .cornerRadius(12)
                
                // 상태 변경 버튼들 (추후 구현)
                VStack(spacing: 12) {
                    Text("지원자 상태 관리")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("지원자 상태 변경 기능은 곧 출시될 예정입니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("지원자 상세")
            .navigationBarItems(leading: Button("닫기") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - JobApplicationsViewModel
class JobApplicationsViewModel: ObservableObject {
    @Published var applications: [JobApplicationResponse] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    
    func loadApplications(for jobId: Int) {
        isLoading = true
        errorMessage = nil
        
        // TODO: 실제 API 연동 (현재는 Mock 데이터)
        Task {
            // 실제 구현 시 다음과 같이 API 호출
            // let applications = try await apiService.getJobApplications(jobId: jobId)
            
            // Mock 데이터로 시뮬레이션
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5초 지연
            
            let mockApplications = generateMockApplications(for: jobId)
            
            DispatchQueue.main.async {
                self.applications = mockApplications
                self.isLoading = false
            }
        }
    }
    
    func updateApplicationStatus(applicationId: Int, status: String) {
        // TODO: 실제 API 연동
        Task {
            // 실제 구현 시:
            // try await apiService.updateApplicationStatus(applicationId: applicationId, status: status)
            
            DispatchQueue.main.async {
                if let index = self.applications.firstIndex(where: { $0.id == applicationId }) {
                    // Mock 업데이트
                    print("지원자 상태 업데이트: \(applicationId) -> \(status)")
                }
            }
        }
    }
    
    private func generateMockApplications(for jobId: Int) -> [JobApplicationResponse] {
        let mockNames = ["김철수", "이영희", "박민수", "정수연", "최동훈", "한지민"]
        let mockTitles = [
            "iOS 개발자 이력서",
            "3년차 모바일 개발자",
            "신입 개발자 지원서",
            "풀스택 개발자 경력서",
            "앱 개발 전문가 이력서",
            "Swift 개발자 포트폴리오"
        ]
        let statuses = ["PENDING", "REVIEWED", "PENDING", "ACCEPTED", "PENDING", "REJECTED"]
        
        return Array(0..<mockNames.count).map { index in
            JobApplicationResponse(
                id: index + 1,
                jobPostingId: jobId,
                resumeId: index + 100,
                applicantId: index + 200,
                applicantName: mockNames[index],
                applicantEmail: "\(mockNames[index].lowercased())@email.com",
                resumeTitle: mockTitles[index],
                status: statuses[index],
                applicationDate: "2024-01-\(15 + index) 10:30",
                updatedAt: "2024-01-\(15 + index) 10:30"
            )
        }
    }
}

// MARK: - JobApplicationsTipRow (고유한 이름)
struct JobApplicationsTipRow: View {
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

// MARK: - Extensions
extension String {
    func toJobApplicationFormattedDate() -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if let date = inputFormatter.date(from: self) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy년 M월 d일 HH:mm"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        return self
    }
}
