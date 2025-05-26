// CompanyJobDetailView.swift
import SwiftUI

struct CompanyJobDetailView: View {
    let job: JobPostingResponse
    @ObservedObject var viewModel: CompanyJobViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var showingApplicationsView = false
    @State private var animateHeader = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 헤더 섹션
                CompanyJobHeaderSection(job: job)
                    .offset(y: animateHeader ? 0 : -30)
                    .opacity(animateHeader ? 1 : 0)
                    .animation(.easeOut(duration: 0.6), value: animateHeader)
                
                // 메인 컨텐츠
                VStack(spacing: 24) {
                    // 채용공고 정보 카드들
                    CompanyJobInfoSection(job: job)
                    
                    // 스킬 및 요구사항
                    CompanyJobSkillsSection(job: job)
                    
                    // 상세 설명
                    CompanyJobDescriptionSection(job: job)
                    
                    // 지원자 관리 섹션
                    CompanyApplicationsSection(job: job, showingApplicationsView: $showingApplicationsView)
                    
                    // 채용공고 관리 액션
                    CompanyJobActionsSection(
                        showingEditView: $showingEditView,
                        showingDeleteAlert: $showingDeleteAlert
                    )
                    
                    // 하단 여백
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .offset(y: animateHeader ? 0 : 50)
                .opacity(animateHeader ? 1 : 0)
                .animation(.easeOut(duration: 0.8).delay(0.3), value: animateHeader)
            }
        }
        .navigationBarHidden(true)
        .overlay(
            // 커스텀 네비게이션 바
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button(action: {
                            showingEditView = true
                        }) {
                            Label("수정", systemImage: "pencil")
                        }
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Label("삭제", systemImage: "trash")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateHeader = true
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditJobPostingView(job: job, viewModel: viewModel)
        }
        .sheet(isPresented: $showingApplicationsView) {
            CompanyApplicationManagementView(job: job)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("채용공고 삭제"),
                message: Text("정말로 이 채용공고를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다."),
                primaryButton: .destructive(Text("삭제")) {
                    deleteJobPosting()
                },
                secondaryButton: .cancel(Text("취소"))
            )
        }
    }
    
    private func deleteJobPosting() {
        viewModel.deleteJobPosting(jobId: job.id)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - 헤더 섹션
struct CompanyJobHeaderSection: View {
    let job: JobPostingResponse
    @Environment(\.colorScheme) var colorScheme
    
    private var statusInfo: (text: String, color: Color) {
        guard let deadline = job.deadline else {
            return ("상시채용", .blue)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        guard let deadlineDate = formatter.date(from: deadline) else {
            return ("상시채용", .blue)
        }
        
        if deadlineDate < Date() {
            return ("마감", .red)
        } else {
            let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: deadlineDate).day ?? 0
            if daysLeft <= 3 {
                return ("D-\(daysLeft)", .orange)
            } else {
                return ("진행중", .green)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 제목과 상태
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(job.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .lineLimit(3)
                        
                        Text(job.position)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                    }
                    
                    Spacer()
                    
                    // 상태 배지
                    VStack(spacing: 8) {
                        Text(statusInfo.text)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusInfo.color)
                            .cornerRadius(16)
                        
                        Text("등록일")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(job.createdAt.toShortDate())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 기본 태그들
            HStack(spacing: 12) {
                CompanyJobTag(icon: "location.fill", text: job.location, color: .blue)
                CompanyJobTag(icon: "dollarsign.circle.fill", text: job.salary, color: .green)
                CompanyJobTag(icon: "briefcase.fill", text: job.experienceLevel, color: .purple)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    colorScheme == .dark ?
                    Color.white.opacity(0.1) :
                    Color.black.opacity(0.05),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 80)
    }
}

// MARK: - 정보 섹션
struct CompanyJobInfoSection: View {
    let job: JobPostingResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("채용 정보")
                .font(.system(size: 20, weight: .bold))
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                CompanyJobInfoCard(
                    icon: "briefcase.fill",
                    title: "직무",
                    value: job.position,
                    color: .blue
                )
                
                CompanyJobInfoCard(
                    icon: "dollarsign.circle.fill",
                    title: "급여",
                    value: job.salary,
                    color: .green
                )
                
                CompanyJobInfoCard(
                    icon: "clock.fill",
                    title: "마감일",
                    value: job.deadline?.toCompanyJobFormattedDate() ?? "상시채용",
                    color: .orange
                )
                
                CompanyJobInfoCard(
                    icon: "calendar.badge.plus",
                    title: "등록일",
                    value: job.createdAt.toCompanyJobFormattedDate(),
                    color: .purple
                )
            }
        }
    }
}

// MARK: - 스킬 섹션
struct CompanyJobSkillsSection: View {
    let job: JobPostingResponse
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("필요 기술")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("이 포지션에서 사용하는 기술 스택")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            CompanySkillTags(skills: job.requiredSkills.components(separatedBy: ","))
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    colorScheme == .dark ?
                    Color.white.opacity(0.1) :
                    Color.black.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - 설명 섹션
struct CompanyJobDescriptionSection: View {
    let job: JobPostingResponse
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("상세 내용")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("업무 내용 및 요구사항")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(job.description)
                .font(.system(size: 16))
                .lineSpacing(6)
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    colorScheme == .dark ?
                    Color.white.opacity(0.1) :
                    Color.black.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - 지원자 관리 섹션
struct CompanyApplicationsSection: View {
    let job: JobPostingResponse
    @Binding var showingApplicationsView: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("지원자 관리")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("이 채용공고에 지원한 지원자들을 관리하세요")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button(action: {
                showingApplicationsView = true
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("지원자 보기")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("지원자 목록을 확인하고 관리하세요")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - 액션 섹션
struct CompanyJobActionsSection: View {
    @Binding var showingEditView: Bool
    @Binding var showingDeleteAlert: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // 수정 버튼
            Button(action: {
                showingEditView = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Text("채용공고 수정")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppTheme.primary,
                            AppTheme.primary.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            // 삭제 버튼
            Button(action: {
                showingDeleteAlert = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    
                    Text("채용공고 삭제")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.red,
                            Color.red.opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
}

// MARK: - 누락된 컴포넌트들
struct CompanyJobInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(colorScheme == .dark ? 0.3 : 0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(AppTheme.secondaryBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct CompanySkillTags: View {
    let skills: [String]
    @Environment(\.colorScheme) var colorScheme

    private var skillColors: [Color] {
        [.blue, .green, .purple, .orange, .pink, .indigo]
    }

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 100), spacing: 12)
        ], spacing: 12) {
            ForEach(Array(skills.enumerated()), id: \.offset) { index, skill in
                let trimmedSkill = skill.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedSkill.isEmpty {
                    CompanySkillTag(
                        skill: trimmedSkill,
                        color: skillColors[index % skillColors.count]
                    )
                }
            }
        }
    }
}

struct CompanySkillTag: View {
    let skill: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(skill.hasPrefix("#") ? skill : "#\(skill)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(color.opacity(colorScheme == .dark ? 0.15 : 0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 보조 컴포넌트들
struct CompanyJobTag: View {
    let icon: String
    let text: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(colorScheme == .dark ? .white : .black)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Extensions for CompanyJobDetailView
extension String {
    func toCompanyJobFormattedDate() -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        if let date = inputFormatter.date(from: self) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "yyyy년 M월 d일"
            outputFormatter.locale = Locale(identifier: "ko_KR")
            return outputFormatter.string(from: date)
        }
        
        return self
    }
}
