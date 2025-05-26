// CompanyApplicationDetailView.swift - 지원자 상세 보기
import SwiftUI

struct CompanyApplicationDetailView: View {
    let application: CompanyApplicationResponse
    let job: JobPostingResponse
    @ObservedObject var viewModel: CompanyApplicationViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingStatusUpdateAlert = false
    @State private var selectedStatus = ""
    @State private var showingContactOptions = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 지원자 정보 카드
                    ApplicantInfoCard(application: application)
                    
                    // 지원 정보 카드
                    ApplicationInfoCard(application: application, job: job)
                    
                    // 상태 관리 카드
                    StatusManagementCard(
                        currentStatus: application.status,
                        onStatusChange: { newStatus in
                            selectedStatus = newStatus
                            showingStatusUpdateAlert = true
                        }
                    )
                    
                    // 연락 옵션 카드
                    ContactOptionsCard(
                        applicantEmail: application.applicantEmail,
                        applicantName: application.applicantName,
                        onContactTapped: {
                            showingContactOptions = true
                        }
                    )
                    
                    // 메모 카드 (추후 구현)
                    ApplicationNotesCard()
                    
                    Spacer()
                        .frame(height: 100)
                }
                .padding()
            }
            .navigationTitle("지원자 상세")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("닫기") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Menu {
                    Button(action: {
                        // TODO: 지원자 정보 내보내기
                    }) {
                        Label("정보 내보내기", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        // TODO: 즐겨찾기 추가
                    }) {
                        Label("즐겨찾기 추가", systemImage: "star")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            )
        }
        .alert("상태 변경", isPresented: $showingStatusUpdateAlert) {
            Button("취소", role: .cancel) { }
            Button("변경") {
                viewModel.updateApplicationStatus(
                    applicationId: application.id,
                    newStatus: selectedStatus
                )
                // 상태 변경 후 화면 닫기
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text("지원자 상태를 '\(getStatusText(selectedStatus))'로 변경하시겠습니까?")
        }
        .actionSheet(isPresented: $showingContactOptions) {
            ActionSheet(
                title: Text("\(application.applicantName)님에게 연락"),
                message: Text("연락 방법을 선택하세요"),
                buttons: [
                    .default(Text("이메일 보내기")) {
                        sendEmail(to: application.applicantEmail)
                    },
                    .default(Text("이메일 주소 복사")) {
                        copyToClipboard(application.applicantEmail)
                    },
                    .cancel(Text("취소"))
                ]
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func getStatusText(_ status: String) -> String {
        switch status {
        case "PENDING": return "대기중"
        case "REVIEWED": return "검토완료"
        case "ACCEPTED": return "합격"
        case "REJECTED": return "불합격"
        default: return "알 수 없음"
        }
    }
    
    private func sendEmail(to email: String) {
        if let url = URL(string: "mailto:\(email)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        // TODO: Toast 메시지 표시
    }
}

// MARK: - 지원자 정보 카드
struct ApplicantInfoCard: View {
    let application: CompanyApplicationResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("👤 지원자 정보")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                InfoRow(label: "이름", value: application.applicantName, icon: "person.fill")
                InfoRow(label: "이메일", value: application.applicantEmail, icon: "envelope.fill")
                InfoRow(label: "지원자 ID", value: "#\(application.applicantId)", icon: "number")
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 지원 정보 카드
struct ApplicationInfoCard: View {
    let application: CompanyApplicationResponse
    let job: JobPostingResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📋 지원 정보")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                InfoRow(label: "지원 직무", value: job.title, icon: "briefcase.fill")
                InfoRow(label: "지원일", value: application.formattedAppliedDate, icon: "calendar")
                InfoRow(label: "현재 상태", value: application.statusText, icon: "flag.fill")
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 상태 관리 카드
struct StatusManagementCard: View {
    let currentStatus: String
    let onStatusChange: (String) -> Void
    
    private let statuses = [
        ("PENDING", "대기중", Color.blue),
        ("REVIEWED", "검토완료", Color.orange),
        ("ACCEPTED", "합격", Color.green),
        ("REJECTED", "불합격", Color.red)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("⚙️ 상태 관리")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("현재 상태: \(getStatusText(currentStatus))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(statuses, id: \.0) { status, text, color in
                    StatusButton(
                        status: status,
                        text: text,
                        color: color,
                        isSelected: currentStatus == status,
                        action: {
                            if currentStatus != status {
                                onStatusChange(status)
                            }
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func getStatusText(_ status: String) -> String {
        switch status {
        case "PENDING": return "대기중"
        case "REVIEWED": return "검토완료"
        case "ACCEPTED": return "합격"
        case "REJECTED": return "불합격"
        default: return "알 수 없음"
        }
    }
}

// MARK: - 상태 버튼
struct StatusButton: View {
    let status: String
    let text: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: getStatusIcon(status))
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                
                Text(text)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color, lineWidth: isSelected ? 0 : 1)
                    )
            )
        }
        .disabled(isSelected)
    }
    
    private func getStatusIcon(_ status: String) -> String {
        switch status {
        case "PENDING": return "clock.fill"
        case "REVIEWED": return "eye.fill"
        case "ACCEPTED": return "checkmark.circle.fill"
        case "REJECTED": return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }
}

// MARK: - 연락 옵션 카드
struct ContactOptionsCard: View {
    let applicantEmail: String
    let applicantName: String
    let onContactTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📞 연락하기")
                .font(.headline)
                .fontWeight(.bold)
            
            Button(action: onContactTapped) {
                HStack(spacing: 12) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(applicantName)님에게 연락")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(applicantEmail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 메모 카드 (추후 구현)
struct ApplicationNotesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📝 메모")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                Text("지원자 메모 기능은 곧 출시될 예정입니다.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                
                Button("메모 추가하기") {
                    // TODO: 메모 추가 기능 구현
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .disabled(true)
            }
        }
        .padding(20)
        .background(AppTheme.secondaryBackground.opacity(0.5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 정보 행
struct InfoRow: View {
    let label: String
    let value: String
    let icon: String
    
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
