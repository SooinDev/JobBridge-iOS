import SwiftUI

// MARK: - Flow Layout

struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            ), proposal: ProposedViewSize(result.sizes[index]))
        }
    }
}

struct InfoTag: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(12)
    }
}

struct FlowResult {
    let size: CGSize
    let positions: [CGPoint]
    let sizes: [CGSize]
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var sizes: [CGSize] = []
        var positions: [CGPoint] = []
        
        var currentRowHeight: CGFloat = 0
        var currentRowWidth: CGFloat = 0
        var currentRowY: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)
            
            if currentRowWidth + size.width > maxWidth && !positions.isEmpty {
                // 새 줄 시작
                currentRowY += currentRowHeight + spacing
                currentRowWidth = 0
                currentRowHeight = 0
            }
            
            positions.append(CGPoint(x: currentRowWidth, y: currentRowY))
            currentRowWidth += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        
        self.sizes = sizes
        self.positions = positions
        self.size = CGSize(
            width: maxWidth,
            height: currentRowY + currentRowHeight
        )
    }
}

// MARK: - Hashtag Category Model

struct HashtagCategory {
    let title: String
    let hashtags: [String]
}

// MARK: - Main View

struct HashtagFilterSearchView: View {
    @StateObject private var viewModel = JobSearchViewModel()
    @State private var selectedHashtags: Set<String> = []
    @State private var selectedLocation = ""
    @State private var selectedExperience = ""
    @State private var showingAdvancedFilters = false
    
    // 사전 선택된 해시태그 지원
    let preselectedHashtag: String?
    
    // 해시태그 카테고리별 분류
    private let hashtagCategories = [
        HashtagCategory(
            title: "프로그래밍 언어",
            hashtags: ["#자바", "#Python", "#JavaScript", "#TypeScript", "#C++", "#C#", "#Swift", "#Kotlin", "#Go", "#Rust"]
        ),
        HashtagCategory(
            title: "프레임워크",
            hashtags: ["#Spring", "#Django", "#React", "#Vue", "#Angular", "#Express", "#Flutter", "#SwiftUI", "#UIKit", "#RxSwift"]
        ),
        HashtagCategory(
            title: "개발 분야",
            hashtags: ["#백엔드", "#프론트엔드", "#풀스택", "#모바일", "#웹개발", "#앱개발", "#게임개발", "#시스템개발"]
        ),
        HashtagCategory(
            title: "기술 영역",
            hashtags: ["#AI", "#머신러닝", "#데이터분석", "#블록체인", "#클라우드", "#DevOps", "#보안", "#IoT"]
        ),
        HashtagCategory(
            title: "데이터베이스",
            hashtags: ["#MySQL", "#PostgreSQL", "#MongoDB", "#Redis", "#Oracle", "#SQLServer", "#Elasticsearch"]
        ),
        HashtagCategory(
            title: "직무",
            hashtags: ["#개발자", "#엔지니어", "#아키텍트", "#팀리드", "#CTO", "#테크리드", "#시니어개발자", "#주니어개발자"]
        )
    ]
    
    // 지역 및 경험 옵션
    private let locations = ["서울", "경기", "인천", "부산", "대구", "대전", "광주", "울산", "세종", "제주", "전국"]
    private let experienceLevels = ["신입", "경력 1-3년", "경력 3-5년", "경력 5년 이상", "시니어"]
    
    // 기본 생성자
    init() {
        self.preselectedHashtag = nil
    }
    
    // 사전 선택된 해시태그가 있는 생성자
    init(preselectedHashtag: String) {
        self.preselectedHashtag = preselectedHashtag
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 선택된 해시태그 표시
            if !selectedHashtags.isEmpty {
                SelectedHashtagsView(
                    selectedHashtags: Array(selectedHashtags),
                    onRemove: { hashtag in
                        selectedHashtags.remove(hashtag)
                        performSearch()
                    },
                    onClear: {
                        selectedHashtags.removeAll()
                        viewModel.clearSearch()
                        viewModel.loadRecentJobs()
                    }
                )
                .padding()
                .background(AppTheme.secondaryBackground)
                
                Divider()
            }
            
            // 해시태그 카테고리 및 필터
            ScrollView {
                VStack(spacing: 20) {
                    // 고급 필터 토글
                    HStack {
                        Text("필터")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                showingAdvancedFilters.toggle()
                            }
                        }) {
                            HStack {
                                Text(showingAdvancedFilters ? "간단히" : "상세 필터")
                                Image(systemName: showingAdvancedFilters ? "chevron.up" : "chevron.down")
                            }
                            .font(.caption)
                            .foregroundColor(AppTheme.primary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 고급 필터 (지역, 경험)
                    if showingAdvancedFilters {
                        VStack(spacing: 16) {
                            // 지역 필터
                            VStack(alignment: .leading, spacing: 8) {
                                Text("지역")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(locations, id: \.self) { location in
                                            FilterButton(
                                                text: location,
                                                isSelected: selectedLocation == location,
                                                onTap: {
                                                    selectedLocation = selectedLocation == location ? "" : location
                                                    performSearch()
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // 경험 수준 필터
                            VStack(alignment: .leading, spacing: 8) {
                                Text("경험 수준")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(experienceLevels, id: \.self) { level in
                                            FilterButton(
                                                text: level,
                                                isSelected: selectedExperience == level,
                                                onTap: {
                                                    selectedExperience = selectedExperience == level ? "" : level
                                                    performSearch()
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                        .background(AppTheme.background)
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // 해시태그 카테고리
                    ForEach(hashtagCategories, id: \.title) { category in
                        HashtagCategoryView(
                            category: category,
                            selectedHashtags: selectedHashtags,
                            onHashtagTap: { hashtag in
                                toggleHashtag(hashtag)
                            }
                        )
                    }
                }
            }
            
            Divider()
            
            // 검색 결과
            SearchResultsSection(viewModel: viewModel)
        }
        .navigationTitle("해시태그 검색")
        .onAppear {
            // 사전 선택된 해시태그가 있으면 자동 선택 및 검색
            if let preselected = preselectedHashtag {
                selectedHashtags.insert(preselected)
                // 약간의 지연 후 검색 실행
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    performSearch()
                }
            } else {
                viewModel.loadRecentJobs()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleHashtag(_ hashtag: String) {
        if selectedHashtags.contains(hashtag) {
            selectedHashtags.remove(hashtag)
        } else {
            selectedHashtags.insert(hashtag)
        }
        
        performSearch()
    }
    
    private func performSearch() {
        if selectedHashtags.isEmpty && selectedLocation.isEmpty && selectedExperience.isEmpty {
            // 필터가 모두 비어있으면 최근 공고 표시
            viewModel.clearSearch()
            viewModel.loadRecentJobs()
        } else {
            // 선택된 해시태그들을 검색어로 변환
            let searchKeyword = selectedHashtags.isEmpty ? nil : Array(selectedHashtags).joined(separator: " ")
            
            let searchRequest = JobSearchRequest(
                keyword: searchKeyword,
                location: selectedLocation.isEmpty ? nil : selectedLocation,
                experienceLevel: selectedExperience.isEmpty ? nil : selectedExperience,
                activeOnly: true
            )
            
            viewModel.searchJobs(request: searchRequest)
        }
    }
}

// MARK: - Selected Hashtags View

struct SelectedHashtagsView: View {
    let selectedHashtags: [String]
    let onRemove: (String) -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("선택된 해시태그 (\(selectedHashtags.count))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("전체 삭제", action: onClear)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // 선택된 해시태그들을 FlowLayout으로 표시
            FlowLayout(spacing: 8) {
                ForEach(selectedHashtags, id: \.self) { hashtag in
                    SelectedHashtagChip(
                        hashtag: hashtag,
                        onRemove: { onRemove(hashtag) }
                    )
                }
            }
        }
    }
}

// MARK: - Selected Hashtag Chip

struct SelectedHashtagChip: View {
    let hashtag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(hashtag)
                .font(.caption)
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(AppTheme.primary)
        .cornerRadius(16)
        .shadow(color: AppTheme.primary.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Hashtag Category View

struct HashtagCategoryView: View {
    let category: HashtagCategory
    let selectedHashtags: Set<String>
    let onHashtagTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.title)
                    .font(.headline)
                    .padding(.horizontal)
                
                Spacer()
                
                // 카테고리별 선택된 개수 표시
                if !selectedInCategory.isEmpty {
                    Text("\(selectedInCategory.count)개 선택")
                        .font(.caption)
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.primary.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }
            
            // 해시태그 버튼들
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(category.hashtags, id: \.self) { hashtag in
                    HashtagButton(
                        hashtag: hashtag,
                        isSelected: selectedHashtags.contains(hashtag),
                        onTap: { onHashtagTap(hashtag) }
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .background(AppTheme.secondaryBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var selectedInCategory: Set<String> {
        selectedHashtags.intersection(Set(category.hashtags))
    }
}

// MARK: - Hashtag Button

struct HashtagButton: View {
    let hashtag: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(hashtag)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(isSelected ? AppTheme.primary : AppTheme.background)
                .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? AppTheme.primary : Color.gray.opacity(0.3),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Filter Button

struct FilterButton: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.primary : AppTheme.background)
                .foregroundColor(isSelected ? .white : AppTheme.textPrimary)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? AppTheme.primary : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

// MARK: - Search Results Section

struct SearchResultsSection: View {
    @ObservedObject var viewModel: JobSearchViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    LoadingView(message: "검색 중...")
                    Spacer()
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Spacer()
                    ErrorView(
                        message: errorMessage,
                        retryAction: { viewModel.loadRecentJobs() }
                    )
                    Spacer()
                }
            } else if viewModel.searchResults.isEmpty && !viewModel.hasSearched {
                // 검색 전 상태 - 최근 공고 표시
                RecentJobsList(jobs: viewModel.recentJobs)
            } else if viewModel.searchResults.isEmpty && viewModel.hasSearched {
                VStack {
                    Spacer()
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "검색 결과 없음",
                        message: "선택한 해시태그와 일치하는 채용공고가 없습니다.\n다른 해시태그를 선택해보세요.",
                        buttonTitle: "전체 공고 보기",
                        buttonAction: {
                            viewModel.clearSearch()
                            viewModel.loadRecentJobs()
                        }
                    )
                    Spacer()
                }
            } else {
                // 검색 결과 표시
                JobResultsList(jobs: viewModel.searchResults)
            }
        }
    }
}

// MARK: - Job Results List

struct JobResultsList: View {
    let jobs: [JobPostingResponse]
    
    var body: some View {
        List {
            Section(header:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("검색 결과")
                    Spacer()
                    Text("\(jobs.count)건")
                        .foregroundColor(.gray)
                }
            ) {
                ForEach(jobs) { job in
                    NavigationLink(destination: JobDetailView(job: job)) {
                        CompactJobRow(job: job)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

// MARK: - Recent Jobs List

struct RecentJobsList: View {
    let jobs: [JobPostingResponse]
    
    var body: some View {
        if jobs.isEmpty {
            VStack {
                Spacer()
                EmptyStateView(
                    icon: "briefcase",
                    title: "채용공고 없음",
                    message: "해시태그를 선택하여 원하는 채용공고를 찾아보세요.",
                    buttonTitle: nil,
                    buttonAction: nil
                )
                Spacer()
            }
        } else {
            List {
                Section(header:
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("최근 채용공고")
                        Spacer()
                        Text("\(jobs.count)건")
                            .foregroundColor(.gray)
                    }
                ) {
                    ForEach(jobs) { job in
                        NavigationLink(destination: JobDetailView(job: job)) {
                            CompactJobRow(job: job)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}

// MARK: - Compact Job Row

struct CompactJobRow: View {
    let job: JobPostingResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 제목과 회사
            VStack(alignment: .leading, spacing: 2) {
                Text(job.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(job.companyName ?? "기업명 없음")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.primary)
            }
            
            // 기본 정보
            HStack {
                InfoTag(icon: "mappin", text: job.location, color: .blue)
                InfoTag(icon: "person.fill", text: job.experienceLevel, color: .green)
                
                Spacer()
                
                Text(job.createdAt.toShortDate())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // 스킬 태그 (최대 4개)
            if !job.requiredSkills.isEmpty {
                let skills = job.requiredSkills.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .prefix(4)
                
                HStack {
                    ForEach(Array(skills), id: \.self) { skill in
                        Text(skill.hasPrefix("#") ? skill : "#\(skill)")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primary.opacity(0.1))
                            .foregroundColor(AppTheme.primary)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct HashtagFilterSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HashtagFilterSearchView()
        }
    }
}
