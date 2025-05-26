// CompanyResumeMatchingCard.swift - 기업용 매칭 이력서 카드 컴포넌트
import SwiftUI

struct CompanyResumeMatchingCard: View {
    let resume: CompanyMatchingResumeResponse
    let rank: Int
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    private var rankColor: Color {
        switch rank {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4...5: return .green
        default: return .blue
        }
    }
    
    private var matchRateColor: Color {
        switch resume.matchRateColor {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        default: return .gray
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "star.fill"
        default: return "trophy.fill"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // 상단: 순위와 매칭률
                HStack {
                    // 순위 배지
                    HStack(spacing: 6) {
                        Image(systemName: rankIcon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(rankColor)
                        
                        Text("#\(rank)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(rankColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(rankColor.opacity(0.15))
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    // 매칭률
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(matchRateColor)
                        
                        Text("\(resume.matchRatePercentage)%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(matchRateColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(matchRateColor.opacity(0.15))
                    .cornerRadius(20)
                }
                
                // 중간: 이력서 정보
                VStack(alignment: .leading, spacing: 12) {
                    // 제목과 지원자명
                    VStack(alignment: .leading, spacing: 4) {
                        Text(resume.title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .lineLimit(2)
                        
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                            
                            Text(resume.userName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // 이력서 내용 미리보기
                    Text(String(resume.content.prefix(100)) + (resume.content.count > 100 ? "..." : ""))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .lineSpacing(2)
                }
                
                // 하단: 추가 정보
                VStack(spacing: 8) {
                    HStack {
                        CompanyResumeInfoChip(
                            icon: "calendar",
                            text: resume.formattedCreatedDate,
                            color: .purple
                        )
                        
                        CompanyResumeInfoChip(
                            icon: "doc.text",
                            text: resume.matchRateDescription,
                            color: matchRateColor
                        )
                        
                        Spacer()
                    }
                    
                    // AI 매칭 태그
                    HStack {
                        Label("AI 추천", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        Label("상세보기", systemImage: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(20)
            .background(
                colorScheme == .dark ?
                Color(UIColor.secondarySystemBackground) :
                Color.white
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                rankColor.opacity(0.5),
                                matchRateColor.opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(
                color: rankColor.opacity(0.2),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - 정보 칩 컴포넌트
struct CompanyResumeInfoChip: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - 간단한 카드 버전 (리스트용)
struct CompanyResumeSimpleCard: View {
    let resume: CompanyMatchingResumeResponse
    let rank: Int
    @Environment(\.colorScheme) var colorScheme
    
    private var matchRateColor: Color {
        switch resume.matchRateColor {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 순위 표시
            ZStack {
                Circle()
                    .fill(matchRateColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(matchRateColor)
            }
            
            // 이력서 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(resume.title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(1)
                
                Text(resume.userName)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                Text(resume.formattedCreatedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 매칭률
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(resume.matchRatePercentage)%")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(matchRateColor)
                
                Text(resume.matchRateDescription)
                    .font(.caption)
                    .foregroundColor(matchRateColor)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 그리드용 컴팩트 카드
struct CompanyResumeCompactCard: View {
    let resume: CompanyMatchingResumeResponse
    let rank: Int
    @Environment(\.colorScheme) var colorScheme
    
    private var matchRateColor: Color {
        switch resume.matchRateColor {
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "blue": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // 상단: 순위와 매칭률
            HStack {
                Text("#\(rank)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(matchRateColor)
                    .cornerRadius(8)
                
                Spacer()
                
                Text("\(resume.matchRatePercentage)%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(matchRateColor)
            }
            
            // 중간: 이력서 정보
            VStack(alignment: .leading, spacing: 6) {
                Text(resume.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(resume.userName)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 하단: 매칭 설명
            HStack {
                Text(resume.matchRateDescription)
                    .font(.caption2)
                    .foregroundColor(matchRateColor)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundColor(.purple)
            }
        }
        .padding(16)
        .background(
            colorScheme == .dark ?
            Color(UIColor.secondarySystemBackground) :
            Color.white
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(matchRateColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - 프리뷰
struct CompanyResumeMatchingCard_Previews: PreviewProvider {
    static var previews: some View {
        let mockResume = CompanyMatchingResumeResponse(
            id: 1,
            title: "3년차 iOS 개발자 이력서",
            content: "Swift, SwiftUI, UIKit을 활용한 iOS 앱 개발 경험 3년. MVVM 패턴과 Combine을 활용한 반응형 프로그래밍에 익숙하며, 다수의 앱스토어 출시 경험 보유.",
            userName: "김개발",
            createdAt: "2024-01-15T10:30:00",
            updatedAt: "2024-01-15T10:30:00",
            matchRate: 0.92
        )
        
        Group {
            VStack(spacing: 20) {
                CompanyResumeMatchingCard(resume: mockResume, rank: 1) {}
                CompanyResumeSimpleCard(resume: mockResume, rank: 1)
                CompanyResumeCompactCard(resume: mockResume, rank: 1)
            }
            .padding()
            .previewDisplayName("Light Mode")
            
            VStack(spacing: 20) {
                CompanyResumeMatchingCard(resume: mockResume, rank: 1) {}
                CompanyResumeSimpleCard(resume: mockResume, rank: 1)
                CompanyResumeCompactCard(resume: mockResume, rank: 1)
            }
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
