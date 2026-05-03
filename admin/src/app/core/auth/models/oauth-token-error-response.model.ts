/**
 * OAuth 2.0 token endpoint error (RFC 6749), e.g. `invalid_grant` from resource-owner validation.
 * Backend returns JSON with snake_case keys (serializer uses literal property names).
 */
export interface OAuthTokenErrorResponse {
  error: string;
  error_description?: string;
}
