import SwiftUI

struct ResumeDetailView: View {
    let resume: ResumeResponse
    @StateObject private var jobViewModel = JobViewModel()
    @State private var showingMatchingJobs = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 헤더 섹션
                VStack(alignment: .leading, spacing: 10) {
                    Text(resume.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("작성자: \(resume.userName)")
                        Spacer()
                        Text("작성일: \(resume.createdAt.toShortDate())")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Divider()
                }
                .padding(.horizontal)
                
                // 내용 섹션
                VStack(alignment: .leading, spacing: 15) {
                    Text("이력서 내용")
                        .font(.headline)
                    
                    Text(resume.content)
                        .lineSpacing(5)
                }
                .padding(.horizontal)
                
                // 매칭 버튼
                Button(action: {
                    jobViewModel.loadMatchingJobs(resumeId: resume.id)
                    showingMatchingJobs = true
                }) {
                    HStack {
                        Image(systemName: "briefcase.fill")
                        Text("추천 채용공고 보기")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // 매칭 결과 섹션 (버튼 클릭 시 표시)
                if showingMatchingJobs {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("추천 채용공고")
                                .font(.headline)
                            Spacer()
                            if jobViewModel.isLoading {
                                ProgressView()
                            }
                        }
                        
                        if let error = jobViewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        } else if jobViewModel.matchingJobs.isEmpty && !jobViewModel.isLoading {
                            Text("추천 채용공고가 없습니다.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(jobViewModel.matchingJobs) { job in
                                NavigationLink(destination: JobDetailView(job: job)) {
                                    JobCard(job: job)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("이력서 상세")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct JobCard: View {
    let job: JobPostingResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(job.title)
                .font(.headline)
                .lineLimit(1)
            
            HStack {
                Text(job.companyName ?? "기업 정보 없음")
                    .font(.subheadline)
                
                Spacer()
                
                if let matchRate = job.matchRate {
                    Text("일치도: \(Int(matchRate * 100))%")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                Text(job.location)
                    .font(.caption)
                
                Spacer()
                
                Text(job.experienceLevel)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct ResumeDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ResumeDetailView(resume: ResumeResponse(
                id: 1,
                title: "예시 이력서",
                content: "이력서 내용입니다. 경력, 기술, 자격증 등이 포함됩니다.",
                userName: "홍길동",
                createdAt: "2023-05-01 12:34",
                updatedAt: "2023-05-01 12:34",
                matchRate: nil
            ))
        }
    }
}
