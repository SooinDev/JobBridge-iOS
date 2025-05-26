// CompanyJobStatsView.swift
import SwiftUI

struct CompanyJobStatsView: View {
    let totalJobs: Int
    let activeJobs: Int
    let totalApplications: Int
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "총 공고",
                value: "\(totalJobs)",
                icon: "briefcase.fill",
                color: .blue
            )
            
            StatCard(
                title: "진행중",
                value: "\(activeJobs)",
                icon: "clock.fill",
                color: .green
            )
            
            StatCard(
                title: "지원자",
                value: "\(totalApplications)",
                icon: "person.3.fill",
                color: .orange
            )
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.secondaryBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - CompanyJobRow
struct CompanyJobRow: View {
    let job: JobPostingResponse
    
    private var statusInfo: (text: String, color: Color) {
        guard let deadline = job.deadline else {
            return ("상시채용", .blue)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        guard let deadlineDate = formatter.date(from: deadline) else {
            return ("상시채용", .blue)
        }
        
        if deadlineDate < Date() {
            return ("마감", .red)
        } else {
            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: deadlineDate).day ?? 0
            if daysLeft <= 3 {
                return ("D-\(daysLeft)", .orange)
            } else {
                return ("진행중", .green)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 제목과 상태
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(job.title)
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                        .lineLimit(2)
                    
                    Text(job.position)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                
                Spacer()
                
                // 상태 배지
                Text(statusInfo.text)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusInfo.color.opacity(0.2))
                    .foregroundColor(statusInfo.color)
                    .cornerRadius(8)
            }
            
            // 기본 정보
            HStack(spacing: 16) {
                InfoTag(icon: "location", text: job.location)
                InfoTag(icon: "dollarsign.circle", text: job.salary)
                
                Spacer()
                
                Text("등록: \(job.createdAt.toShortDate())")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            
            // 마감일
            if let deadline = job.deadline {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("마감: \(deadline.toFormattedDate())")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
            
            // 스킬 태그
            if !job.requiredSkills.isEmpty {
                let skills = job.requiredSkills.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .prefix(3)
                
                HStack {
                    ForEach(Array(skills), id: \.self) { skill in
                        Text(skill.hasPrefix("#") ? skill : "#\(skill)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary.opacity(0.1))
                            .foregroundColor(AppTheme.primary)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }
}
