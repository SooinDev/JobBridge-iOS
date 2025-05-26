// EmptyCompanyJobsView.swift
import SwiftUI

struct EmptyCompanyJobsView: View {
    let filter: CompanyJobManagementView.JobFilter
    let onCreateAction: () -> Void
    
    private var emptyMessage: (icon: String, title: String, message: String) {
        switch filter {
        case .all:
            return (
                "briefcase.badge.plus",
                "등록된 채용공고가 없습니다",
                "첫 채용공고를 등록하고 우수한 인재를 찾아보세요"
            )
        case .active:
            return (
                "clock.badge.exclamationmark",
                "진행중인 채용공고가 없습니다",
                "새로운 채용공고를 등록하거나 기존 공고의 마감일을 확인해보세요"
            )
        case .expired:
            return (
                "calendar.badge.minus",
                "마감된 채용공고가 없습니다",
                "아직 마감된 채용공고가 없습니다"
            )
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: emptyMessage.icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(emptyMessage.title)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(emptyMessage.message)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if filter == .all || filter == .active {
                Button(action: onCreateAction) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("채용공고 등록하기")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.primary)
                    .cornerRadius(25)
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
