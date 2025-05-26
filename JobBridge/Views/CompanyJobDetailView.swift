// CompanyJobDetailView.swift
import SwiftUI

struct CompanyJobDetailView: View {
    let job: JobPostingResponse
    @ObservedObject var viewModel: CompanyJobViewModel
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var showingApplicationsView = false
    
    private var statusInfo: (text: String, color: Color, icon: String) {
        guard let deadline = job.deadline else {
            return ("상시채용", .blue, "infinity")
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        guard let deadlineDate = formatter.date(from: deadline) else {
            return ("상시채용", .blue, "infinity")
        }
        
        if deadlineDate < Date() {
            return ("마감", .red, "xmark.circle.fill")
        } else {
            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: deadlineDate).day ?? 0
            if daysLeft <= 3 {
                return ("D-\(daysLeft)", .orange, "clock.fill")
            } else {
                return ("진행중", .green, "checkmark.circle.fill")
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 헤더 - 상태와 액션 버튼들
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(job.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text(job.position)
                                .font(.headline)
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        // 상태 배지
                        HStack(spacing: 6) {
                            Image(systemName: statusInfo.icon)
                                .font(.caption)
                            
                            Text(statusInfo.text)
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(statusInfo.color.opacity(0.2))
                        .foregroundColor(statusInfo.color)
                        .cornerRadius(20)
                    }
                    
                    // 액션 버튼들
                    HStack(spacing: 12) {
                        // 지원자 보기 버튼
                        Button(action: {
                            showingApplicationsView = true
                        }) {
                            HStack {
                                Image(systemName: "person.3.fill")
                                Text("지원자 보기")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.primary)
                            .cornerRadius(10)
                        }
                        
                        // 수정 버튼
                        Button(action: {
                            showingEditView = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("수정")
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(AppTheme.primary.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .background(AppTheme.secondaryBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                // 상세 정보 카드들
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    CompanyJobInfoCard(
                        icon: "location.fill",
                        title: "근무지",
                        value: job.location,
                        color: .blue
                    )
                    
                    CompanyJobInfoCard(
                        icon: "dollarsign.circle.fill",
                        title: "급여",
                        value: job.salary,
                        color: .green
                    )
                    
                    CompanyJobInfoCard(
                        icon: "briefcase.fill",
                        title: "경력",
                        value: job.experienceLevel,
                        color: .orange
                    )
                    
                    CompanyJobInfoCard(
                        icon: "calendar",
                        title: "등록일",
                        value: job.createdAt.toShortDate(),
                        color: .purple
                    )
                }
                .padding(.horizontal)
                
                // 마감일 (있는 경우)
                if let deadline = job.deadline {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("지원 마감일")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(deadline.toFormattedDate())
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                
                                Text(getDeadlineDescription(deadline))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                }
                
                // 필요 기술
                if !job.requiredSkills.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("필요 기술")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        CompanySkillTags(skills: job.requiredSkills.components(separatedBy: ","))
                    }
                    .padding()
                    .background(AppTheme.secondaryBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                }
                
                // 상세 설명
                VStack(alignment: .leading, spacing: 16) {
                    Text("상세 설명")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(job.description)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding()
                .background(AppTheme.secondaryBackground)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
                
                // 하단 여백
                Spacer()
                    .frame(height: 100)
            }
            .padding(.vertical)
        }
        .navigationTitle("채용공고 상세")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Menu {
            Button(action: {
                showingEditView = true
            }) {
                Label("수정", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: {
                showingDeleteAlert = true
            }) {
                Label("삭제", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        })
        .sheet(isPresented: $showingEditView) {
            EditJobPostingView(job: job, viewModel: viewModel)
        }
        .sheet(isPresented: $showingApplicationsView) {
            JobApplicationsView(job: job)
        }
        .alert("채용공고 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                viewModel.deleteJobPosting(jobId: job.id)
            }
        } message: {
            Text("이 채용공고를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.")
        }
    }
    
    private func getDeadlineDescription(_ deadlineString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        guard let deadline = formatter.date(from: deadlineString) else { return "" }
        
        let now = Date()
        let timeInterval = deadline.timeIntervalSince(now)
        
        if timeInterval < 0 {
            return "마감됨"
        } else {
            let days = Int(timeInterval / (24 * 60 * 60))
            let hours = Int((timeInterval.truncatingRemainder(dividingBy: 24 * 60 * 60)) / (60 * 60))
            
            if days > 0 {
                return "\(days)일 \(hours)시간 남음"
            } else if hours > 0 {
                return "\(hours)시간 남음"
            } else {
                return "곧 마감"
            }
        }
    }
}

// MARK: - CompanyJobInfoCard
struct CompanyJobInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(colorScheme == .dark ? 0.3 : 0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - CompanySkillTags
struct CompanySkillTags: View {
    let skills: [String]
    @Environment(\.colorScheme) var colorScheme
    
    private var skillColors: [Color] {
        [.blue, .green, .purple, .orange, .pink, .indigo]
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 100), spacing: 12)
        ], spacing: 12) {
            ForEach(Array(skills.enumerated()), id: \.offset) { index, skill in
                let trimmedSkill = skill.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedSkill.isEmpty {
                    CompanySkillTag(
                        skill: trimmedSkill,
                        color: skillColors[index % skillColors.count]
                    )
                }
            }
        }
    }
}

struct CompanySkillTag: View {
    let skill: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(skill.hasPrefix("#") ? skill : "#\(skill)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(color.opacity(colorScheme == .dark ? 0.15 : 0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
