# Design Document

## Overview

This design outlines the approach to make all Domain entities properly Sendable-compliant by ensuring their dependent enums also conform to the Sendable protocol. The solution focuses on adding Sendable conformance to the existing enums without breaking existing functionality.

## Architecture

The current architecture has Domain entities that depend on Core enums:

```
Domain/Entities/
├── QuizQuestion.swift (uses QuizCategory, QuizDifficulty, QuizType)
├── QuizResult.swift (uses QuizCategory, QuizMode)  
├── QuizSession.swift (uses QuizCategory, QuizMode)
└── User.swift (uses AuthProvider)

Core/Enums/
├── AuthProvider.swift (already Sendable)
├── QuizCategory.swift (needs Sendable)
├── QuizType.swift (contains QuizType, QuizMode, QuizDifficulty - all need Sendable)
```

## Components and Interfaces

### Enum Modifications

All enums that are used by Domain entities need to be updated to conform to Sendable:

1. **QuizCategory** - Add Sendable conformance
2. **QuizType** - Add Sendable conformance  
3. **QuizMode** - Add Sendable conformance
4. **QuizDifficulty** - Add Sendable conformance
5. **AuthProvider** - Already Sendable, no changes needed

### Entity Verification

The Domain entities are already marked as Sendable:
- QuizQuestion
- QuizResult  
- QuizSession
- User

Once the enums are properly Sendable, these entities will compile without warnings.

## Data Models

### Current Enum Definitions

```swift
// QuizCategory.swift
enum QuizCategory: String, CaseIterable, Codable {
    case person = "인물"
    case general = "상식"
    case country = "나라"
    case drama = "드라마"
    case music = "음악"
}

// QuizType.swift  
enum QuizType: String, CaseIterable, Codable {
    case multipleChoice = "객관식"
    case shortAnswer = "주관식"
    case voice = "음성모드"
    case ai = "AI모드"
}

enum QuizMode: String, CaseIterable, Codable {
    case stage = "스테이지"
    case individual = "개별"
}

enum QuizDifficulty: String, CaseIterable, Codable {
    case easy = "쉬움"
    case medium = "보통"
    case hard = "어려움"
}
```

### Updated Enum Definitions

```swift
// QuizCategory.swift
enum QuizCategory: String, CaseIterable, Codable, Sendable {
    case person = "인물"
    case general = "상식"
    case country = "나라"
    case drama = "드라마"
    case music = "음악"
}

// QuizType.swift
enum QuizType: String, CaseIterable, Codable, Sendable {
    case multipleChoice = "객관식"
    case shortAnswer = "주관식"
    case voice = "음성모드"
    case ai = "AI모드"
}

enum QuizMode: String, CaseIterable, Codable, Sendable {
    case stage = "스테이지"
    case individual = "개별"
}

enum QuizDifficulty: String, CaseIterable, Codable, Sendable {
    case easy = "쉬움"
    case medium = "보통"
    case hard = "어려움"
}
```

## Error Handling

Since this is a straightforward protocol conformance addition, minimal error handling is required:

1. **Compilation Errors**: If any enum cannot conform to Sendable due to non-Sendable properties, the compiler will provide clear error messages
2. **Runtime Safety**: Sendable conformance is compile-time verified, so no runtime errors are expected

## Testing Strategy

### Compilation Testing
1. Verify that all files compile without Sendable-related warnings
2. Ensure that Domain entities can be used in concurrent contexts without compiler errors

### Integration Testing  
1. Test that existing functionality remains unchanged after adding Sendable conformance
2. Verify that enums can still be used in all existing contexts (SwiftUI, SwiftData, etc.)

### Concurrent Usage Testing
1. Create simple test cases that use the entities across different threads
2. Verify that the entities can be safely passed between actors and async contexts

## Implementation Notes

- All target enums are simple value types with String raw values, making them naturally thread-safe
- Adding Sendable conformance is purely additive and won't break existing code
- The changes are minimal and focused, reducing risk of introducing bugs
- No @unchecked Sendable annotations are needed since all enum cases are immutable value types