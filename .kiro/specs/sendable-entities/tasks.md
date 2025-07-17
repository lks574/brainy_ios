# 구현 계획

- [ ] 1. QuizCategory 열거형에 Sendable 준수 추가
  - QuizCategory 열거형 선언에 Sendable 프로토콜 준수 추가
  - 경고 없이 컴파일이 성공하는지 확인
  - _요구사항: 2.1_

- [ ] 2. QuizType 열거형에 Sendable 준수 추가
  - QuizType 열거형 선언에 Sendable 프로토콜 준수 추가
  - 경고 없이 컴파일이 성공하는지 확인
  - _요구사항: 2.2_

- [ ] 3. QuizMode 열거형에 Sendable 준수 추가
  - QuizMode 열거형 선언에 Sendable 프로토콜 준수 추가
  - 경고 없이 컴파일이 성공하는지 확인
  - _요구사항: 2.3_

- [ ] 4. QuizDifficulty 열거형에 Sendable 준수 추가
  - QuizDifficulty 열거형 선언에 Sendable 프로토콜 준수 추가
  - 경고 없이 컴파일이 성공하는지 확인
  - _요구사항: 2.4_

- [ ] 5. SwiftData 엔티티의 Sendable 준수 방식 수정
  - @Model 클래스에서 직접적인 Sendable 준수 대신 @unchecked Sendable 사용
  - SwiftData의 내부 구현과 호환되도록 수정
  - 모든 Domain 엔티티(QuizQuestion, QuizResult, QuizSession, User)에 적용
  - _요구사항: 1.1, 1.2, 1.3_

- [ ] 6. 컴파일 오류 해결 확인
  - 프로젝트를 빌드하고 Sendable 관련 컴파일 오류가 해결되었는지 확인
  - 모든 Domain 엔티티들이 정상적으로 컴파일되는지 테스트
  - _요구사항: 1.1, 3.2_

- [ ] 7. 기본적인 동시성 사용 테스트 작성
  - 엔티티들이 스레드 간에 안전하게 사용될 수 있음을 보여주는 간단한 테스트 작성
  - 엔티티들이 async 함수와 actor에 전달될 수 있는지 확인
  - _요구사항: 1.1, 3.3_