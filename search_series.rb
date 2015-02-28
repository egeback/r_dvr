#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'optparse'
require 'shellwords'
require 'io/console'
require 'blurrily'
require 'blurrily/map'
require_relative 'lib/ffmpeg'
require_relative 'lib/svt-play'
require_relative 'lib/commandline-util'
require_relative 'lib/util'

options, optparse = parse_args

begin
  mandatory = [:folder]
  missing = mandatory.select{ |param| options[param].nil? }
  if not missing.empty?
    puts "Missing options: #{missing.join(', ')}"
    puts optparse
    exit
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit
end

if(ARGV.length<1)
  puts @opts
  exit
end

begin
  downloaded_count, excluded, total_count = Svt_play::search_series options, ARGV[0]
  puts "Downloaded #{downloaded_count}/#{total_count} (#{excluded} excluded)"
  exit
rescue SignalException => e
  puts "Ctrl-c pressed. Exiting"
  exit
rescue SystemExit => e
  exit
rescue Exception => e
  puts e.message
  puts e.backtrace.join("\n")
  exit
end

#Clean up
