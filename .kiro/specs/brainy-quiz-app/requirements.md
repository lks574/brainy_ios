# Requirements Document

## Introduction

Brainy는 다양한 형태의 퀴즈를 제공하는 iOS 앱입니다. 사용자는 여러 로그인 방식으로 인증하고, 카테고리별 퀴즈를 단계적으로 풀며, 진행 상황을 동기화할 수 있습니다. Swift 6와 SwiftData를 활용한 클린 아키텍처로 구현되며, 최소한의 서버 통신으로 효율적인 사용자 경험을 제공합니다.

## Requirements

### Requirement 1

**User Story:** 사용자로서, 다양한 방식으로 로그인하고 싶습니다. 그래야 편리하게 앱을 사용할 수 있습니다.

#### Acceptance Criteria

1. WHEN 앱을 처음 실행하면 THEN 시스템은 로그인 화면을 표시해야 합니다
2. WHEN 사용자가 이메일 로그인을 선택하면 THEN 시스템은 이메일과 비밀번호 입력 필드를 제공해야 합니다
3. WHEN 사용자가 Google 로그인을 선택하면 THEN 시스템은 Google OAuth 인증을 진행해야 합니다
4. WHEN 사용자가 Apple 로그인을 선택하면 THEN 시스템은 Sign in with Apple을 진행해야 합니다
5. WHEN 로그인이 성공하면 THEN 시스템은 메인 퀴즈 화면으로 이동해야 합니다

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

**User Story:** 사용자로서, 내 정보와 설정을 관리하고 싶습니다. 그래야 앱을 개인화할 수 있습니다.

#### Acceptance Criteria

1. WHEN 내정보 화면에 접근하면 THEN 시스템은 로그인 정보와 설정 옵션을 표시해야 합니다
2. WHEN 동기화 버튼을 누르면 THEN 시스템은 현재까지의 진행 내용을 서버에 저장해야 합니다
3. WHEN 로그아웃을 선택하면 THEN 시스템은 로그인 화면으로 이동해야 합니다
4. WHEN 다크모드 설정을 변경하면 THEN 시스템은 즉시 테마를 적용해야 합니다

### Requirement 6

**User Story:** 사용자로서, 최신 퀴즈 데이터를 받고 싶습니다. 그래야 새로운 문제를 풀 수 있습니다.

#### Acceptance Criteria

1. WHEN 앱을 시작하면 THEN 시스템은 퀴즈 버전을 확인해야 합니다
2. WHEN 서버의 퀴즈 버전이 다르면 THEN 시스템은 새로운 퀴즈 데이터를 다운로드해야 합니다
3. WHEN 퀴즈 데이터를 받으면 THEN 시스템은 SwiftData에 저장해야 합니다
4. WHEN 네트워크가 없으면 THEN 시스템은 로컬 데이터로 동작해야 합니다

### Requirement 7

**User Story:** 사용자로서, 광고를 통해 무료로 앱을 사용하고 싶습니다. 그래야 비용 부담 없이 퀴즈를 풀 수 있습니다.

#### Acceptance Criteria

1. WHEN 퀴즈를 완료하면 THEN 시스템은 AdMob 광고를 표시해야 합니다
2. WHEN 광고가 로드되지 않으면 THEN 시스템은 정상적으로 다음 단계로 진행해야 합니다
3. WHEN 광고를 시청하면 THEN 시스템은 보상을 제공해야 합니다

### Requirement 8

**User Story:** 개발자로서, 유지보수 가능한 코드를 작성하고 싶습니다. 그래야 장기적으로 앱을 발전시킬 수 있습니다.

#### Acceptance Criteria

1. WHEN 코드를 작성하면 THEN 시스템은 클린 아키텍처 패턴을 따라야 합니다
2. WHEN 데이터를 저장하면 THEN 시스템은 SwiftData를 사용해야 합니다
3. WHEN 비동기 작업을 수행하면 THEN 시스템은 Swift Concurrency를 사용해야 합니다
4. WHEN UI를 구성하면 THEN 시스템은 디자인 시스템을 적용해야 합니다
5. WHEN 앱을 빌드하면 THEN 시스템은 iOS 17 이상에서 동작해야 합니다
6. WHEN 외부 라이브러리를 추가하면 THEN 시스템은 Swift Package Manager(SPM)만을 사용해야 합니다