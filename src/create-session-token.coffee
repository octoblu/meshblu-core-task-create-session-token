_    = require 'lodash'
http = require 'http'
TokenManager = require 'meshblu-core-manager-token'

class CreateSessionToken
  constructor: ({@uuidAliasResolver,@cache,@datastore,@pepper}) ->
    @tokenManager = new TokenManager {@datastore,@cache,@pepper,@uuidAliasResolver}

  _doCallback: (request, code, data, callback) =>
    response =
      metadata:
        responseId: request.metadata.responseId
        code: code
        status: http.STATUS_CODES[code]
      data: data
    callback null, response

  do: (request, callback) =>
    {uuid, messageType, options} = request.metadata
    data = JSON.parse request.rawData

    @tokenManager.generateAndStoreToken {uuid, data}, (error, token) =>
      return callback error if error?
      data.token = token
      return @_doCallback request, 201, data, callback

module.exports = CreateSessionToken
