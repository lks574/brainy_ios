# Authentication System

This document describes the authentication system implementation for the Brainy Backend API.

## Overview

The authentication system provides secure user authentication and authorization using Supabase Auth with support for:

- Email/password authentication
- Google OAuth integration
- Apple Sign-in integration
- JWT token verification and refresh
- Rate limiting protection
- Input validation and sanitization

## API Endpoints

### POST /auth/signup
Creates a new user account with email and password.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123",
  "display_name": "User Name" // optional
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "access_token": "jwt_token_here",
    "refresh_token": "refresh_token_here",
    "expires_in": 3600,
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "display_name": "User Name",
      "auth_provider": "email",
      "created_at": "2024-01-01T00:00:00Z"
    }
  }
}
```

### POST /auth/signin
Authenticates a user with email and password.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword123"
}
```

**Response:** Same as signup response.

### POST /auth/oauth
Authenticates a user with OAuth provider (Google or Apple).

**Request Body:**
```json
{
  "provider": "google", // or "apple"
  "token": "oauth_token_from_provider"
}
```

**Response:** Same as signup response.

### POST /auth/refresh
Refreshes an expired access token using a refresh token.

**Request Body:**
```json
{
  "refresh_token": "refresh_token_here"
}
```

**Response:** Same as signup response with new tokens.

### GET /auth/user
Retrieves the current user's profile information.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "email": "user@example.com",
    "display_name": "User Name",
    "auth_provider": "email",
    "created_at": "2024-01-01T00:00:00Z",
    "last_sync_at": "2024-01-01T12:00:00Z"
  }
}
```

### PUT /auth/user
Updates the current user's profile information.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "display_name": "New Display Name",
  "email": "newemail@example.com" // optional
}
```

**Response:** Updated user object.

### POST /auth/signout
Signs out the current user and invalidates the token.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Successfully signed out"
  }
}
```

## Security Features

### Rate Limiting
- Authentication endpoints are rate limited to 5 requests per 15 minutes per IP
- Prevents brute force attacks and abuse

### Input Validation
- Email format validation
- Password minimum length (6 characters)
- Display name maximum length (100 characters)
- Request sanitization to prevent injection attacks

### JWT Token Security
- Tokens are signed with RS256 algorithm
- Access tokens expire in 1 hour (configurable)
- Refresh tokens can be used to obtain new access tokens
- Tokens include user ID, email, and role claims

### Row Level Security (RLS)
- Database policies ensure users can only access their own data
- Service role can access all data for admin functions
- Policies are enforced at the database level

## OAuth Integration

### Google OAuth
1. Client obtains Google OAuth token from Google Sign-In SDK
2. Client sends token to `/auth/oauth` endpoint
3. Server verifies token with Google's API
4. Server creates or updates user account
5. Server returns JWT tokens for API access

### Apple Sign-in
1. Client obtains Apple ID token from Apple Sign-In SDK
2. Client sends token to `/auth/oauth` endpoint
3. Server verifies token with Apple's API
4. Server creates or updates user account
5. Server returns JWT tokens for API access

## Error Handling

The authentication system returns standardized error responses:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {} // optional additional details
  }
}
```

### Error Codes
- `VALIDATION_ERROR`: Invalid input data
- `AUTHENTICATION_FAILED`: Invalid credentials or token
- `AUTHORIZATION_FAILED`: Insufficient permissions
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `INTERNAL_SERVER_ERROR`: Server error

## Usage Examples

### iOS Swift Integration
```swift
// Sign up new user
let signupData = [
    "email": "user@example.com",
    "password": "securepassword123",
    "display_name": "User Name"
]

// Sign in existing user
let signinData = [
    "email": "user@example.com",
    "password": "securepassword123"
]

// OAuth with Google
let oauthData = [
    "provider": "google",
    "token": googleToken
]

// Make authenticated request
let headers = [
    "Authorization": "Bearer \(accessToken)",
    "Content-Type": "application/json"
]
```

### JavaScript Integration
```javascript
// Sign up
const response = await fetch('/auth/signup', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    email: 'user@example.com',
    password: 'securepassword123',
    display_name: 'User Name'
  })
});

// Get user info
const userResponse = await fetch('/auth/user', {
  headers: { 'Authorization': `Bearer ${accessToken}` }
});
```

## Testing

Run the authentication test suite:

```bash
npm run test:auth
# or
node scripts/test-auth-system.js
```

The test suite covers:
- User signup and signin
- OAuth authentication simulation
- Token refresh functionality
- User profile management
- Rate limiting verification
- Input validation testing

## Configuration

### Environment Variables
```bash
# Supabase Configuration
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# OAuth Configuration
SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID=your-google-client-id
SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET=your-google-client-secret
SUPABASE_AUTH_EXTERNAL_APPLE_CLIENT_ID=your-apple-client-id
SUPABASE_AUTH_EXTERNAL_APPLE_SECRET=your-apple-client-secret
```

### Supabase Configuration
The authentication system is configured in `supabase/config.toml`:

```toml
[auth]
enabled = true
site_url = "http://localhost:3000"
jwt_expiry = 3600
enable_signup = true

[auth.external.google]
enabled = true
client_id = "env(SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID)"
secret = "env(SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET)"

[auth.external.apple]
enabled = true
client_id = "env(SUPABASE_AUTH_EXTERNAL_APPLE_CLIENT_ID)"
secret = "env(SUPABASE_AUTH_EXTERNAL_APPLE_SECRET)"
```

## Deployment

### Local Development
1. Start Supabase: `supabase start`
2. Deploy function: `supabase functions deploy auth`
3. Test endpoints: `node scripts/test-auth-system.js`

### Production Deployment
1. Configure production environment variables
2. Deploy to Supabase: `supabase functions deploy auth --project-ref your-project-ref`
3. Update OAuth redirect URLs in provider consoles
4. Test production endpoints

## Monitoring and Logging

The authentication system includes comprehensive logging:
- All authentication attempts (success/failure)
- Rate limiting violations
- OAuth provider interactions
- Token refresh operations
- Error conditions and stack traces

Logs can be viewed with:
```bash
supabase logs --type functions --filter auth
```

## Security Considerations

1. **Token Storage**: Store tokens securely on client (iOS Keychain)
2. **HTTPS Only**: Always use HTTPS in production
3. **Token Expiration**: Implement proper token refresh logic
4. **Rate Limiting**: Monitor and adjust rate limits as needed
5. **OAuth Security**: Validate OAuth tokens server-side
6. **Input Sanitization**: All inputs are validated and sanitized
7. **Database Security**: RLS policies enforce data access controls

## Troubleshooting

### Common Issues

1. **Invalid Token Error**
   - Check token expiration
   - Verify token format (Bearer prefix)
   - Ensure token was issued by correct Supabase instance

2. **OAuth Failures**
   - Verify OAuth provider configuration
   - Check client ID and secret
   - Ensure redirect URLs are configured correctly

3. **Rate Limiting**
   - Implement exponential backoff
   - Check IP-based rate limiting
   - Consider user-based rate limiting for authenticated requests

4. **Database Connection Issues**
   - Verify Supabase connection string
   - Check database migrations are applied
   - Ensure RLS policies are enabled