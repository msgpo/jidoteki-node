# Tests the helpers

assert    = require 'should'
jidoteki  = require '../lib/jidoteki'

describe 'Jidoteki.com API client ', ->
  describe '#Security', ->
    it 'should generate a 64-char HMAC', (done) ->
      result = jidoteki.makeHMAC 'test string to hmac'
      result.should.have.length 64
      result.should.be.a.String
      result.should.equal '5762b52d77fa3b7adb7a3a0618ebcec2598b0f60e96e375f852e895ef1355355'
      done()

  describe '#Headers', ->
    it 'should return the correct TOKEN headers', (done) ->
      jidoteki.getHeaders 1, 'token', 'test signature', (error, result) ->
        result.should.be.a.Object
        result.should.have.properties 'Accept-Version', 'Host', 'User-Agent', 'X-Auth-Uid', 'X-Auth-Signature', 'Content-Type'
        result['Accept-Version'].should.equal 1
        result['X-Auth-Signature'].should.equal 'test signature'
        result['Content-Type'].should.equal 'application/json'
        done()

    it 'should return the correct GET headers', (done) ->
      jidoteki.getHeaders 1, 'get', 'test signature', (error, result) ->
        result.should.be.a.Object
        result.should.have.properties 'Accept-Version', 'Host', 'User-Agent', 'X-Auth-Token', 'X-Auth-Signature'
        result['Accept-Version'].should.equal 1
        result['X-Auth-Signature'].should.equal 'test signature'
        (result['X-Auth-Token'] is null).should.be.true
        done()

    it 'should return the correct POST headers', (done) ->
      jidoteki.getHeaders 2, 'post', 'test signature', (error, result) ->
        result.should.be.a.Object
        result.should.have.properties 'Accept-Version', 'Host', 'User-Agent', 'X-Auth-Token', 'X-Auth-Signature', 'Content-Type'
        result['Accept-Version'].should.equal 2
        result['X-Auth-Signature'].should.equal 'test signature'
        (result['X-Auth-Token'] is null).should.be.true
        result['Content-Type'].should.equal 'application/json'
        done()

    it 'should return an error from invalid headers requestType', (done) ->
      jidoteki.getHeaders 1, 'invalid', 'test signature', (error, result) ->
        error.message.should.equal "Invalid Request Type. Must be 'token', 'get' or 'post'"
        error.should.Error
        error.should.be.a.Error
        done()

  describe '#API Calls', ->
    it 'should make an API call using an invalid request method', (done) ->
      jidoteki.apiCall 1, 'INVALIDREQUESTMETHOD', '/404', null, (error, result) ->
        error.should.Error
        error.should.be.a.Error
        error.message.should.equal 'Invalid request method'
        done()

    it 'should make an API call to an invalid download URL', (done) ->
      this.timeout 10000
      jidoteki.apiCall 2, 'GET', '/download/00000', null, (error, result) ->
        error.status.should.equal 'error'
        error.message.should.equal 'Invalid download URL'
        error.content.should.equal 'Please specify an existing download URL'
        error.should.be.a.Object
        error.should.have.properties 'status', 'message', 'content'
        done()

    it 'should make an API call to a 404', (done) ->
      jidoteki.apiCall 1, 'GET', '/404', null, (error, result) ->
        error.should.Error
        error.should.be.a.Error
        done()

    it 'should make an API call to /software without auth credentials', (done) ->
      this.timeout 10000
      params =
        appliance_id: 'abcd1234'
        version:      '1.1'
        script:       '#!/bin/bash'
        files:        [
          file_id:    '.diz'
          file_name:  'flightsim.zip'
        ]
      jidoteki.apiCall 2, 'POST', '/software', params, (error, result) ->
        error.status.should.equal 'error'
        error.message.should.equal 'Invalid Request headers'
        error.content.should.equal 'Please specify a valid token and signature'
        error.should.be.a.Object
        error.should.have.properties 'status', 'message', 'content'
        done()

    it 'should fail to authenticate to the API', (done) ->
      jidoteki.settings.userid = '0000000'
      jidoteki.settings.apikey = '5762b52d77fa3b7adb7a3a0618ebcec2598b0f60e96e375f852e895ef1355355'
      jidoteki.getToken (error, result) ->
        error.status.should.equal 'error'
        error.message.should.equal 'Unable to authenticate'
        error.content.should.equal 'The HMAC signatures don\'t match. Please verify your user id and signature.'
        error.should.be.a.Object
        error.should.have.properties 'status', 'message', 'content'
        done()

    it 'should fail to authenticate to the API with no session token', (done) ->
      jidoteki.settings.userid = '0000000'
      jidoteki.settings.apikey = '5762b52d77fa3b7adb7a3a0618ebcec2598b0f60e96e375f852e895ef1355355'
      jidoteki.settings.token  = null
      jidoteki.settings.tries  = 0
      jidoteki.makeRequest 1, 'get', '/settings', null, (error, result) ->
        error.message.should.equal 'Unable to authenticate'
        error.should.Error
        error.should.be.a.Error
        error.should.have.properties 'message'
        done()

    it 'should fail to authenticate to the API with an invalid session token', (done) ->
      jidoteki.settings.userid = '0000000'
      jidoteki.settings.apikey = '5762b52d77fa3b7adb7a3a0618ebcec2598b0f60e96e375f852e895ef1355355'
      jidoteki.settings.token  = '5762b52d77fa3b7adb7a3a0618ebcec2598b0f60e96e375f852e895ef1355355'
      jidoteki.settings.tries  = 0
      jidoteki.makeRequest 1, 'get', '/settings', null, (error, result) ->
        error.message.should.equal 'Unable to authenticate'
        error.should.Error
        error.should.be.a.Error
        error.should.have.properties 'message'
        done()

    it 'should fail to authenticate to the API after too many tries', (done) ->
      jidoteki.settings.userid = '0000000'
      jidoteki.settings.apikey = '5762b52d77fa3b7adb7a3a0618ebcec2598b0f60e96e375f852e895ef1355355'
      jidoteki.settings.tries  = 1
      jidoteki.makeRequest 1, 'get', '/settings', null, (error, result) ->
        error.message.should.equal 'Unable to authenticate'
        error.should.Error
        error.should.be.a.Error
        error.should.have.properties 'message'
        done()

    it 'should fail to make an API call', (done) ->
      jidoteki.settings.userid = '0000000'
      jidoteki.settings.apikey = '5762b52d77fa3b7adb7a3a0618ebcec2598b0f60e96e375f852e895ef1355355'
      jidoteki.settings.token  = '5762b52d77fa3b7adb7a3a0618ebcec2598b0f60e96e375f852e895ef1355355'
      jidoteki.settings.tries  = 0
      jidoteki.makeRequest 1, 'get', '/download/000000', null, (error, result) ->
        error.should.Error
        error.should.be.a.Error
        done()

    it 'should fail to make an API call', (done) ->
      jidoteki.settings.userid = '0000000'
      jidoteki.settings.apikey = '5762b52d77fa3b7adb7a3a0618ebcec2598b0f60e96e375f852e895ef1355355'
      jidoteki.settings.token  = '5762b52d77fa3b7adb7a3a0618ebcec2598b0f60e96e375f852e895ef1355355'
      jidoteki.settings.tries  = 0
      this.timeout 10000
      jidoteki.makeRequest 2, 'get', '/download/00000', null, (error, result) ->
        error.status.should.equal 'error'
        error.message.should.equal 'Invalid download URL'
        error.content.should.equal 'Please specify an existing download URL'
        error.should.be.a.Object
        error.should.have.properties 'status', 'message', 'content'
        done()
