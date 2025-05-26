// EditJobPostingView.swift
import SwiftUI

struct EditJobPostingView: View {
    @Environment(\.presentationMode) var presentationMode
    let job: JobPostingResponse
    @ObservedObject var viewModel: CompanyJobViewModel
    
    @State private var title: String
    @State private var description: String
    @State private var position: String
    @State private var requiredSkills: String
    @State private var experienceLevel: String
    @State private var location: String
    @State private var salary: String
    @State private var deadline = Date()
    @State private var hasDeadline = true
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    // 미리 정의된 옵션들
    private let experienceLevels = ["신입", "1-3년", "3-5년", "5-10년", "10년+", "경력무관"]
    private let locations = ["서울", "부산", "대구", "인천", "광주", "대전", "울산", "세종", "경기", "강원", "충북", "충남", "전북", "전남", "경북", "경남", "제주", "전국", "재택근무"]
    private let salaryRanges = ["면접 후 결정", "2000-3000만원", "3000-4000만원", "4000-5000만원", "5000-6000만원", "6000-8000만원", "8000만원 이상"]
    
    init(job: JobPostingResponse, viewModel: CompanyJobViewModel) {
        self.job = job
        self.viewModel = viewModel
        
        // 기존 값들로 초기화
        self._title = State(initialValue: job.title)
        self._description = State(initialValue: job.description)
        self._position = State(initialValue: job.position)
        self._requiredSkills = State(initialValue: job.requiredSkills)
        self._experienceLevel = State(initialValue: job.experienceLevel)
        self._location = State(initialValue: job.location)
        self._salary = State(initialValue: job.salary)
        
        // 마감일 설정
        if let deadlineString = job.deadline {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            if let deadlineDate = formatter.date(from: deadlineString) {
                self._deadline = State(initialValue: deadlineDate)
                self._hasDeadline = State(initialValue: true)
            } else {
                self._hasDeadline = State(initialValue: false)
            }
        } else {
            self._hasDeadline = State(initialValue: false)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 기본 정보
                Section(header: Text("기본 정보")) {
                    TextField("채용공고 제목", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("채용 포지션", text: $position)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("상세 설명")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                // 요구 사항
                Section(header: Text("요구 사항")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("필요 기술/스킬")
                        TextField("예: Swift, iOS, UIKit, SwiftUI", text: $requiredSkills)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("쉼표(,)로 구분하여 입력해주세요")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("경력 요구사항")
                        Picker("경력", selection: $experienceLevel) {
                            ForEach(experienceLevels, id: \.self) { level in
                                Text(level).tag(level)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // 근무 조건
                Section(header: Text("근무 조건")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("근무 지역")
                        Picker("지역", selection: $location) {
                            ForEach(locations, id: \.self) { loc in
                                Text(loc).tag(loc)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("급여")
                        Picker("급여", selection: $salary) {
                            ForEach(salaryRanges, id: \.self) { range in
                                Text(range).tag(range)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // 마감일
                Section(header: Text("지원 마감")) {
                    Toggle("마감일 설정", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("마감일", selection: $deadline, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                }
                
                // 오류 메시지
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("채용공고 수정")
            .navigationBarItems(
                leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("저장") {
                    updateJobPosting()
                }
                .disabled(title.isEmpty || description.isEmpty || position.isEmpty || viewModel.isLoading)
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(isSuccess ? "수정 완료" : "수정 실패"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인")) {
                        if isSuccess {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        
                        Text("채용공고를 수정하는 중...")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(20)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func updateJobPosting() {
        guard !title.isEmpty, !description.isEmpty, !position.isEmpty else {
            showAlert = true
            isSuccess = false
            alertMessage = "필수 항목을 모두 입력해주세요."
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        let request = CompanyJobPostingRequest(
            title: title,
            description: description,
            position: position,
            requiredSkills: requiredSkills,
            experienceLevel: experienceLevel,
            location: location,
            salary: salary,
            deadline: hasDeadline ? formatter.string(from: deadline) : ""
        )
        
        viewModel.updateJobPosting(jobId: job.id, request: request) { success in
            showAlert = true
            isSuccess = success
            if success {
                alertMessage = "채용공고가 성공적으로 수정되었습니다."
            } else {
                alertMessage = viewModel.errorMessage ?? "채용공고 수정 중 오류가 발생했습니다."
            }
        }
    }
}
