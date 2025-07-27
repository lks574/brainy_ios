# Implementation Plan

- [x] 1. 프로젝트 초기 설정 및 기본 구조 생성
  - iOS 17+ 타겟으로 Xcode 프로젝트 생성
  - Swift 6 언어 모드 활성화
  - 클린 아키텍처 폴더 구조 생성 (Presentation, Domain, Data, Core)
  - SwiftData 프레임워크 추가 및 기본 설정
  - _Requirements: 8.1, 8.5_

- [x] 2. 코어 도메인 엔티티 및 프로토콜 정의
  - User, QuizQuestion, QuizResult, QuizSession SwiftData 모델 구현
  - AuthProvider, QuizCategory, QuizType 등 열거형 정의
  - Repository 프로토콜 인터페이스 정의
  - BrainyError 커스텀 에러 타입 구현
  - _Requirements: 8.1, 8.2_

- [x] 3. 디자인 시스템 기초 구현
  - Color extension으로 앱 컬러 팔레트 정의
  - Font extension으로 타이포그래피 시스템 구현
  - 기본 UI 컴포넌트 (BrainyButton, BrainyCard, BrainyTextField) 생성
  - 다크모드 지원을 위한 컬러 에셋 설정
  - _Requirements: 8.4, 5.4_

- [x] 4. SwiftData 저장소 구현
  - ModelContainer 설정 및 데이터베이스 초기화
  - LocalDataSource 클래스로 SwiftData CRUD 작업 구현
  - Repository 구현체에서 로컬 데이터 소스 연동
  - 데이터 마이그레이션 및 버전 관리 로직 구현
  - _Requirements: 8.2, 6.3_

- [x] 5. 정적 설정 기반 인증 시스템 구현
  - StaticConfigManager 구현 (정적 설정 파일 로드 및 캐싱)
  - 정적 설정 기반 AuthenticationUseCase 도메인 로직 구현
  - 이메일 로그인 기능 구현 (정적 비밀번호 정책 적용)
  - Sign in with Apple 통합 구현 (정적 설정 확인)
  - Google Sign-In SDK 통합 구현 (정적 설정 확인)
  - 게스트 로그인 기능 구현 (정적 설정 기반)
  - 세션 관리 및 자동 갱신 로직 구현
  - 앱 버전 호환성 검증 로직 구현
  - 로그인 시도 제한 및 계정 잠금 기능 구현
  - AuthenticationViewModel과 SwiftUI 뷰 연동
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9_

- [x] 6. 메인 네비게이션 및 앱 플로우 구현
  - 앱 진입점에서 인증 상태 확인 로직 구현
  - 로그인 성공 시 메인 화면으로 전환하는 네비게이션 구현
  - 탭 없는 네비게이션 구조로 화면 간 이동 관리
  - 앱 생명주기에 따른 상태 관리 구현
  - _Requirements: 1.5_

- [x] 7. 퀴즈 모드 선택 화면 구현
  - QuizModeSelectionView SwiftUI 뷰 구현
  - 주관식, 객관식, 음성모드, AI 모드 선택 UI 구현
  - 각 모드별 설명 및 아이콘 표시
  - 선택된 모드를 다음 화면으로 전달하는 네비게이션 구현
  - _Requirements: 2.1_

- [x] 8. 카테고리 선택 화면 구현
  - CategorySelectionView SwiftUI 뷰 구현
  - 인물, 상식, 나라, 드라마, 음악 카테고리 UI 구현
  - 스테이지 형식 vs 개별 형식 선택 토글 구현
  - 전체 무작위 vs 풀었던 것 제외 옵션 구현
  - _Requirements: 2.2, 2.3, 3.1_

- [x] 9. 로컬 우선 퀴즈 데이터 관리 시스템 구현
  - LocalDataManager 구현 (로컬 데이터 우선 로드)
  - 정적 설정 파일에서 퀴즈 버전 체크 로직 구현
  - Supabase Storage에서 직접 JSON 파일 다운로드 기능 구현
  - 다운로드된 데이터를 SwiftData에 저장하는 로직 구현
  - 완전 오프라인 모드 지원 (모든 퀴즈 기능 동작)
  - maintenance_mode 및 feature_flags 처리 로직 구현
  - 정적 설정 캐싱 및 만료 관리 시스템 구현
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

- [x] 10. 퀴즈 플레이 화면 구현
  - QuizPlayView SwiftUI 뷰 구현
  - 문제 표시 및 답안 입력 UI 구현
  - 객관식 선택지 및 주관식 텍스트 입력 처리
  - 진행률 표시 및 타이머 기능 구현
  - 다음 문제로 넘어가는 네비게이션 구현
  - _Requirements: 2.4, 2.5_

- [x] 11. 퀴즈 로직 및 상태 관리 구현
  - QuizViewModel에서 문제 로딩 로직 구현
  - 사용자 답안 검증 및 점수 계산 로직 구현
  - 풀었던 문제 필터링 로직 구현
  - 퀴즈 세션 진행 상태 관리 구현
  - _Requirements: 3.2, 3.3, 3.4_

- [x] 12. 퀴즈 결과 저장 및 히스토리 구현
  - 퀴즈 완료 시 결과를 SwiftData에 저장하는 로직 구현
  - HistoryView에서 퀴즈 히스토리 목록 표시 구현
  - 날짜, 카테고리, 점수, 소요시간 표시 UI 구현
  - HistoryDetailView에서 상세 결과 표시 구현
  - _Requirements: 4.1, 4.2, 4.3_

- [x] 13. 프로필 및 설정 화면 구현
  - ProfileView SwiftUI 뷰 구현
  - 사용자 정보 표시 및 로그아웃 기능 구현
  - 다크모드 토글 설정 구현
  - 기타 앱 설정 옵션 UI 구현
  - _Requirements: 5.1, 5.3, 5.4_

- [x] 14. 로컬 우선 데이터 동기화 시스템 구현
  - SyncManager Actor 클래스 구현 (로컬 우선 아키텍처)
  - 퀴즈 완료 시 로컬 저장 및 동기화 대기 상태 표시 구현
  - 수동 동기화 버튼 클릭 시 배치 업로드 로직 구현
  - 리더보드 하루 1회 업데이트 로직 구현
  - 동기화 진행률 표시 및 마지막 동기화 시간 표시 구현
  - 오프라인 상태에서도 모든 기능 정상 동작 보장
  - 동기화 상태 표시 및 에러 처리 구현
  - _Requirements: 5.2, 5.3, 5.4, 5.7_

- [x] 15. AdMob 광고 통합 구현
  - Google AdMob SDK 통합 및 설정
  - 퀴즈 완료 후 전면 광고 표시 로직 구현
  - 광고 로드 실패 시 정상 진행 처리 구현
  - 광고 시청 보상 시스템 구현 (선택사항)
  - _Requirements: 7.1, 7.2, 7.3_

- [x] 16. 음성 모드 퀴즈 기능 구현
  - AVFoundation을 사용한 음성 재생 기능 구현
  - 음성 인식을 통한 답안 입력 기능 구현
  - 음성 파일 다운로드 및 캐싱 시스템 구현
  - 음성 모드 전용 UI 컴포넌트 구현
  - _Requirements: 2.1_

- [x] 17. AI 모드 퀴즈 기능 구현
  - AI 기반 문제 생성 API 연동 구현
  - 동적 문제 생성 및 난이도 조절 로직 구현
  - AI 모드 전용 UI 및 사용자 경험 구현
  - AI 응답 파싱 및 검증 로직 구현
  - _Requirements: 2.1_

- [x] 18. 정적 설정 관리 시스템 구현
  - 정적 설정 파일 구조 정의 및 검증 로직 구현
  - Supabase Storage에서 정적 설정 파일 다운로드 구현
  - 정적 설정 캐싱 및 만료 관리 시스템 구현
  - feature_flags 기반 기능 활성화/비활성화 로직 구현
  - maintenance_mode 처리 및 점검 화면 구현
  - 오프라인 시 캐싱된 정적 설정 사용 로직 구현
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

- [x] 19. 로컬 우선 아키텍처 완전 구현
  - 모든 퀴즈 기능의 완전 오프라인 동작 보장
  - 로컬 통계 계산 및 표시 시스템 구현
  - 동기화 대기 상태 표시 및 관리 시스템 구현
  - 배치 동기화 및 진행률 표시 구현
  - 리더보드 캐시 관리 및 하루 1회 업데이트 구현
  - 로컬 데이터 우선 로드 및 백그라운드 업데이트 구현
  - _Requirements: 5.3, 5.4, 5.7_

- [x] 20. 보안 강화 및 세션 관리 구현
  - 세션 타임아웃 및 자동 갱신 로직 구현
  - 로그인 시도 제한 및 계정 잠금 기능 구현
  - 보안 이벤트 로깅 (로컬) 시스템 구현
  - 앱 버전 호환성 검증 및 업데이트 안내 구현
  - 게스트 계정 24시간 제한 로직 구현
  - _Requirements: 1.7, 1.8, 1.9_

- [x] 21. 에러 처리 및 사용자 피드백 구현
  - 네트워크 에러 처리 및 재시도 로직 구현
  - 사용자 친화적 에러 메시지 표시 구현
  - 로딩 상태 표시 및 프로그레스 인디케이터 구현
  - 토스트 메시지 및 알림 시스템 구현
  - 오프라인 상태 표시 및 안내 구현
  - _Requirements: 6.5_

- [x] 22. 접근성 및 사용성 개선 구현
  - VoiceOver 지원을 위한 accessibility label 추가
  - 동적 타입 크기 지원 구현
  - 키보드 네비게이션 지원 구현
  - 색상 대비 및 WCAG 가이드라인 준수 확인
  - _Requirements: 8.4_

- [ ] 23. 단위 테스트 및 통합 테스트 구현
  - ViewModel 로직에 대한 단위 테스트 작성
  - Repository 및 UseCase 테스트 작성
  - SwiftData 저장소 통합 테스트 작성
  - 인증 플로우 통합 테스트 작성
  - _Requirements: 8.1_

- [x] 24. UI 테스트 및 접근성 테스트 구현
  - 주요 사용자 플로우 UI 테스트 작성
  - 다크모드 전환 테스트 작성
  - 접근성 기능 테스트 작성
  - 다양한 디바이스 크기 대응 테스트 작성
  - _Requirements: 8.4_

- [ ] 25. 성능 최적화 및 메모리 관리 구현
  - SwiftData lazy loading 최적화 구현
  - 이미지 캐싱 및 압축 시스템 구현
  - 백그라운드 작업 정리 로직 구현
  - 메모리 누수 방지 및 성능 모니터링 구현
  - _Requirements: 8.3_

- [ ] 26. 최종 통합 및 앱 완성
  - 모든 모듈 간 연동 테스트 및 버그 수정
  - 앱 아이콘 및 스플래시 스크린 구현
  - 앱스토어 배포를 위한 메타데이터 준비
  - 최종 사용자 테스트 및 피드백 반영
  - _Requirements: 8.5_