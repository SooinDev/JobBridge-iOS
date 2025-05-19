import SwiftUI

struct ResumesView: View {
    @ObservedObject var viewModel: ResumeViewModel
    @State private var showAddResume = false
    @State private var isRefreshing = false
    
    var body: some View {
        ZStack {
            // 배경
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // 컨텐츠
            if viewModel.isLoading && viewModel.resumes.isEmpty {
                // 로딩 중
                ProgressView("이력서를 불러오는 중...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else if let errorMessage = viewModel.errorMessage, viewModel.resumes.isEmpty {
                // 오류 발생
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("이력서를 불러올 수 없습니다")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        viewModel.loadResumes()
                    }) {
                        Text("다시 시도")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding()
            } else if viewModel.resumes.isEmpty {
                // 데이터 없음
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("등록된 이력서가 없습니다")
                        .font(.headline)
                    
                    Text("새 이력서를 작성하고 맞춤 채용공고를 추천받아보세요")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button(action: {
                        showAddResume = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("이력서 작성하기")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }
                .padding()
            } else {
                // 이력서 목록
                List {
                    ForEach(viewModel.resumes) { resume in
                        NavigationLink(destination: ResumeDetailView(resume: resume)) {
                            ResumeRow(resume: resume)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    isRefreshing = true
                    viewModel.loadResumes()
                    isRefreshing = false
                }
            }
        }
        .navigationTitle("내 이력서")
        .navigationBarItems(trailing: Button(action: {
            showAddResume = true
        }) {
            Image(systemName: "plus")
        })
        .sheet(isPresented: $showAddResume) {
            AddResumeView(viewModel: viewModel)
        }
        .onAppear {
            if viewModel.resumes.isEmpty {
                viewModel.loadResumes()
            }
        }
    }
}

struct ResumeRow: View {
    let resume: ResumeResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resume.title)
                .font(.headline)
            
            HStack {
                Text("작성일: \(formatDate(resume.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let matchRate = resume.matchRate {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(Int(matchRate * 100))%")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ dateString: String) -> String {
        // "2023-05-01 12:34" 형식의 문자열을 "2023년 5월 1일"로 변환
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if let date = dateFormatter.date(from: dateString) {
            dateFormatter.dateFormat = "yyyy년 M월 d일"
            return dateFormatter.string(from: date)
        }
        
        return dateString
    }
}

struct ResumesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ResumesView(viewModel: ResumeViewModel())
        }
    }
}
