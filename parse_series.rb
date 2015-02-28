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

url = nil
if options[:url]!=nil
  url = options[:url]
else
  if ARGV.length<1
    optparse
    exit
  end

  url = $baseurl
  url = "#{url}#{ARGV[0]}"
end

#catch :ctrl_c do
  begin
    downloaded_count, excluded, total_count = download_episodes options, url, ARGV[0]
    puts "Downloaded #{downloaded_count}/#{total_count} (#{excluded} excluded)"
    exit
  rescue SystemExit => e
    exit
  rescue Exception
    puts e.message
    print detail.backtrace.join("\n")
    exit
  end
#end
#Clean up
