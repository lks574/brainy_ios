import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @State private var viewModel: AuthenticationViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: AuthenticationViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // 로고 및 타이틀
                    headerSection
                    
                    // 이메일 로그인 폼
                    emailSignInSection
                    
                    // 구분선
                    dividerSection
                    
                    // 소셜 로그인 버튼들
                    socialSignInSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .background(Color.brainyBackground)
            .navigationBarHidden(true)
        }
        .alert("로그인 오류", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 앱 로고 (임시로 텍스트 사용)
            Text("🧠")
                .font(.system(size: 80))
            
            Text("Brainy Quiz")
                .font(.brainyTitle)
                .foregroundColor(.brainyText)
            
            Text("지식을 늘려가는 재미있는 퀴즈")
                .font(.brainyBody)
                .foregroundColor(.brainyTextSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Email Sign In Section
    private var emailSignInSection: some View {
        VStack(spacing: 16) {
            // 이메일 입력 필드
            BrainyTextField(
                text: $viewModel.email,
                placeholder: "이메일",
                keyboardType: .emailAddress
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            
            // 비밀번호 입력 필드
            HStack {
                if viewModel.showPassword {
                    BrainyTextField(
                        text: $viewModel.password,
                        placeholder: "비밀번호"
                    )
                } else {
                    SecureField("비밀번호", text: $viewModel.password)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.brainySurface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.brainySecondary.opacity(0.3), lineWidth: 1)
                        )
                }
                
                Button(action: viewModel.togglePasswordVisibility) {
                    Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.brainyTextSecondary)
                }
                .padding(.trailing, 16)
            }
            
            // 로그인 버튼
            BrainyButton(
                title: viewModel.isLoading ? "로그인 중..." : "이메일로 로그인",
                style: .primary,
                isEnabled: viewModel.isSignInButtonEnabled
            ) {
                Task {
                    await viewModel.signInWithEmail()
                }
            }
            .disabled(!viewModel.isSignInButtonEnabled)
        }
    }
    
    // MARK: - Divider Section
    private var dividerSection: some View {
        HStack {
            Rectangle()
                .fill(Color.brainySecondary.opacity(0.3))
                .frame(height: 1)
            
            Text("또는")
                .font(.brainyCaption)
                .foregroundColor(.brainyTextSecondary)
                .padding(.horizontal, 16)
            
            Rectangle()
                .fill(Color.brainySecondary.opacity(0.3))
                .frame(height: 1)
        }
    }
    
    // MARK: - Social Sign In Section
    private var socialSignInSection: some View {
        VStack(spacing: 12) {
            // Sign in with Apple
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    Task {
                        await viewModel.signInWithApple()
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .cornerRadius(12)
            .disabled(!viewModel.isSocialSignInEnabled)
            
            // Google 로그인 버튼
            Button(action: {
                Task {
                    await viewModel.signInWithGoogle()
                }
            }) {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.white)
                    
                    Text("Google로 로그인")
                        .font(.brainyButton)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.red)
                .cornerRadius(12)
            }
            .disabled(!viewModel.isSocialSignInEnabled)
        }
    }
}

// MARK: - Preview
#Preview {
    SignInView(
        viewModel: AuthenticationViewModel(
            authenticationUseCase: AuthenticationUseCase(
                repository: AuthenticationRepositoryImpl(
                    localDataSource: LocalDataSource(modelContext: ModelContainer.preview.mainContext)
                )
            )
        )
    )
}