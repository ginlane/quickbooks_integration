# Getting Quickbooks Integration OAuth on Local

1. Log in to the quickbooks account
1. Start ngrok to enable external access
   `ngrok http 8080`
1. Set consumer key, secret, and callback url (using ngrok as host) in .env (source it if necessary)
1. Spin up server
    `PORT=8080 foreman run web`
1. GET /auth to authorize app and get request token
1. Go through QB auth flow
1. Make note of the token, verifier, and realm ID in the response
1. Check in server logs (console output) for the request secret
1. GET /auth/get_access_token?token=XXX&secret=XXX&oauth_verifier=XXX with values set to get access token
1. Token and Secret will appear the response
1. Use token, secret, and realm in future post bodies like so:

body:

```
{
  "parameters": {
    "quickbooks_access_token": "...",
    "quickbooks_access_secret": "...",
    "quickbooks_realm": "...",
    "quickbooks_account_name": "Sales of Product Income"
  },
  "order_or_other_payload_name": {
    ...
  }
}
