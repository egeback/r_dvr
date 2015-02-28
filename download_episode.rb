#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'optparse'
require 'shellwords'
require 'io/console'
require_relative 'lib/ffmpeg'
require_relative 'lib/svt-play'

options, optparse = parse_args

if(ARGV.length<1)
  puts @opts
  exit
end

if options[:folder]!=nil and !is_folder options[:folder]
  puts "Specified destination folder does not exist"
  exit
end

catch :ctrl_c do
  begin
    download_episode options, ARGV[0]
    exit
  rescue SystemExit => e
    exit
  rescue Exception
    puts e.message
    print detail.backtrace.join("\n")
  end
end
#Clean up
