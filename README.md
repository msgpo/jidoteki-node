# Official Node.JS API client and helper library

![Downloads](http://img.shields.io/npm/dm/jidoteki.svg "Jidoteki")

http://docs.jidoteki.com

## Version

Currently at version `0.1.9`

## Installation

`npm install jidoteki`

## Usage

First, make sure you have your `USERID` and `APIKEY` for using the jidoteki.com API.

If you don't have one, you can signup for free here: [Jidoteki.com](https://jidoteki.com)

### Node.JS

```
$ node

jidoteki = require('jidoteki')
jidoteki.settings.userid = 'youruserid'
jidoteki.settings.apikey = 'yourapikey'
console.log(jidoteki.settings)

// make a request!
jidoteki.makeRequest('GET', '/os/list', function(data){ console.log(data); });
```

### CoffeeScript

```
$ coffee

jidoteki = require 'jidoteki'
jidoteki.settings.userid = 'youruserid'
jidoteki.settings.apikey = 'yourapikey'
console.log jidoteki.settings

# make a request!
jidoteki.makeRequest 'GET', '/os/list', (data) -> console.log data
```

# Todo

* Support PUT/DELETE requests with `makeRequest()`
