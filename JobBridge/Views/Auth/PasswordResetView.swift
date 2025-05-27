import SwiftUI

struct PasswordResetView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = PasswordResetViewModel()
    @State private var showingResetSuccessAlert = false  // ✅ 변경됨

    var body: some View {
        NavigationView {
            Form {
                if !viewModel.showResetForm {
                    // 이메일 입력 폼
                    Section(header: Text("이메일 입력")) {
                        TextField("가입한 이메일 주소", text: $viewModel.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)

                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.top, 5)
                        }

                        if let successMessage = viewModel.successMessage {
                            Text(successMessage)
                                .foregroundColor(.green)
                                .font(.footnote)
                                .padding(.top, 5)
                        }

                        Button(action: {
                            viewModel.requestPasswordReset()
                        }) {
                            Text("비밀번호 재설정 코드 받기")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(viewModel.isLoading || viewModel.email.isEmpty)
                        .padding(.top, 5)
                    }

                    // 안내 섹션
                    Section(header: Text("안내")) {
                        Text("가입 시 등록한 이메일 주소를 입력하시면, 비밀번호 재설정 코드를 이메일로 보내드립니다.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // 비밀번호 재설정 폼
                    Section(header: Text("비밀번호 재설정")) {
                        TextField("재설정 코드", text: $viewModel.resetToken)
                            .autocapitalization(.none)
                            .keyboardType(.numberPad)

                        SecureField("새 비밀번호", text: $viewModel.newPassword)

                        SecureField("새 비밀번호 확인", text: $viewModel.confirmPassword)

                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.footnote)
                                .padding(.top, 5)
                        }

                        if let successMessage = viewModel.successMessage {
                            Text(successMessage)
                                .foregroundColor(.green)
                                .font(.footnote)
                                .padding(.top, 5)
                        }

                        Button(action: {
                            viewModel.resetPassword {
                                self.showingResetSuccessAlert = true // ✅ 비밀번호 재설정 성공 시에만 알림 표시
                            }
                        }) {
                            Text("비밀번호 변경")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .disabled(viewModel.isLoading || viewModel.resetToken.isEmpty ||
                                  viewModel.newPassword.isEmpty || viewModel.confirmPassword.isEmpty)
                        .padding(.top, 5)
                    }

                    // 안내 섹션
                    Section(header: Text("안내")) {
                        Text("이메일로 받은 6자리 재설정 코드와 새로운 비밀번호를 입력해주세요. 비밀번호는 8자 이상이어야 합니다.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("비밀번호 찾기")
            .navigationBarItems(leading: Button("닫기") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingResetSuccessAlert) {  // ✅ 조건 수정됨
                Alert(
                    title: Text("비밀번호 변경 완료"),
                    message: Text("비밀번호가 성공적으로 변경되었습니다. 새 비밀번호로 로그인해주세요."),
                    dismissButton: .default(Text("확인")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
}
