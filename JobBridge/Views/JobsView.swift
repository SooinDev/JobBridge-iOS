import SwiftUI

struct JobsView: View {
    @ObservedObject var viewModel: JobViewModel
    @State private var searchText = ""
    
    var filteredJobs: [JobPostingResponse] {
        if searchText.isEmpty {
            return viewModel.jobs
        } else {
            return viewModel.jobs.filter { job in
                job.title.lowercased().contains(searchText.lowercased()) ||
                (job.companyName?.lowercased().contains(searchText.lowercased()) ?? false) ||
                job.position.lowercased().contains(searchText.lowercased()) ||
                job.requiredSkills.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.jobs.isEmpty {
                ProgressView("채용공고를 불러오는 중...")
            } else if let errorMessage = viewModel.errorMessage, viewModel.jobs.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("오류가 발생했습니다")
                        .font(.headline)
                    
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        viewModel.loadRecentJobs()
                    }) {
                        Text("다시 시도")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            } else {
                VStack {
                    // 검색 바
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("채용공고 검색", text: $searchText)
                            .disableAutocorrection(true)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    // 채용공고 목록
                    if filteredJobs.isEmpty {
                        VStack(spacing: 15) {
                            Spacer()
                            
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            if searchText.isEmpty {
                                Text("채용공고가 없습니다")
                            } else {
                                Text("'\(searchText)'에 대한 검색 결과가 없습니다")
                            }
                            
                            Spacer()
                        }
                    } else {
                        List {
                            ForEach(filteredJobs) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(job.title)
                                            .font(.headline)
                                            .lineLimit(1)
                                        
                                        HStack {
                                            Text(job.companyName ?? "기업명 없음")
                                                .font(.subheadline)
                                            
                                            Spacer()
                                            
                                            Text(job.location)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        HStack {
                                            Text(job.experienceLevel)
                                                .font(.caption)
                                            
                                            Spacer()
                                            
                                            Text("등록일: \(job.createdAt.toShortDate())")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                }
                .refreshable {
                    viewModel.loadRecentJobs()
                }
            }
        }
        .navigationTitle("채용공고")
        .onAppear {
            if viewModel.jobs.isEmpty {
                viewModel.loadRecentJobs()
            }
        }
    }
}

struct JobsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            JobsView(viewModel: JobViewModel())
        }
    }
}
