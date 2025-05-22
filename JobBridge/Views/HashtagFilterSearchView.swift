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

// MARK: - Clean Hashtag Category Model

struct CleanHashtagCategory {
    let id = UUID()
    let title: String
    let hashtags: [String]
}

// MARK: - Clean Main View

struct HashtagFilterSearchView: View {
    @StateObject private var viewModel = JobSearchViewModel()
    @State private var selectedHashtags: Set<String> = []
    @State private var selectedLocation = ""
    @State private var selectedExperience = ""
    @State private var searchText = ""
    @State private var showingFilters = false
    
    let preselectedHashtag: String?
    
    // 간단하고 깔끔한 카테고리 구성
    private let hashtagCategories = [
        CleanHashtagCategory(
            title: "프로그래밍 언어",
            hashtags: ["#JavaScript", "#Python", "#Java", "#TypeScript", "#Swift", "#Kotlin", "#Go", "#Rust"]
        ),
        CleanHashtagCategory(
            title: "프레임워크",
            hashtags: ["#React", "#Vue", "#Angular", "#Spring", "#Django", "#Express", "#Flutter", "#SwiftUI"]
        ),
        CleanHashtagCategory(
            title: "AI & 데이터",
            hashtags: ["#AI", "#머신러닝", "#데이터분석", "#빅데이터", "#TensorFlow", "#PyTorch", "#SQL", "#Pandas"]
        ),
        CleanHashtagCategory(
            title: "클라우드 & DevOps",
            hashtags: ["#AWS", "#Azure", "#GCP", "#Docker", "#Kubernetes", "#CI/CD", "#DevOps", "#Terraform"]
        ),
        CleanHashtagCategory(
            title: "모바일",
            hashtags: ["#iOS", "#Android", "#Flutter", "#ReactNative", "#SwiftUI", "#UIKit", "#Jetpack", "#Compose"]
        ),
        CleanHashtagCategory(
            title: "기타",
            hashtags: ["#프론트엔드", "#백엔드", "#풀스택", "#UI/UX", "#블록체인", "#보안", "#게임개발", "#IoT"]
        )
    ]
    
    private let locations = ["서울", "경기", "인천", "부산", "대구", "대전", "광주", "울산", "세종", "제주", "전국"]
    private let experienceLevels = ["신입", "1-3년", "3-5년", "5-10년", "10년+"]
    
    init() {
        self.preselectedHashtag = nil
    }
    
    init(preselectedHashtag: String) {
        self.preselectedHashtag = preselectedHashtag
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 검색 영역
            searchSection
            
            // 선택된 필터 표시
            if hasActiveFilters {
                selectedFiltersSection
            }
            
            // 메인 컨텐츠
            if viewModel.hasSearched && !viewModel.searchResults.isEmpty {
                // 검색 결과가 있을 때
                searchResultsList
            } else if viewModel.hasSearched && viewModel.searchResults.isEmpty {
                // 검색 결과가 없을 때
                noResultsView
            } else {
                // 검색 전 상태 - 카테고리 표시
                hashtagCategoriesView
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("해시태그 검색")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            setupInitialState()
        }
    }
    
    // MARK: - UI Sections
    
    private var searchSection: some View {
        VStack(spacing: 16) {
            // 검색바
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("기술, 회사, 직무 검색", text: $searchText)
                        .onSubmit { performTextSearch() }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(8)
                
                // 필터 버튼
                Button(action: { showingFilters.toggle() }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(AppTheme.primary)
                        .padding(12)
                        .background(showingFilters ? AppTheme.primary.opacity(0.1) : Color(.systemBackground))
                        .cornerRadius(8)
                }
            }
            
            // 필터 옵션 (토글 가능)
            if showingFilters {
                VStack(spacing: 12) {
                    filterRow(title: "지역", items: locations, selected: $selectedLocation)
                    filterRow(title: "경력", items: experienceLevels, selected: $selectedExperience)
                }
                .transition(.slide)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
    }
    
    private var selectedFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(selectedHashtags), id: \.self) { hashtag in
                    selectedFilterChip(text: hashtag, onRemove: { removeHashtag(hashtag) })
                }
                
                if !selectedLocation.isEmpty {
                    selectedFilterChip(text: selectedLocation, onRemove: {
                        selectedLocation = ""
                        performSearch()
                    })
                }
                
                if !selectedExperience.isEmpty {
                    selectedFilterChip(text: selectedExperience, onRemove: {
                        selectedExperience = ""
                        performSearch()
                    })
                }
                
                Button("전체 삭제") {
                    clearAllFilters()
                }
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(16)
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private var hashtagCategoriesView: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(hashtagCategories, id: \.id) { category in
                    categorySection(category)
                }
            }
            .padding(16)
        }
    }
    
    private var searchResultsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 결과 헤더
            HStack {
                Text("검색 결과")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.searchResults.count)건")
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            
            // 결과 목록
            List(viewModel.searchResults) { job in
                NavigationLink(destination: JobDetailView(job: job)) {
                    cleanJobRow(job: job)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
            .listStyle(PlainListStyle())
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("검색 결과가 없습니다")
                .font(.headline)
            
            Text("다른 키워드나 필터를 시도해보세요")
                .foregroundColor(.secondary)
            
            Button("필터 초기화") {
                clearAllFilters()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppTheme.primary)
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Helper Views
    
    private func filterRow(title: String, items: [String], selected: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        Button(item) {
                            selected.wrappedValue = selected.wrappedValue == item ? "" : item
                            performSearch()
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selected.wrappedValue == item ? AppTheme.primary : Color(.systemGray6))
                        .foregroundColor(selected.wrappedValue == item ? .white : .primary)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func categorySection(_ category: CleanHashtagCategory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                let selectedCount = selectedHashtags.intersection(Set(category.hashtags)).count
                if selectedCount > 0 {
                    Text("\(selectedCount)개 선택")
                        .font(.caption)
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.primary.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            FlowLayout(spacing: 8) {
                ForEach(category.hashtags, id: \.self) { hashtag in
                    hashtagButton(hashtag: hashtag)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func hashtagButton(hashtag: String) -> some View {
        Button(hashtag) {
            toggleHashtag(hashtag)
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(selectedHashtags.contains(hashtag) ? AppTheme.primary : Color(.systemGray6))
        .foregroundColor(selectedHashtags.contains(hashtag) ? .white : .primary)
        .cornerRadius(8)
    }
    
    private func selectedFilterChip(text: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.primary)
        .foregroundColor(.white)
        .cornerRadius(16)
    }
    
    private func cleanJobRow(job: JobPostingResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 제목과 회사
            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(job.companyName ?? "기업명 없음")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.primary)
            }
            
            // 기본 정보
            HStack {
                Label(job.location, systemImage: "location")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label(job.experienceLevel, systemImage: "briefcase")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(job.createdAt.toShortDate())
                    .font(.caption)
                    .foregroundColor(.secondary)
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
        .padding(.vertical, 4)
    }
    
    // MARK: - Computed Properties
    
    private var hasActiveFilters: Bool {
        !selectedHashtags.isEmpty || !selectedLocation.isEmpty || !selectedExperience.isEmpty
    }
    
    // MARK: - Methods
    
    private func setupInitialState() {
        if let preselected = preselectedHashtag {
            selectedHashtags.insert(preselected)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                performSearch()
            }
        } else {
            viewModel.loadRecentJobs()
        }
    }
    
    private func toggleHashtag(_ hashtag: String) {
        if selectedHashtags.contains(hashtag) {
            selectedHashtags.remove(hashtag)
        } else {
            selectedHashtags.insert(hashtag)
        }
        performSearch()
    }
    
    private func removeHashtag(_ hashtag: String) {
        selectedHashtags.remove(hashtag)
        performSearch()
    }
    
    private func clearAllFilters() {
        selectedHashtags.removeAll()
        selectedLocation = ""
        selectedExperience = ""
        searchText = ""
        viewModel.clearSearch()
        viewModel.loadRecentJobs()
    }
    
    private func performTextSearch() {
        if !searchText.isEmpty {
            let searchRequest = JobSearchRequest(
                keyword: searchText,
                location: selectedLocation.isEmpty ? nil : selectedLocation,
                experienceLevel: selectedExperience.isEmpty ? nil : selectedExperience,
                activeOnly: true
            )
            viewModel.searchJobs(request: searchRequest)
        }
    }
    
    private func performSearch() {
        if selectedHashtags.isEmpty && selectedLocation.isEmpty && selectedExperience.isEmpty {
            viewModel.clearSearch()
            viewModel.loadRecentJobs()
        } else {
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

struct HashtagFilterSearchView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HashtagFilterSearchView()
        }
    }
}
