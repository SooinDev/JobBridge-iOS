import SwiftUI

struct AddResumeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: ResumeViewModel
    
    @State private var title = ""
    @State private var content = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
            .navigationTitle("이력서 작성")
            .navigationBarItems(
                leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("저장") {
                    saveResume()
                }
                .disabled(title.isEmpty || content.isEmpty || viewModel.isLoading)
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("알림"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인")) {
                        if alertMessage.contains("저장되었습니다") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                )
            }
        }
    }
    
    private func saveResume() {
        guard !title.isEmpty, !content.isEmpty else {
            showAlert = true
            alertMessage = "제목과 내용을 모두 입력해주세요."
            return
        }
        
        viewModel.createResume(title: title, content: content) { success in
            showAlert = true
            if success {
                alertMessage = "이력서가 성공적으로 저장되었습니다."
            } else {
                alertMessage = viewModel.errorMessage ?? "이력서 저장 중 오류가 발생했습니다."
            }
        }
    }
}

struct AddResumeView_Previews: PreviewProvider {
    static var previews: some View {
        AddResumeView(viewModel: ResumeViewModel())
    }
}
