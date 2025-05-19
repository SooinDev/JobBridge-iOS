import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 25) {
                // 로고 및 헤더
                VStack(spacing: 12) {
                    Image(systemName: "building.columns.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("JobBridge")
                        .font(.system(size: 32, weight: .bold))
                    
                    Text("구직자와 기업을 연결하는 지능형 매칭 서비스")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 30)
                
                // 로그인 폼
                VStack(spacing: 15) {
                    TextField("이메일", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    SecureField("비밀번호", text: $password)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 5)
                    }
                    
                    Button(action: {
                        viewModel.login(email: email, password: password)
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        } else {
                            Text("로그인")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(.horizontal, 30)
                
                // 회원가입 버튼
                Button(action: {
                    showSignup = true
                }) {
                    Text("계정이 없으신가요? 회원가입")
                        .foregroundColor(.blue)
                }
                .padding(.top, 5)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $viewModel.isAuthenticated) {
                MainTabView()
                    .environmentObject(viewModel)
            }
            .sheet(isPresented: $showSignup) {
                SignupView()
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
