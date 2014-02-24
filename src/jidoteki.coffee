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

jido = exports ? this

jido.settings   =
  endpoint:   'https://api.jidoteki.com'
  userid:     process.env.JIDOTEKI_USERID || 'change me'
  apikey:     process.env.JIDOTEKI_APIKEY || 'change me'
  useragent:  'nodeclient-jidoteki/0.1.4'
  token:      null

jido.api        = armrest.client jido.settings.endpoint

exports.makeHMAC = (string, callback) =>
  hmac = crypto.createHmac('sha256', jido.settings.apikey).update(string).digest 'hex'
  callback(hmac)

exports.getToken = (callback) =>
  resource = '/auth/user'
  @makeHMAC "POST#{jido.settings.endpoint}#{resource}", (signature) ->
    jido.api.post
      url: resource
      headers:
        'X-Auth-Uid': jido.settings.userid
        'X-Auth-Signature': signature
        'User-Agent': jido.settings.useragent
        'Accept-Version': 1
        'Content-Type': 'application/json'
      complete: (err, res, data) ->
        if data.status is 'success'
          jido.settings.token = data.content
          setTimeout ->
            jido.settings.token = null
          , 27000000 # Expire the token after 7.5 hours
        callback data

exports.getData = (resource, callback) =>
  @makeHMAC "GET#{jido.settings.endpoint}#{resource}", (signature) ->
    jido.api.get
      url: resource
      headers:
        'X-Auth-Token': jido.settings.token
        'X-Auth-Signature': signature
        'User-Agent': jido.settings.useragent
        'Accept-Version': 1
      complete: (err, res, data) ->
        if err
          jido.settings.token = null if data.status is 'error' and data.message is 'Unable to authenticate'
        callback data

exports.postData = (resource, string, callback) =>
  @makeHMAC "POST#{jido.settings.endpoint}#{resource}#{JSON.stringify(string)}", (signature) ->
    jido.api.post
      url: resource
      params: string
      headers:
        'X-Auth-Token': jido.settings.token
        'X-Auth-Signature': signature
        'User-Agent': jido.settings.useragent
        'Accept-Version': 1
        'Content-Type': 'application/json'
      complete: (err, res, data) ->
        if err
          jido.settings.token = null if data.status is 'error' and data.message is 'Unable to authenticate'
        callback data

exports.makeRequest = (type, resource, string..., callback) =>
  newType = type.toUpperCase()
  if jido.settings.token isnt null
    switch newType
      when "GET"
        @getData resource, (data) ->
          callback data
      when "POST"
        @postData resource, string[0], (data) ->
          callback data
  else
    @getToken (result) ->
      switch newType
        when "GET"
          jido.getData resource, (data) ->
            callback data
        when "POST"
          jido.postData resource, string[0], (data) ->
            callback data
