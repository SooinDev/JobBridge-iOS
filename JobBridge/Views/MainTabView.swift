import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var resumeViewModel = ResumeViewModel()
    @StateObject private var jobViewModel = JobViewModel()
    
    var body: some View {
        TabView {
            // 이력서 탭
            NavigationView {
                ResumesView(viewModel: resumeViewModel)
            }
            .tabItem {
                Label("이력서", systemImage: "doc.text")
            }
            
            // 채용공고 탭
            NavigationView {
                JobsView(viewModel: jobViewModel)
            }
            .tabItem {
                Label("채용공고", systemImage: "briefcase")
            }
            
            // 프로필 탭
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Label("내 정보", systemImage: "person")
            }
        }
        .accentColor(.blue)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
    }
}
