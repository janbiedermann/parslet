#!/usr/bin/env ruby

# Example contributed by Hal Brodigan (postmodern). Thanks!

require 'parslet'

class EmailParser < Parslet::Parser
  rule(:space) { match('\s').repeat(1) }
  rule(:space?) { space.maybe }
  rule(:dash?) { match['_-'].maybe }

  rule(:at) {
    str('@') |
    (dash? >> (str('at') | str('AT')) >> dash?)
  }
  rule(:dot) {
    str('.') |
    (dash? >> (str('dot') | str('DOT')) >> dash?)
  }

  rule(:word) { match('[a-z0-9]').repeat(1).as(:word) >> space? }
  rule(:separator) { space? >> dot.as(:dot) >> space? | space }
  rule(:words) { word >> (separator >> word).repeat }

  rule(:email) {
    (words >> space? >> at.as(:at) >> space? >> words).as(:email)
  }

  root(:email)
end

class EmailSanitizer < Parslet::Transform
  rule(:dot => simple(:dot), :word => simple(:word)) { ".#{word}" }
  rule(:at => simple(:at)) { '@' }
  rule(:word => simple(:word)) { word }
  rule(:email => sequence(:email)) { email.join }
end

parser = EmailParser.new
sanitizer = EmailSanitizer.new

unless ARGV[0]
  STDERR.puts "usage: #{$0} \"EMAIL_ADDR\""
  exit -1
end

begin
  puts sanitizer.apply(parser.parse(ARGV[0]))
rescue Parslet::ParseFailed => error
  puts error
  puts parser.root.error_tree
end