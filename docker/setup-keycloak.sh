#!/bin/bash
set -e

echo "Waiting for Keycloak to be ready..."
until curl -f http://localhost:8081/admin/ > /dev/null 2>&1; do
  echo "Keycloak not ready yet, waiting..."
  sleep 5
done

echo "Getting admin token..."
ADMIN_TOKEN=$(curl -s -X POST http://localhost:8081/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin" \
  -d "password=admin" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" | jq -r .access_token)

if [ "$ADMIN_TOKEN" = "null" ] || [ -z "$ADMIN_TOKEN" ]; then
  echo "Failed to get admin token"
  exit 1
fi

echo "Creating console-proxy realm..."
curl -s -X POST http://localhost:8081/admin/realms \
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
curl -s -X POST http://localhost:8081/admin/realms/console-proxy/clients \
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
curl -s -X POST http://localhost:8081/admin/realms/console-proxy/users \
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
echo "🌐 OIDC Endpoint: http://localhost:8081/realms/console-proxy"