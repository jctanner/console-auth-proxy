#!/bin/bash
set -e

# External Keycloak configuration (can be overridden with environment variables)
KEYCLOAK_URL="${KEYCLOAK_URL:-https://keycloak.tannerjc.net}"
KEYCLOAK_ADMIN="${KEYCLOAK_ADMIN:-admin}"
KEYCLOAK_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-}"

# Check if password is provided
if [ -z "$KEYCLOAK_PASSWORD" ]; then
  echo "❌ Error: KEYCLOAK_ADMIN_PASSWORD environment variable is required"
  echo "Please set it with: export KEYCLOAK_ADMIN_PASSWORD='your-password'"
  echo ""
  echo "Optional environment variables:"
  echo "  KEYCLOAK_URL (default: https://keycloak.tannerjc.net)"
  echo "  KEYCLOAK_ADMIN (default: admin)"
  exit 1
fi

echo "Connecting to external Keycloak at $KEYCLOAK_URL..."
echo "Testing connectivity..."
until curl -f $KEYCLOAK_URL/admin/ > /dev/null 2>&1; do
  echo "Keycloak not reachable yet, waiting..."
  sleep 5
done

echo "Getting admin token..."
ADMIN_TOKEN=$(curl -s -X POST $KEYCLOAK_URL/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$KEYCLOAK_ADMIN" \
  -d "password=$KEYCLOAK_PASSWORD" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r .access_token)

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
  echo "Failed to get admin token"
  exit 1
fi

echo "Creating console-proxy realm..."
curl -s -X POST $KEYCLOAK_URL/admin/realms \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "realm": "console-proxy",
    "displayName": "Console Auth Proxy Realm",
    "enabled": true,
    "registrationAllowed": true,
    "loginWithEmailAllowed": true,
    "duplicateEmailsAllowed": false,
    "resetPasswordAllowed": true,
    "editUsernameAllowed": false,
    "bruteForceProtected": false
  }'

echo "Creating OIDC client..."
curl -s -X POST $KEYCLOAK_URL/admin/realms/console-proxy/clients \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "clientId": "console-auth-proxy",
    "name": "Console Auth Proxy Client",
    "enabled": true,
    "clientAuthenticatorType": "client-secret",
    "secret": "console-secret-key",
    "redirectUris": ["http://localhost:8080/auth/callback"],
    "webOrigins": ["http://localhost:8080"],
    "standardFlowEnabled": true,
    "implicitFlowEnabled": false,
    "directAccessGrantsEnabled": true,
    "serviceAccountsEnabled": false,
    "publicClient": false,
    "frontchannelLogout": true,
    "protocol": "openid-connect",
    "attributes": {
      "saml.assertion.signature": "false",
      "saml.force.post.binding": "false",
      "saml.multivalued.roles": "false",
      "saml.encrypt": "false",
      "saml.server.signature": "false",
      "saml.server.signature.keyinfo.ext": "false",
      "exclude.session.state.from.auth.response": "false",
      "saml_force_name_id_format": "false",
      "saml.client.signature": "false",
      "tls.client.certificate.bound.access.tokens": "false",
      "saml.authnstatement": "false",
      "display.on.consent.screen": "false",
      "saml.onetimeuse.condition": "false"
    }
  }'

echo "Creating test user..."
curl -s -X POST $KEYCLOAK_URL/admin/realms/console-proxy/users \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "testuser@example.com",
    "firstName": "Test",
    "lastName": "User",
    "enabled": true,
    "emailVerified": true,
    "credentials": [{
      "type": "password",
      "value": "testpass",
      "temporary": false
    }]
  }'

echo "✅ Keycloak setup complete!"
echo "🎯 Realm: console-proxy"
echo "👤 Test user: testuser/testpass"
echo "🔑 Client: console-auth-proxy"
echo "🌐 OIDC Endpoint: $KEYCLOAK_URL/realms/console-proxy"