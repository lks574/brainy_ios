# Requirements Document

## Introduction

Brainy는 다양한 형태의 퀴즈를 제공하는 iOS 앱입니다. 사용자는 여러 로그인 방식으로 인증하고, 카테고리별 퀴즈를 단계적으로 풀며, 진행 상황을 동기화할 수 있습니다. Swift 6와 SwiftData를 활용한 클린 아키텍처로 구현되며, 최소한의 서버 통신으로 효율적인 사용자 경험을 제공합니다.

## Requirements

### Requirement 1

**User Story:** 사용자로서, 다양한 방식으로 로그인하고 싶습니다. 그래야 편리하게 앱을 사용할 수 있습니다.

#### Acceptance Criteria

1. WHEN 앱을 처음 실행하면 THEN 시스템은 정적 설정을 확인하고 허용된 로그인 방식만 표시해야 합니다
2. WHEN 사용자가 이메일 로그인을 선택하면 THEN 시스템은 정적 설정의 비밀번호 정책을 적용하여 검증해야 합니다
3. WHEN 사용자가 Google 로그인을 선택하면 THEN 시스템은 정적 설정에서 소셜 로그인 허용 여부를 확인하고 OAuth 인증을 진행해야 합니다
4. WHEN 사용자가 Apple 로그인을 선택하면 THEN 시스템은 정적 설정에서 Apple 로그인 허용 여부를 확인하고 Sign in with Apple을 진행해야 합니다
5. WHEN 사용자가 게스트 로그인을 선택하면 THEN 시스템은 정적 설정의 게스트 모드 허용 여부를 확인하고 임시 계정을 생성해야 합니다
6. WHEN 로그인이 성공하면 THEN 시스템은 세션 정보를 저장하고 메인 퀴즈 화면으로 이동해야 합니다
7. WHEN 앱 버전이 최소 요구 버전보다 낮으면 THEN 시스템은 업데이트 안내를 표시해야 합니다
8. WHEN 최대 로그인 시도 횟수를 초과하면 THEN 시스템은 계정 잠금 메시지를 표시해야 합니다
9. WHEN 세션이 만료되면 THEN 시스템은 정적 설정에 따라 자동 갱신하거나 재로그인을 요구해야 합니다

### Requirement 2

**User Story:** 사용자로서, 다양한 형태의 퀴즈를 풀고 싶습니다. 그래야 재미있게 학습할 수 있습니다.

#### Acceptance Criteria

1. WHEN 메인 화면에 접근하면 THEN 시스템은 주관식, 객관식, 음성모드, AI 모드 퀴즈 옵션을 제공해야 합니다
2. WHEN 사용자가 퀴즈 모드를 선택하면 THEN 시스템은 카테고리 선택 화면을 표시해야 합니다
3. WHEN 사용자가 카테고리를 선택하면 THEN 시스템은 인물, 상식, 나라, 드라마, 음악 등의 옵션을 제공해야 합니다
4. WHEN 사용자가 스테이지 형식을 선택하면 THEN 시스템은 순차적인 문제 진행을 제공해야 합니다
5. WHEN 사용자가 개별 형식을 선택하면 THEN 시스템은 독립적인 문제 풀이를 제공해야 합니다

### Requirement 3

**User Story:** 사용자로서, 퀴즈 문제를 선택적으로 풀고 싶습니다. 그래야 효율적으로 학습할 수 있습니다.

#### Acceptance Criteria

1. WHEN 퀴즈 시작 전에 THEN 시스템은 "전체 무작위" 또는 "풀었던 것 제외" 옵션을 제공해야 합니다
2. WHEN "전체 무작위"를 선택하면 THEN 시스템은 모든 문제에서 랜덤하게 선택해야 합니다
3. WHEN "풀었던 것 제외"를 선택하면 THEN 시스템은 이전에 풀지 않은 문제만 제공해야 합니다
4. WHEN 문제를 풀면 THEN 시스템은 해당 문제를 풀이 완료로 기록해야 합니다

### Requirement 4

**User Story:** 사용자로서, 내 퀴즈 히스토리를 확인하고 싶습니다. 그래야 진행 상황을 파악할 수 있습니다.

#### Acceptance Criteria

1. WHEN 히스토리 화면에 접근하면 THEN 시스템은 풀었던 퀴즈 목록을 표시해야 합니다
2. WHEN 히스토리를 조회하면 THEN 시스템은 날짜, 카테고리, 점수, 소요시간을 표시해야 합니다
3. WHEN 특정 히스토리를 선택하면 THEN 시스템은 상세 결과를 표시해야 합니다

### Requirement 5

**User Story:** 사용자로서, 로컬 우선으로 내 정보와 설정을 관리하고 싶습니다. 그래야 오프라인에서도 앱을 개인화할 수 있습니다.

#### Acceptance Criteria

1. WHEN 내정보 화면에 접근하면 THEN 시스템은 로컬에 저장된 사용자 정보와 설정 옵션을 표시해야 합니다
2. WHEN 동기화 버튼을 누르면 THEN 시스템은 대기 중인 모든 퀴즈 결과를 배치로 서버에 업로드해야 합니다
3. WHEN 동기화가 진행되면 THEN 시스템은 진행률과 마지막 동기화 시간을 표시해야 합니다
4. WHEN 리더보드를 조회하면 THEN 시스템은 로컬 캐시 데이터를 표시하고 마지막 업데이트 시간을 보여줘야 합니다
5. WHEN 로그아웃을 선택하면 THEN 시스템은 세션을 무효화하고 로그인 화면으로 이동해야 합니다
6. WHEN 다크모드 설정을 변경하면 THEN 시스템은 즉시 테마를 적용하고 로컬에 저장해야 합니다
7. WHEN 오프라인 상태여도 THEN 시스템은 모든 설정 변경과 프로필 조회가 정상 동작해야 합니다

### Requirement 6

**User Story:** 사용자로서, 비용 효율적이고 오프라인 우선으로 퀴즈 데이터를 관리하고 싶습니다. 그래야 언제든지 퀴즈를 풀 수 있습니다.

#### Acceptance Criteria

1. WHEN 앱을 시작하면 THEN 시스템은 로컬 데이터를 우선 로드하고 백그라운드에서 버전만 체크해야 합니다
2. WHEN 정적 설정 파일에서 퀴즈 버전이 다르면 THEN 시스템은 업데이트 알림을 표시해야 합니다
3. WHEN 사용자가 업데이트를 선택하면 THEN 시스템은 Supabase Storage에서 직접 JSON 파일을 다운로드해야 합니다
4. WHEN 퀴즈 데이터를 받으면 THEN 시스템은 SwiftData에 저장하고 로컬 캐시를 업데이트해야 합니다
5. WHEN 네트워크가 없어도 THEN 시스템은 완전히 오프라인으로 모든 퀴즈 기능이 동작해야 합니다
6. WHEN maintenance_mode가 true면 THEN 시스템은 점검 화면을 표시해야 합니다
7. WHEN 정적 설정에서 feature_flags를 확인하면 THEN 시스템은 해당 기능의 활성화 여부를 결정해야 합니다

### Requirement 7

**User Story:** 사용자로서, 광고를 통해 무료로 앱을 사용하고 싶습니다. 그래야 비용 부담 없이 퀴즈를 풀 수 있습니다.

#### Acceptance Criteria

1. WHEN 퀴즈를 완료하면 THEN 시스템은 AdMob 광고를 표시해야 합니다
2. WHEN 광고가 로드되지 않으면 THEN 시스템은 정상적으로 다음 단계로 진행해야 합니다
3. WHEN 광고를 시청하면 THEN 시스템은 보상을 제공해야 합니다

### Requirement 8

**User Story:** 사용자로서, 정적 설정 기반으로 앱 기능을 제어하고 싶습니다. 그래야 서버 부하 없이 앱 설정을 관리할 수 있습니다.

#### Acceptance Criteria

1. WHEN 앱이 시작되면 THEN 시스템은 정적 설정 파일을 로드하여 기능 활성화 여부를 결정해야 합니다
2. WHEN 정적 설정에서 auth_methods_enabled를 확인하면 THEN 시스템은 허용된 로그인 방식만 표시해야 합니다
3. WHEN 정적 설정에서 feature_flags를 확인하면 THEN 시스템은 AI 퀴즈, 음성 모드, 오프라인 모드 활성화를 결정해야 합니다
4. WHEN 정적 설정에서 maintenance_mode가 true면 THEN 시스템은 점검 화면을 표시해야 합니다
5. WHEN 정적 설정이 업데이트되면 THEN 시스템은 새로운 설정을 다운로드하고 캐시를 갱신해야 합니다
6. WHEN 오프라인 상태면 THEN 시스템은 마지막으로 캐싱된 정적 설정을 사용해야 합니다

### Requirement 9

**User Story:** 개발자로서, 유지보수 가능한 코드를 작성하고 싶습니다. 그래야 장기적으로 앱을 발전시킬 수 있습니다.

#### Acceptance Criteria

1. WHEN 코드를 작성하면 THEN 시스템은 클린 아키텍처 패턴을 따라야 합니다
2. WHEN 데이터를 저장하면 THEN 시스템은 SwiftData를 사용해야 합니다
3. WHEN 비동기 작업을 수행하면 THEN 시스템은 Swift Concurrency를 사용해야 합니다
4. WHEN UI를 구성하면 THEN 시스템은 디자인 시스템을 적용해야 합니다
5. WHEN 색상을 사용하면 THEN 시스템은 Asset Catalog의 GeneratedAssetSymbols 기능을 사용해야 합니다
6. WHEN 앱을 빌드하면 THEN 시스템은 iOS 17 이상에서 동작해야 합니다
7. WHEN 개발 환경을 설정하면 THEN 시스템은 Xcode 16 이상을 사용해야 합니다
8. WHEN 외부 라이브러리를 추가하면 THEN 시스템은 Swift Package Manager(SPM)만을 사용해야 합니다
9. WHEN 폴더 구조를 생성하면 THEN 시스템은 .gitkeep 파일을 생성하지 않아야 합니다
10. WHEN SwiftUI 뷰를 작성하면 THEN 시스템은 #Preview를 생성하지 않아야 합니다