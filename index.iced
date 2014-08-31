#!/usr/bin/env iced

readline = require "readline"
twit = require "twit"

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


canWork = true
while canWork
  await T.get "statuses/user_timeline", count: 200, defer err, tweets

  return console.log "There is an error, bro:", err if err?

  insults = tweets

  insults = for tweet in insults
      id: tweet.id_str
      text: tweet.text

  questions = for insult in insults
      "#{insult.text}"

  rl.question """Do you really want to delete these tweets?

            #{questions.join ', '}

            [y(es)|N(o)|s(elect)|e(xit)] """, defer answer

  switch answer
    when "Y", "y", "yes"

      await for insult in insults
        console.log "Deleting #{tweet.text}"

        T.post "statuses/destroy/:id", id: tweet.id, defer err

        console.log err if err?

        console.log "Tweet has been deleted..."

    when "S", "s", "select"
      await for insult in insults
        await rl.question "Do you want to keep tweets \"#{tweet.text}\"? [Y|n] ", defer answer
        return if answer isnt ("n" or "N")

        console.log "Deleting..."

        T.post "statuses/destroy/:id", id: tweet.id, defer err
        console.log err if err?

        console.log "Tweet has been deleted..."

    when "E", "e", "exit"
      canWork = false

    else console.log "Skipping this set!"