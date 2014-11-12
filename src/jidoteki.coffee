# Description:
#   Build virtual appliances using Jidoteki
#   https://jidoteki.com
#   Copyright (c) 2014 Alex Williams, Unscramble <license@unscramble.jp>

###
 * Jidoteki - https://jidoteki.com
 * Build virtual appliances using Jidoteki
 * Copyright (c) 2014 Alex Williams, Unscramble <license@unscramble.jp>
###

crypto    = require 'crypto'
armrest   = require 'armrest'

settings  =
  host:       'api.jidoteki.com'
  endpoint:   process.env.JIDOTEKI_ENDPOINT   || 'https://api.jidoteki.com'
  userid:     process.env.JIDOTEKI_USERID     || 'change me'
  apikey:     process.env.JIDOTEKI_APIKEY     || 'change me'
  logLevel:   process.env.JIDOTEKI_LOGLEVEL   || 'info'
  useragent:  'nodeclient-jidoteki/0.2.4'
  token:      null
  tries:      0

api = armrest.client settings.endpoint

exports.settings = settings

exports.makeHMAC = (string) ->
  return crypto.createHmac('sha256', settings.apikey)
    .update(string)
    .digest 'hex'

# Set the request headers depending on the type of request we're trying to make
exports.getHeaders = (apiVersion, requestType, signature, callback) ->
  switch requestType
    when 'token'
      callback null, {
        'Accept-Version':   apiVersion
        'Host':             settings.host
        'User-Agent':       settings.useragent
        'X-Auth-Uid':       settings.userid
        'X-Auth-Signature': signature
        'Content-Type':     'application/json'
      }
    when 'get'
      callback null, {
        'Accept-Version':   apiVersion
        'Host':             settings.host
        'User-Agent':       settings.useragent
        'X-Auth-Token':     settings.token
        'X-Auth-Signature': signature
      }
    when 'post'
      callback null, {
        'Accept-Version':   apiVersion
        'Host':             settings.host
        'User-Agent':       settings.useragent
        'X-Auth-Token':     settings.token
        'X-Auth-Signature': signature
        'Content-Type':     'application/json'
      }
    else
      callback new Error "Invalid Request Type. Must be 'token', 'get' or 'post'"

# Obtains a session token from the APIv1
exports.getToken = (callback) ->
  signature = this.makeHMAC "POSThttps://#{settings.host}/auth/user"
  this.getHeaders 1, 'token', signature, (error, result) ->
    api.post
      url: '/auth/user'
      headers: result
      complete: (err, data, res) ->
        if err
          settings.token = null
          settings.tries = 1

          return callback err
        else
          settings.token = res.content
          settings.tries = 0

          return callback null, res

# Make an APIv1 or APIv2 GET or POST request
exports.apiCall = (apiVersion, method, resource, string, callback) ->
  switch method
    when 'GET'
      signature = this.makeHMAC "GEThttps://#{settings.host}#{resource}"
      this.getHeaders apiVersion, 'get', signature, (error, result) ->
        api.get
          url: resource
          headers: result
          complete: (err, data, res) ->
            if err then return callback err
            return callback null, res

    when 'POST'
      signature = this.makeHMAC "POSThttps://#{settings.host}#{resource}#{JSON.stringify string}"
      this.getHeaders apiVersion, 'post', signature, (error, result) ->
        api.post
          url: resource
          headers: result
          params: string
          complete: (err, data, res) ->
            if err then return callback err
            return callback null, res

    else
      return callback new Error 'Invalid request method'

exports.makeRequest = (apiVersion, requestMethod, resource, string, callback) ->
  return callback new Error 'Unable to authenticate' if settings.tries >= 1

  if settings.token?
    this.apiCall apiVersion, requestMethod.toUpperCase(), resource, string, (err, res) =>
      if err
        if err.status is 'error' and err.message is 'Unable to authenticate'
          this.getToken (err, res) =>
            this.makeRequest apiVersion, requestMethod, resource, string, callback
        else
          return callback err
      else
        return callback null, res

  else
    this.getToken (err, res) =>
      this.makeRequest apiVersion, requestMethod, resource, string, callback
