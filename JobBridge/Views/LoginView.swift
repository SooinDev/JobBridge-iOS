import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showSignup = false
    @State private var isPasswordVisible = false
    @State private var rememberMe = false
    @State private var animateBackground = false
    @State private var animateFields = false
    @State private var showPasswordReset = false // 상태 변수 추가
    @State private var showPasswordAlert = false
    
    @Environment(\.colorScheme) var colorScheme
    
    // 로고 이미지 이름 (Assets에 추가 필요)
    private let logoImage = "appLogo"
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 다크모드에 적합한 그라데이션 배경
                Group {
                    if colorScheme == .dark {
                        // 다크모드용 배경
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.1, green: 0.1, blue: 0.2),
                                Color(red: 0.05, green: 0.05, blue: 0.15),
                                Color(red: 0, green: 0, blue: 0.1)
                            ]),
                            startPoint: animateBackground ? .topLeading : .topTrailing,
                            endPoint: animateBackground ? .bottomTrailing : .bottomLeading
                        )
                        .ignoresSafeArea()
                    } else {
                        // 라이트모드용 배경 - 더 심플하고 현대적인 그라데이션
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.92, green: 0.95, blue: 1.0),
                                Color(red: 0.85, green: 0.9, blue: 1.0),
                                Color.white
                            ]),
                            startPoint: animateBackground ? .topLeading : .topTrailing,
                            endPoint: animateBackground ? .bottomTrailing : .bottomLeading
                        )
                        .ignoresSafeArea()
                    }
                }
                .animation(
                    Animation.easeInOut(duration: 10.0)
                        .repeatForever(autoreverses: true),
                    value: animateBackground
                )
                
                // 백그라운드 장식 요소 (다크모드에 따라 적응)
                ZStack {
                    Circle()
                        .fill(colorScheme == .dark ?
                              Color.white.opacity(0.03) :
                              Color.blue.opacity(0.05))
                        .frame(width: geometry.size.width * 0.7)
                        .offset(x: -geometry.size.width * 0.4, y: -geometry.size.height * 0.2)
                        .blur(radius: 40)
                    
                    Circle()
                        .fill(colorScheme == .dark ?
                              Color.blue.opacity(0.05) :
                              Color.blue.opacity(0.08))
                        .frame(width: geometry.size.width * 0.8)
                        .offset(x: geometry.size.width * 0.4, y: geometry.size.height * 0.3)
                        .blur(radius: 60)
                }
                
                // 컨텐츠
                ScrollView {
                    VStack(spacing: 30) {
                        // 로고 및 헤더
                        VStack(spacing: 15) {
                            // 앱 로고 (실제 로고 이미지로 교체 가능)
                            if let uiImage = UIImage(named: logoImage) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            } else {
                                // 대체 로고
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.7)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                        .shadow(color: colorScheme == .dark ?
                                               Color.black.opacity(0.3) :
                                               Color.black.opacity(0.15),
                                               radius: 10, x: 0, y: 5)
                                    
                                    Image(systemName: "building.columns.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text("JobBridge")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("구직자와 기업을 연결하는 지능형 매칭 서비스")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(colorScheme == .dark ?
                                                Color.white.opacity(0.7) :
                                                Color.black.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .offset(y: animateFields ? 0 : -30)
                        .opacity(animateFields ? 1 : 0)
                        .animation(.easeOut(duration: 0.8).delay(0.2), value: animateFields)
                        
                        // 로그인 카드
                        VStack(spacing: 24) {
                            // 이메일 입력
                            FloatingLabelTextField(
                                title: "이메일",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress
                            )
                            
                            // 비밀번호 입력
                            FloatingLabelTextField(
                                title: "비밀번호",
                                text: $password,
                                icon: "lock.fill",
                                isSecure: !isPasswordVisible,
                                trailingIcon: isPasswordVisible ? "eye.slash.fill" : "eye.fill",
                                trailingAction: {
                                    withAnimation {
                                        isPasswordVisible.toggle()
                                    }
                                }
                            )
                            
                            // 로그인 추가 옵션
                            HStack {
                                Toggle(isOn: $rememberMe) {
                                    Text("로그인 유지")
                                        .font(.footnote)
                                        .foregroundColor(colorScheme == .dark ?
                                                         Color.white.opacity(0.7) :
                                                         Color.black.opacity(0.6))
                                }
                                .toggleStyle(SwitchToggleStyle(tint: Color.blue))
                                
                                Spacer()
                                
                                Button("비밀번호 찾기") {
                                    showPasswordReset = true
                                }
                                .font(.footnote)
                                .foregroundColor(Color.blue)

                                // View 수정자로 추가
                                .alert(isPresented: $showPasswordAlert) {
                                    Alert(
                                        title: Text("준비 중"),
                                        message: Text("비밀번호 찾기 기능은 현재 개발 중입니다. 빠른 시일 내에 제공될 예정입니다."),
                                        dismissButton: .default(Text("확인"))
                                    )
                                }
                            }
                            .padding(.top, 10)
                            
                            // 오류 메시지
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(5)
                            }
                            
                            // 로그인 버튼
                            Button(action: {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                               to: nil,
                                                               from: nil,
                                                               for: nil)
                                viewModel.login(email: email, password: password, rememberMe: rememberMe)
                            }) {
                                Group {
                                    if viewModel.isLoading {
                                        HStack(spacing: 10) {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            Text("로그인 중...")
                                        }
                                    } else {
                                        Text("로그인")
                                    }
                                }
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)
                            .scaleEffect(viewModel.isLoading ? 0.95 : 1.0)
                            .animation(.spring(), value: viewModel.isLoading)
                        }
                        .padding(20)
                        .background(colorScheme == .dark ?
                                   Color(UIColor.secondarySystemBackground) :
                                   Color.white)
                        .cornerRadius(20)
                        .shadow(color: colorScheme == .dark ?
                               Color.black.opacity(0.5) :
                               Color.black.opacity(0.1),
                               radius: 20, x: 0, y: 10)
                        .padding(.horizontal)
                        .offset(y: animateFields ? 0 : 50)
                        .opacity(animateFields ? 1 : 0)
                        .animation(.easeOut(duration: 0.8).delay(0.4), value: animateFields)
                        
                        // 회원가입 버튼
                        Button(action: {
                            showSignup = true
                        }) {
                            HStack(spacing: 4) {
                                Text("계정이 없으신가요?")
                                    .foregroundColor(colorScheme == .dark ?
                                                     Color.white.opacity(0.7) :
                                                     Color.black.opacity(0.6))
                                
                                Text("회원가입")
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.blue)
                            }
                            .font(.system(size: 15))
                        }
                        .padding(.top, 10)
                        .offset(y: animateFields ? 0 : 30)
                        .opacity(animateFields ? 1 : 0)
                        .animation(.easeOut(duration: 0.8).delay(0.6), value: animateFields)
                    }
                    .padding(.vertical, 30)
                    .padding(.bottom, 20) // 키보드를 위한 추가 공간
                }
                .frame(width: geometry.size.width)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $viewModel.isAuthenticated) {
            MainTabView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showSignup) {
            SignupView()
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView()
        }
        .onAppear {
            // 애니메이션 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateBackground = true
                animateFields = true
            }
        }
    }
}

// MARK: - 커스텀 컴포넌트

// 부유하는 레이블이 있는 TextField (iOS 14 호환 버전)
struct FloatingLabelTextField: View {
    let title: String
    @Binding var text: String
    var icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var trailingIcon: String? = nil
    var trailingAction: (() -> Void)? = nil
    
    @State private var isFocused = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 15) {
                // 아이콘
                Image(systemName: icon)
                    .foregroundColor(isFocused ? Color.blue : (colorScheme == .dark ? Color.white.opacity(0.6) : Color.gray))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 0) {
                    // 부유하는 레이블
                    if isFocused || !text.isEmpty {
                        Text(title)
                            .font(.system(size: 12))
                            .foregroundColor(isFocused ? Color.blue :
                                            (colorScheme == .dark ? Color.white.opacity(0.7) : Color.gray))
                            .padding(.bottom, 4)
                    }
                    
                    // 텍스트 필드
                    Group {
                        if isSecure {
                            CustomSecureField(
                                placeholder: isFocused || !text.isEmpty ? "" : title,
                                text: $text,
                                isFocused: $isFocused,
                                keyboardType: keyboardType,
                                isDarkMode: colorScheme == .dark
                            )
                        } else {
                            CustomTextField(
                                placeholder: isFocused || !text.isEmpty ? "" : title,
                                text: $text,
                                isFocused: $isFocused,
                                keyboardType: keyboardType,
                                isDarkMode: colorScheme == .dark
                            )
                        }
                    }
                    .frame(height: 25)
                }
                
                // 추가 아이콘 (예: 비밀번호 표시/숨김)
                if let trailingIcon = trailingIcon, let trailingAction = trailingAction {
                    Button(action: trailingAction) {
                        Image(systemName: trailingIcon)
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.6) : Color.gray)
                    }
                }
            }
            
            // 하단 디바이더
            Rectangle()
                .fill(isFocused ? Color.blue :
                     (colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.3)))
                .frame(height: isFocused ? 2 : 1)
        }
    }
}

// UIKit 기반 TextField 래퍼 (다크모드 지원)
struct CustomTextField: UIViewRepresentable {
    var placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    var keyboardType: UIKeyboardType
    var isDarkMode: Bool
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField
        
        init(_ parent: CustomTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            withAnimation {
                parent.isFocused = true
            }
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            withAnimation {
                parent.isFocused = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.borderStyle = .none
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textColor = isDarkMode ? .white : .black
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor:
                        isDarkMode ? UIColor.lightGray : UIColor.darkGray]
        )
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.placeholder = placeholder
        uiView.textColor = isDarkMode ? .white : .black
    }
}

// UIKit 기반 SecureTextField 래퍼 (다크모드 지원)
struct CustomSecureField: UIViewRepresentable {
    var placeholder: String
    @Binding var text: String
    @Binding var isFocused: Bool
    var keyboardType: UIKeyboardType
    var isDarkMode: Bool
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomSecureField
        
        init(_ parent: CustomSecureField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            withAnimation {
                parent.isFocused = true
            }
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            withAnimation {
                parent.isFocused = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.keyboardType = keyboardType
        textField.isSecureTextEntry = true
        textField.borderStyle = .none
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.textColor = isDarkMode ? .white : .black
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor:
                        isDarkMode ? UIColor.lightGray : UIColor.darkGray]
        )
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.placeholder = placeholder
        uiView.textColor = isDarkMode ? .white : .black
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            LoginView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
