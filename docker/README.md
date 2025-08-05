# Docker Compose Testing Environment

This directory contains a complete Docker Compose setup for testing the console-auth-proxy with a Keycloak OIDC provider and an echo service backend.

## Services

- **console-auth-proxy**: The main authentication proxy service (port 8080)
- **keycloak**: OIDC authentication provider (port 8081) 
- **backend-app**: Echo service that returns all headers and request info (port 3000)

## Quick Start

1. **Start all services:**
   ```bash
   docker-compose up --build
   ```

2. **Wait for services to be ready** (about 60-90 seconds)
   - Console Auth Proxy: http://localhost:8080
   - Keycloak Admin: http://localhost:8081 (admin/admin)
   - Backend Echo Service: http://localhost:3000

3. **Test the authentication flow:**
   - Visit http://localhost:8080
   - You'll be redirected to Keycloak for login
   - Use one of the test users:
     - Username: `testuser` / Password: `testpass`
     - Username: `admin` / Password: `admin`
   - After login, you'll see the echo service response with all forwarded headers

## What You'll See

When successfully authenticated, the echo service will return a JSON response showing:

```json
{
  "path": "/",
  "headers": {
    "authorization": "Bearer eyJhbGciOiJSUzI1NiIs...",
    "x-forwarded-user": "testuser",
    "x-forwarded-user-id": "12345678-1234-1234-1234-123456789abc",
    "x-forwarded-email": "testuser@example.com",
    "host": "backend-app:8080",
    "user-agent": "console-auth-proxy/dev",
    ...
  },
  "method": "GET",
  "body": "",
  "fresh": false,
  "hostname": "backend-app",
  "ip": "::ffff:172.x.x.x",
  "ips": [],
  "protocol": "http",
  "query": {},
  "subdomains": [],
  "xhr": false
}
```

## Key Headers to Look For

The console-auth-proxy forwards these authentication headers to the backend:

- `Authorization: Bearer <jwt-token>` - The OIDC access token
- `X-Forwarded-User: <username>` - The authenticated username
- `X-Forwarded-User-ID: <user-id>` - The user's unique ID
- `X-Forwarded-Email: <email>` - The user's email address

## Testing Different Scenarios

### Test Direct Backend Access
```bash
# This should work (no auth required)
curl http://localhost:3000
```

### Test Proxy Without Authentication
```bash
# This should redirect to Keycloak
curl -L http://localhost:8080
```

### Test Health Endpoints
```bash
# These should work without authentication
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
curl http://localhost:8080/metrics
curl http://localhost:8080/version
```

## Keycloak Configuration

The Keycloak realm is pre-configured with:

- **Realm**: `console-proxy`
- **Client ID**: `console-auth-proxy`
- **Client Secret**: `console-secret-key`
- **Test Users**:
  - `testuser` / `testpass`
  - `admin` / `admin`

## Troubleshooting

### Services Not Starting
```bash
# Check service status
docker-compose ps

# View logs
docker-compose logs console-auth-proxy
docker-compose logs keycloak
docker-compose logs backend-app
```

### Keycloak Not Ready
Wait for the health check to pass:
```bash
# Check if Keycloak is healthy
curl http://localhost:8081/realms/console-proxy
```

### Authentication Issues
1. Make sure Keycloak is fully started (check logs)
2. Verify the realm configuration was imported
3. Check console-auth-proxy logs for OIDC discovery issues

### Clean Reset
```bash
# Stop and remove everything
docker-compose down -v

# Rebuild and restart
docker-compose up --build
```

## Development

### Modify Configuration
Edit the environment variables in `docker-compose.yaml` to test different configurations.

### Custom Keycloak Realm
Modify `docker/keycloak-realm.json` to customize the OIDC configuration.

### View Raw Tokens
The echo service shows the raw JWT token in the `Authorization` header. You can decode it at https://jwt.io to see the claims.