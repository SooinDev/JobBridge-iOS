import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showingLogoutAlert = false
    
    var body: some View {
        Form {
            // 사용자 정보 섹션
            Section(header: Text("계정 정보")) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.blue)
                        .padding(.trailing, 10)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(authViewModel.currentUser?.name ?? "사용자")
                            .font(.headline)
                        
                        Text(authViewModel.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(userTypeFormatted)
                            .font(.caption)
                            .padding(5)
                            .background(userTypeColor)
                            .foregroundColor(.white)
                            .cornerRadius(5)
                    }
                }
                .padding(.vertical, 5)
            }
            
            // 활동 내역 섹션
            Section(header: Text("활동 내역")) {
                NavigationLink(destination: MyApplicationsView()) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                        Text("지원 내역")
                    }
                }
                
                NavigationLink(destination: ResumesView(viewModel: ResumeViewModel())) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                        Text("내 이력서")
                    }
                }
            }
            
            // 앱 정보 섹션
            Section(header: Text("앱 정보")) {
                HStack {
                    Text("버전")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link(destination: URL(string: "https://yourapp.com/privacy")!) {
                    HStack {
                        Text("개인정보 처리방침")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }
                
                Link(destination: URL(string: "https://yourapp.com/terms")!) {
                    HStack {
                        Text("이용약관")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                }
            }
            
            // 로그아웃 섹션
            Section {
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    HStack {
                        Spacer()
                        Text("로그아웃")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("내 프로필")
        .alert(isPresented: $showingLogoutAlert) {
            Alert(
                title: Text("로그아웃"),
                message: Text("정말 로그아웃 하시겠습니까?"),
                primaryButton: .destructive(Text("로그아웃")) {
                    authViewModel.logout()
                },
                secondaryButton: .cancel(Text("취소"))
            )
        }
    }
    
    var userTypeFormatted: String {
        switch authViewModel.currentUser?.userType {
        case "INDIVIDUAL":
            return "개인 회원"
        case "COMPANY":
            return "기업 회원"
        default:
            return "회원"
        }
    }
    
    var userTypeColor: Color {
        switch authViewModel.currentUser?.userType {
        case "INDIVIDUAL":
            return Color.blue
        case "COMPANY":
            return Color.green
        default:
            return Color.gray
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
                .environmentObject(AuthViewModel())
        }
    }
}
