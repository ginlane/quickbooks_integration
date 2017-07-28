# Quickbooks Online Integration (fork for Sunday Goods)

## Overview

[Quickbooks](http://quickbooks.intuit.com) is an accounting software package developed and marketed by [Intuit](http://www.intuit.com). This implementation uses the [Quickbooks v3 API](https://developer.intuit.com/apiexplorer?apiname=V3QBO) through the [quickbooks-ruby](https://github.com/ruckus/quickbooks-ruby) gem.

With this integration you can perform the following functions:

* Send orders to Quickbooks as Invoices and Payments
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

### Generate OAuth 1.0 Keys

**Note**: For developer accounts created after [July 17, 2017 Quickbooks API requires
OAuth 2.0](qb_oauth_2), this integration has not yet been updated to account for this.

Create an app here: https://developer.intuit.com/v2/ui#/app/dashboard and generate your oauth keys.

### Environment Variables

Copy "sample.env" to ".env" and fill out the following variables:

`QB_CONSUMER_KEY` - OAuth consumer key

`QB_CONSUMER_KEY` - OAuth token

# Starting Application

`bundle exec unicorn` -- Starts application on port 8080

[qb_oauth_2]: https://developer.intuit.com/hub/blog/2017/07/17/oauth-2-0openid-connect-now-available-new-developers

## History

Forked from https://github.com/flowlink/quickbooks_integration, which itself was a fork of https://github.com/wombat/quickbooks_integration
