import SwiftUI

struct EditResumeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ResumeViewModel
    let resume: ResumeResponse
    
    @State private var title: String
    @State private var content: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(viewModel: ResumeViewModel, resume: ResumeResponse) {
        self.viewModel = viewModel
        self.resume = resume
        self._title = State(initialValue: resume.title)
        self._content = State(initialValue: resume.content)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("이력서 제목")) {
                    TextField("제목을 입력하세요", text: $title)
                }
                
                Section(header: Text("이력서 내용")) {
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("경력, 기술, 자격증 등 자신을 어필할 수 있는 내용을 작성하세요.")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .opacity(content.isEmpty ? 0.25 : 1)
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("이력서 수정")
            .navigationBarItems(
                leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("저장") {
                    updateResume()
                }
                .disabled(title.isEmpty || content.isEmpty || viewModel.isLoading)
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("알림"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인")) {
                        if alertMessage.contains("수정되었습니다") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }
    
    private func updateResume() {
        guard !title.isEmpty, !content.isEmpty else {
            showAlert = true
            alertMessage = "제목과 내용을 모두 입력해주세요."
            return
        }
        
        Task {
            do {
                let request = ResumeRequest(title: title, content: content)
                let _ = try await APIService.shared.updateResume(resumeId: resume.id, request: request)
                
                DispatchQueue.main.async {
                    self.showAlert = true
                    self.alertMessage = "이력서가 성공적으로 수정되었습니다."
                    // 목록 새로고침
                    self.viewModel.loadResumes()
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert = true
                    if let apiError = error as? APIError {
                        self.alertMessage = apiError.errorMessage
                    } else {
                        self.alertMessage = "이력서 수정 중 오류가 발생했습니다."
                    }
                }
            }
        }
    }
}

struct EditResumeView_Previews: PreviewProvider {
    static var previews: some View {
        EditResumeView(
            viewModel: ResumeViewModel(),
            resume: ResumeResponse(
                id: 1,
                title: "샘플 이력서",
                content: "샘플 내용",
                userName: "홍길동",
                createdAt: "2024-01-01 10:00",
                updatedAt: "2024-01-01 10:00"
            )
        )
    }
}
