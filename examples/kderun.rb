#!/usr/bin/ruby
$:.unshift('lib')
$toolkit = :kde
load "examples/#{ARGV.shift}/main.rb"
