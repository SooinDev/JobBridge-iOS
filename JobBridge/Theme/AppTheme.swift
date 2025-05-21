import SwiftUI

// MARK: - 색상 테마
struct AppTheme {
    // 브랜드 색상
    static let primary = Color.blue // 메인 브랜드 색상
    static let secondary = Color.indigo // 보조색
    static let accent = Color.orange // 강조색
    
    // 기능적 색상
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // 배경 색상
    static let background = Color(UIColor.systemBackground) // 기본 배경
    static let secondaryBackground = Color(UIColor.secondarySystemBackground) // 카드나 컴포넌트 배경
    
    // 텍스트 색상
    static let textPrimary = Color(UIColor.label) // 주요 텍스트
    static let textSecondary = Color(UIColor.secondaryLabel) // 보조 텍스트
    static let textTertiary = Color(UIColor.tertiaryLabel) // 부가 정보 텍스트
}

// MARK: - 텍스트 스타일
extension Text {
    func heading1() -> Text {
        self.font(.system(size: 28, weight: .bold))
            .foregroundColor(AppTheme.textPrimary)
    }
    
    func heading2() -> Text {
        self.font(.system(size: 24, weight: .bold))
            .foregroundColor(AppTheme.textPrimary)
    }
    
    func heading3() -> Text {
        self.font(.system(size: 20, weight: .semibold))
            .foregroundColor(AppTheme.textPrimary)
    }
    
    func body1() -> Text {
        self.font(.system(size: 16))
            .foregroundColor(AppTheme.textPrimary)
    }
    
    func body2() -> Text {
        self.font(.system(size: 14))
            .foregroundColor(AppTheme.textSecondary)
    }
    
    func caption() -> Text {
        self.font(.system(size: 12))
            .foregroundColor(AppTheme.textTertiary)
    }
}

// MARK: - 버튼 스타일
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? AppTheme.primary.opacity(0.8) : AppTheme.primary)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: configuration.isPressed ? 0 : 2)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(configuration.isPressed ? AppTheme.secondaryBackground.opacity(0.8) : AppTheme.secondaryBackground)
            .foregroundColor(AppTheme.primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.primary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - 카드 뷰 스타일
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(AppTheme.secondaryBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 버튼 확장
extension Button {
    func primaryStyle() -> some View {
        self.buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryStyle() -> some View {
        self.buttonStyle(SecondaryButtonStyle())
    }
}

// MARK: - View 확장
extension View {
    func cardStyle() -> some View {
        CardView { self }
    }
}

// MARK: - 공통 컴포넌트
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .body2()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.05))
    }
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.warning)
            
            Text("오류가 발생했습니다")
                .heading3()
            
            Text(message)
                .body2()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("다시 시도", action: retryAction)
                .secondaryStyle()
                .frame(width: 150)
        }
        .padding()
        .cardStyle()
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(AppTheme.textSecondary)
            
            Text(title)
                .heading3()
            
            Text(message)
                .body2()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(buttonTitle, action: buttonAction)
                    .primaryStyle()
                    .frame(maxWidth: 250)
                    .padding(.top, 10)
            }
        }
        .padding()
    }
}
