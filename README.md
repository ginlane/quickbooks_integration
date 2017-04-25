# Quickbooks Online Integration

## Overview

[Quickbooks](http://quickbooks.intuit.com) is an accounting software package developed and marketed by [Intuit](http://www.intuit.com). This implementation uses the [Quickbooks v3 API](https://developer.intuit.com/apiexplorer?apiname=V3QBO) through the [quickbooks-ruby](https://github.com/ruckus/quickbooks-ruby) gem.

Please visit the [wiki](https://github.com/flowlink/quickbooks_integration/wiki)
for further info on how to connect this integration.

This is a fully hosted and supported integration for use with the [FlowLink](http://flowlink.io/)
product. With this integration you can perform the following functions:

* Send orders to Quickbooks as Invoices
* Send products to Quickbooks as Items
* Send returns to Quickbooks as Credit Memo
* Poll for inventory stock levels in Quickbooks

### 21 Character limit on Order numbers.

If your having problems with it, this transform should help:
```javascript
//nomustache
payload.order.number = payload.order.number.substring(0, 21);
```

## Development

### Generate OAuth Keys

Create an app here: https://developer.intuit.com/v2/ui#/app/dashboard and generate your oauth keys.

### Environment Variables

Copy "sample.env" to ".env" and fill out the following variables:

`QB_CONSUMER_KEY` - OAuth consumer key

`QB_CONSUMER_KEY` - OAuth token

`CALLBACK_URL` - the URL to use for authorization callback

# Starting Application

`bundle exec unicorn` -- Starts application on port 8080

# Getting OAuth on Local

1. Log in to your Quickbooks account
1. Start ngrok to enable external access
   `ngrok http 8080`
1. Set consumer key, secret, and callback url (using ngrok as host) in .env (source it if necessary)
1. Spin up server
    `PORT=8080 foreman run web`
1. GET /auth to authorize app and get request token
1. Go through QB auth flow until you've been redirected to the callback url
1. Make note of the token, verifier, and realm in the response
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
