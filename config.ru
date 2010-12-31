require 'rubygems'
require 'bundler'
Bundler.require
require './pants.rb'

run Sinatra::Application

