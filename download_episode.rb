#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'optparse'
require 'shellwords'
require 'io/console'
require_relative 'lib/r_dvr'
require_relative 'lib/ffmpeg'
require_relative 'lib/svt-play'
require_relative 'lib/commandline-util'
require_relative 'lib/util'

options, optparse = parse_args

if(ARGV.length<1)
  puts @opts
  exit
end

if options[:folder]!=nil and !is_folder options[:folder]
  puts "Specified destination folder does not exist"
  exit
end


begin
  Svt_play::download_episode options, ARGV[0]
  exit
rescue SystemExit => e
  exit
rescue Exception
  puts e.message
  print detail.backtrace.join("\n")
end
