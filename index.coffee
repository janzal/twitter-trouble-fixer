#!/usr/bin/env coffee

readline = require "readline"
twit = require "twit"
async = require "async"

config = require "./config.json"

# String extension
String::startsWith ?= (s) -> @slice(0, s.length) == s
String::endsWith   ?= (s) -> s == '' or @slice(-s.length) == s


# Readline initialization
rl = readline.createInterface
  input: process.stdin,
  output: process.stdout


# Setting up twitter
T = new twit config

doWork = true

async.whilst () ->
    doWork
  ,
  (callback) ->
    T.get "statuses/user_timeline", count: 200, (err, tweets) ->
      return console.log "There is an error, bro:", err if err?

      # insults = tweets.filter (tweet) ->
      #   if tweet.text.startsWith "Pica"
      #     true

      insults = tweets

      insults = for tweet in insults
          id: tweet.id_str
          text: tweet.text

      questions = for insult in insults
          "#{insult.text}"

      rl.question """Do you really want to delete these tweets?

                #{questions.join ', '}

                [y(es)|N(o)|s(elect)|e(xit)] """, (answer) ->
        switch answer
          when "Y", "y", "yes"
            async.each insults, (tweet, callback) ->
              console.log "Deleting #{tweet.text}"
              T.post "statuses/destroy/:id", id: tweet.id, (err) ->
                console.log err if err?

                console.log "Tweet has been deleted..."
                callback()
              , (err) ->
                  callback err

          when "S", "s", "select"
            async.eachSeries insults, (tweet, callback) ->
              rl.question "Do you want to keep tweets \"#{tweet.text}\"? [Y|n] ", (answer) ->
                return callback() if answer isnt ("n" or "N")

                console.log "Deleting..."

                T.post "statuses/destroy/:id", id: tweet.id, (err) ->
                  console.log err if err?

                  console.log "Tweet has been deleted..."
                  callback()

          when "E", "e", "exit"
            doWork = false

          else console.log "Skipping this set!"

        callback()
  ,
  (err) ->
    console.log err if err?

    console.log "Job is done!"
    rl.close()
