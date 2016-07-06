_            = require 'lodash'
http         = require 'http'
TokenManager = require 'meshblu-core-manager-token'

class CreateSessionToken
  constructor: ({uuidAliasResolver, datastore, pepper}) ->
    @tokenManager = new TokenManager {uuidAliasResolver, datastore, pepper}

  _doCallback: (request, code, data, callback) =>
    response =
      metadata:
        responseId: request.metadata.responseId
        code: code
        status: http.STATUS_CODES[code]
      data: data
    callback null, response

  do: (request, callback) =>
    {toUuid, messageType, options} = request.metadata
    metadata = JSON.parse request.rawData

    @tokenManager.generateAndStoreToken {uuid: toUuid, metadata}, (error, token) =>
      return callback error if error?
      response = metadata
      response ?= {}
      response.uuid = toUuid
      response.token = token
      @_doCallback request, 201, metadata, callback

module.exports = CreateSessionToken
