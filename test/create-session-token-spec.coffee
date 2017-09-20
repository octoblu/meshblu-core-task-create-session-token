{describe,beforeEach,it,expect} = global
mongojs            = require 'mongojs'
Datastore          = require 'meshblu-core-datastore'
TokenManager       = require 'meshblu-core-manager-token'
CreateSessionToken = require '../'

describe 'CreateSessionToken', ->
  beforeEach (done) ->
    @uuidAliasResolver = resolve: (uuid, callback) => callback(null, uuid)
    @database = mongojs 'meshblu-core-task-update-device', ['tokens']
    @datastore = new Datastore {
      @database,
      collection: 'tokens'
    }

    @database.tokens.remove done

  beforeEach ->
    pepper = 'im-a-pepper'
    @tokenManager = new TokenManager { @datastore, @uuidAliasResolver, pepper }
    @sut = new CreateSessionToken { @datastore, @uuidAliasResolver, pepper }

  describe '->do', ->
    beforeEach (done) ->
      request =
        metadata:
          responseId: 'used-as-biofuel'
          auth:
            uuid: 'thank-you-for-considering'
            token: 'the-environment'
          toUuid: '2-you-you-eye-dee'
        rawData: '{"tag":"foo"}'

      @sut.do request, (error, @response) => done error

    it 'should respond with a 201', ->
      expect(@response.metadata.code).to.equal 201
      expect(@response.data.token).to.exist
      expect(@response.data.tag).to.equal 'foo'

    it 'should create a session token', (done) ->
      @database.tokens.findOne { uuid: '2-you-you-eye-dee' }, (error, record) =>
        return done error if error?
        expect(record).to.exist
        expect(record.uuid).to.equal '2-you-you-eye-dee'
        expect(record.hashedToken).to.exist
        expect(record.metadata.tag).to.equal 'foo'
        expect(record.metadata.createdAt).to.exist
        done()

    it 'should be a valid session token', (done) ->
      @tokenManager.verifyToken {uuid: '2-you-you-eye-dee', token: @response.data.token}, (error, valid) =>
        return done error if error?
        expect(valid).to.be.true
        done()
