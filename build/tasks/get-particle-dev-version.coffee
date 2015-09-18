request = require 'request'

_grunt = null
isRelease = true

getParticleDevVersion = (cb) ->
  # Get Particle Dev version from options/current sources
  if !!_grunt.option('particleDevVersion')
    cb _grunt.option('particleDevVersion')
  else if !!process.env.TRAVIS_TAG or !!process.env.APPVEYOR_REPO_TAG_NAME
    tag = process.env.TRAVIS_TAG ? process.env.APPVEYOR_REPO_TAG_NAME
    # Drop the "v" from tag name
    cb tag.slice(1)
  else
    isRelease = false
    # Get the version from master
    repo = 'spark/spark-dev'
    url = "https://raw.githubusercontent.com/#{repo}/master/package.json"
    request url, (error, response, body) ->
      if !!error
        _grunt.fail.fatal '(e) Error fetching version'
      version = JSON.parse(body).version

      # Fetch latest commit
      options =
        url: "https://api.github.com/repos/#{repo}/commits?sha=master"
        headers:
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.93 Safari/537.36'

      request options, (error, response, body) ->
        if !!error
          _grunt.fail.fatal '(e) Error fetching commits'

        version = "#{version}-" + JSON.parse(body)[0].sha.substring(0, 7)
        cb version

module.exports = (grunt) ->
  grunt.registerTask 'get-particle-dev-version', 'Figures Particle Dev version', ->
    done = @async()
    _grunt = grunt

    getParticleDevVersion (particleDevVersion) ->
      grunt.log.writeln '(i) Particle Dev version is ' + particleDevVersion
      grunt.config.merge
        particleDevApp:
          particleDevVersion: particleDevVersion
          isRelease: isRelease

      done()
