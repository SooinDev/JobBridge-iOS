// AllMatchedResumesView.swift - 매칭된 이력서 전체 목록 화면
import SwiftUI

struct AllMatchedResumesView: View {
    let resumes: [ResumeMatchResponse]
    let jobPosting: JobPostingResponse
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedSortOption: SortOption = .matchRate
    @State private var showingSortOptions = false
    @State private var searchText = ""
    
    enum SortOption: String, CaseIterable {
        case matchRate = "매칭률 순"
        case createdDate = "작성일 순"
        case name = "이름 순"
        
        var systemImage: String {
            switch self {
            case .matchRate: return "heart.fill"
            case .createdDate: return "calendar"
            case .name: return "person.fill"
            }
        }
    }
    
    var sortedAndFilteredResumes: [ResumeMatchResponse] {
        let filtered = searchText.isEmpty ? resumes : resumes.filter { resume in
            resume.title.localizedCaseInsensitiveContains(searchText) ||
            resume.userName.localizedCaseInsensitiveContains(searchText) ||
            resume.content.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedSortOption {
        case .matchRate:
            return filtered.sorted { $0.matchRate > $1.matchRate }
        case .createdDate:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .name:
            return filtered.sorted { $0.userName < $1.userName }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 헤더 정보
                AllMatchedResumesHeaderView(
                    jobPosting: jobPosting,
                    resumes: resumes,
                    totalCount: resumes.count,
                    filteredCount: sortedAndFilteredResumes.count
                )
                .padding()
                .background(AppTheme.secondaryBackground)
                
                // 검색 및 정렬
                VStack(spacing: 12) {
                    // 검색바
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("이름, 제목, 내용으로 검색", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                    
                    // 정렬 옵션
                    HStack {
                        Text("정렬:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Menu {
                            ForEach(SortOption.allCases, id: \.self) { option in
                                Button(action: {
                                    selectedSortOption = option
                                }) {
                                    HStack {
                                        Image(systemName: option.systemImage)
                                        Text(option.rawValue)
                                        
                                        if selectedSortOption == option {
                                            Spacer()
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: selectedSortOption.systemImage)
                                    .font(.caption)
                                Text(selectedSortOption.rawValue)
                                    .font(.subheadline)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Spacer()
                        
                        Text("\(sortedAndFilteredResumes.count)개 결과")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                // 이력서 목록
                if sortedAndFilteredResumes.isEmpty {
                    EmptySearchResultView(searchText: searchText)
                } else {
                    List {
                        ForEach(Array(sortedAndFilteredResumes.enumerated()), id: \.element.id) { index, resume in
                            NavigationLink(
                                destination: CompanyResumeDetailView(
                                    resume: CompanyMatchingResumeResponse(
                                        id: resume.id,
                                        title: resume.title,
                                        content: resume.content,
                                        userName: resume.userName,
                                        createdAt: resume.createdAt,
                                        updatedAt: resume.updatedAt,
                                        matchRate: resume.matchRate
                                    ),
                                    jobPosting: jobPosting
                                )
                            ) {
                                AllMatchedResumeRow(
                                    resume: resume,
                                    rank: getRankForResume(resume),
                                    searchText: searchText
                                )
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("매칭 결과")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("닫기") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Menu {
                    Button(action: {
                        // TODO: 결과 내보내기
                    }) {
                        Label("결과 내보내기", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: {
                        // TODO: 즐겨찾기 추가
                    }) {
                        Label("관심 인재 추가", systemImage: "heart")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            )
        }
    }
    
    private func getRankForResume(_ resume: ResumeMatchResponse) -> Int {
        return (resumes.sorted { $0.matchRate > $1.matchRate }.firstIndex { $0.id == resume.id } ?? 0) + 1
    }
}

// MARK: - 헤더 뷰
struct AllMatchedResumesHeaderView: View {
    let jobPosting: JobPostingResponse
    let resumes: [ResumeMatchResponse]
    let totalCount: Int
    let filteredCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 채용공고 정보
            VStack(alignment: .leading, spacing: 8) {
                Text("매칭 대상 채용공고")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(jobPosting.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                
                HStack {
                    InfoTag(icon: "location.fill", text: jobPosting.location)
                    InfoTag(icon: "briefcase.fill", text: jobPosting.experienceLevel)
                    
                    Spacer()
                }
            }
            
            // 매칭 통계
            HStack(spacing: 20) {
                MatchingStatItem(
                    title: "총 매칭",
                    value: "\(totalCount)명",
                    icon: "person.3.fill",
                    color: .blue
                )
                
                MatchingStatItem(
                    title: "높은 적합도",
                    value: "\(totalCount > 0 ? resumes.filter { $0.matchRate >= 0.8 }.count : 0)명",
                    icon: "star.fill",
                    color: .green
                )
                
                MatchingStatItem(
                    title: "평균 매칭률",
                    value: totalCount > 0 ? "\(Int(resumes.map { $0.matchRate }.reduce(0, +) / Double(totalCount) * 100))%" : "0%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
            }
        }
    }
}

struct MatchingStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - 이력서 행
struct AllMatchedResumeRow: View {
    let resume: ResumeMatchResponse
    let rank: Int
    let searchText: String
    @Environment(\.colorScheme) var colorScheme
    
    private var rankColor: Color {
        switch rank {
        case 1...3: return .red
        case 4...10: return .orange
        case 11...20: return .blue
        default: return .gray
        }
    }
    
    private var matchRateColor: Color {
        if resume.matchRate >= 0.9 { return .red }
        else if resume.matchRate >= 0.8 { return .green }
        else if resume.matchRate >= 0.7 { return .orange }
        else if resume.matchRate >= 0.6 { return .blue }
        else { return .gray }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 상단: 순위, 제목, 매칭률
            HStack {
                // 순위 배지
                ZStack {
                    Circle()
                        .fill(rankColor)
                        .frame(width: 36, height: 36)
                    
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    // 제목 (검색어 하이라이트)
                    Text(resume.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    .lineLimit(2)
                    
                    // 작성자 (검색어 하이라이트)
                    HStack(spacing: 6) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text(resume.userName)
                            .font(.caption)
                            .fontWeight(.medium)
                        .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // 매칭률
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(matchRateColor)
                        
                        Text("\(resume.matchRatePercentage)%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(matchRateColor)
                    }
                    
                    Text(resume.matchRateDescription)
                        .font(.caption2)
                        .foregroundColor(matchRateColor)
                }
            }
            
            // 중간: 이력서 내용 미리보기 (검색어 하이라이트)
            VStack(alignment: .leading, spacing: 8) {
                Text("이력서 내용")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(resume.content.prefix(150)) + (resume.content.count > 150 ? "..." : ""))
                    .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .lineSpacing(2)
            }
            
            // 하단: 추가 정보
            HStack {
                HStack(spacing: 12) {
                    InfoTag(icon: "calendar", text: resume.formattedCreatedDate)
                    
                    if let skills = extractSkills(from: resume.content) {
                        InfoTag(icon: "gear", text: skills)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    
                    Text("상세보기")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
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
                .stroke(rankColor.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func extractSkills(from content: String) -> String? {
        let keywords = ["Swift", "iOS", "Android", "React", "Python", "Java", "JavaScript", "SwiftUI", "UIKit", "Kotlin"]
        let foundKeywords = keywords.filter { content.contains($0) }
        return foundKeywords.isEmpty ? nil : foundKeywords.prefix(3).joined(separator: ", ")
    }
}

// MARK: - 빈 검색 결과 뷰
struct EmptySearchResultView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                if searchText.isEmpty {
                    Text("매칭된 이력서가 없습니다")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("다른 채용공고로 다시 시도해보세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("'\(searchText)' 검색 결과가 없습니다")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("다른 키워드로 검색해보세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if !searchText.isEmpty {
                Button("검색어 지우기") {
                    // searchText를 여기서 직접 변경할 수 없으므로
                    // 상위 뷰에서 처리해야 함
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
