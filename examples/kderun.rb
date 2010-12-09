#!/usr/bin/ruby
$:.unshift('lib')
$toolkit = :qt
load "examples/#{ARGV[0]}/main.rb"
