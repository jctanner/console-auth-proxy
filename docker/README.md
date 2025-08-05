# Docker Development Environment

This directory contains Docker configuration and setup scripts for the console-auth-proxy development environment.

## Quick Start

1. **Set up environment variables** (required for external Keycloak):
   ```bash
   # Copy the example file
   cp env.example .env
   
   # Edit .env and set your Keycloak admin password
   # KEYCLOAK_ADMIN_PASSWORD=your-actual-password
   ```

2. **Load environment variables**:
   ```bash
   source .env
   # or
   export KEYCLOAK_ADMIN_PASSWORD="your-password"
   ```

3. **Set up Keycloak realm and client**:
   ```bash
   ./docker/setup-keycloak.sh
   ```

4. **Start the development environment**:
   ```bash
   podman compose up -d
   ```

## Environment Variables

### Required
- `KEYCLOAK_ADMIN_PASSWORD`: Password for the Keycloak admin user

### Optional
- `KEYCLOAK_URL`: Keycloak server URL (default: `https://keycloak.tannerjc.net`)
- `KEYCLOAK_ADMIN`: Keycloak admin username (default: `admin`)

## Services

### Console Auth Proxy
- **Port**: 8080
- **URL**: http://localhost:8080
- Authenticates via external Keycloak and forwards requests to backend

### Backend Echo Service  
- **Port**: 3000
- **URL**: http://localhost:3000
- Returns all HTTP headers for testing proxy behavior

### External Keycloak
- **URL**: https://keycloak.tannerjc.net
- **Admin Console**: https://keycloak.tannerjc.net/admin
- **Realm**: `console-proxy`
- **Test User**: `testuser/testpass`

## Testing

1. Visit http://localhost:8080
2. You'll be redirected to Keycloak for authentication
3. Login with `testuser/testpass`
4. After authentication, you'll see the backend echo service response
5. Check http://localhost:3000 to see all forwarded headers

## Security Notes

- Never commit `.env` files or passwords to git
- The `.gitignore` already excludes `*.env` files
- Use environment variables for all sensitive configuration