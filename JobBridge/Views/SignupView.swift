import SwiftUI

struct SignupView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = AuthViewModel()
    
    // 기존 상태 변수들
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var address = ""
    @State private var age = ""
    @State private var phone = ""
    @State private var userType = "INDIVIDUAL" // 기본값
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // 이메일 인증 관련 상태 변수 추가
    @State private var verificationCode = ""
    @State private var isEmailSent = false
    @State private var isEmailVerified = false
    @State private var emailVerifiedMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // 이메일 인증 섹션 추가
                Section(header: Text("이메일 인증")) {
                    TextField("이메일", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !isEmailSent {
                        Button("인증코드 전송") {
                            sendVerificationCode()
                        }
                        .disabled(email.isEmpty || viewModel.isLoading)
                    } else if !isEmailVerified {
                        HStack {
                            TextField("인증코드", text: $verificationCode)
                                .keyboardType(.numberPad)
                            
                            Button("확인") {
                                verifyCode()
                            }
                            .disabled(verificationCode.isEmpty || viewModel.isLoading)
                        }
                    } else {
                        HStack {
                            Text(emailVerifiedMessage)
                                .foregroundColor(.green)
                            
                            Spacer()
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // 계정 정보 섹션
                Section(header: Text("필수 정보")) {
                    TextField("이름", text: $name)
                    
                    SecureField("비밀번호", text: $password)
                    SecureField("비밀번호 확인", text: $confirmPassword)
                }
                
                // 추가 정보 섹션 (기존과 동일)
                Section(header: Text("추가 정보")) {
                    TextField("주소", text: $address)
                    TextField("나이", text: $age)
                        .keyboardType(.numberPad)
                    TextField("전화번호", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                // 회원 유형 섹션 (기존과 동일)
                Section(header: Text("회원 유형")) {
                    Picker("회원 유형", selection: $userType) {
                        Text("개인 회원").tag("INDIVIDUAL")
                        Text("기업 회원").tag("COMPANY")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 오류 메시지 섹션 (기존과 동일)
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                // 회원가입 버튼 섹션 (이메일 인증 필수 조건 추가)
                Section {
                    Button(action: signUp) {
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("회원가입")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.isLoading || !isEmailVerified || name.isEmpty || password.isEmpty || password != confirmPassword)
                }
            }
            .navigationTitle("회원가입")
            .navigationBarItems(leading: Button("취소") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("회원가입 완료"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("확인")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    // 인증코드 전송 함수 추가
    private func sendVerificationCode() {
        viewModel.sendVerificationCode(email: email) { result in
            switch result {
            case .success(let message):
                isEmailSent = true
                // 성공 메시지 표시 (옵션)
            case .failure(let error):
                // 에러는 viewModel.errorMessage에서 처리됨
                print("인증코드 전송 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // 인증코드 확인 함수 추가
    private func verifyCode() {
        viewModel.verifyCode(email: email, code: verificationCode) { result in
            switch result {
            case .success(let message):
                isEmailVerified = true
                emailVerifiedMessage = "이메일 인증 완료"
            case .failure(let error):
                // 에러는 viewModel.errorMessage에서 처리됨
                print("인증코드 확인 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // 회원가입 함수 (이메일 인증 조건 추가)
    private func signUp() {
        // 유효성 검사
        if name.isEmpty || email.isEmpty || password.isEmpty {
            viewModel.errorMessage = "필수 항목을 모두 입력해주세요"
            return
        }
        
        if password != confirmPassword {
            viewModel.errorMessage = "비밀번호가 일치하지 않습니다"
            return
        }
        
        if !isEmailVerified {
            viewModel.errorMessage = "이메일 인증이 필요합니다"
            return
        }
        
        // 회원가입 요청
        viewModel.signup(
            name: name,
            email: email,
            password: password,
            address: address,
            age: age,
            phone: phone,
            userType: userType
        )
        
        // 회원가입 성공 시 알림 표시
        showingAlert = true
        alertMessage = "회원가입이 완료되었습니다. 로그인 페이지로 이동합니다."
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
    }
}
