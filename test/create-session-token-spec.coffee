_ = require 'lodash'
mongojs = require 'mongojs'
redis = require 'fakeredis'
moment = require 'moment'
Cache = require 'meshblu-core-cache'
Datastore = require 'meshblu-core-datastore'
redis  = require 'fakeredis'
CreateSessionToken = require '../'
JobManager = require 'meshblu-core-job-manager'
uuid = require 'uuid'

describe 'CreateSessionToken', ->
  beforeEach (done) ->
    @redisKey = uuid.v1()
    @pepper = 'im-a-pepper-too'
    @pubSubKey = uuid.v1()
    @cache = new Cache client: redis.createClient(@redisKey)
    @uuidAliasResolver = resolve: (uuid, callback) => callback(null, uuid)
    @jobManager = new JobManager
      client: _.bindAll redis.createClient @pubSubKey
      timeoutSeconds: 1
    @datastore = new Datastore
      database: mongojs('meshblu-core-task-update-device')
      moment: moment
      collection: 'devices'

    @datastore.remove done

  beforeEach ->
    @sut = new CreateSessionToken {@datastore, @uuidAliasResolver, @jobManager, @pepper, @cache}

  describe '->do', ->
    beforeEach (done) ->
      @datastore.insert {uuid: 'thank-you-for-considering'}, done

    describe 'when the device exists in the datastore', ->
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
