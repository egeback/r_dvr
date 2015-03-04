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
require_relative 'lib/r_dvr'
require_relative 'lib/ffmpeg'
require_relative 'lib/svt-play'
require_relative 'lib/tv4play'
require_relative 'lib/commandline-util'
require_relative 'lib/util'

options, optparse = parse_args

begin
  mandatory = [:folder, :service]
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
  puts optparse
  exit
end

begin

  program = R_dvr.search_program options, ARGV[0]

  options[:folder] = "#{options[:folder]}#{program.title}"

  #if !is_folder "#{options[:folder]}"
  #  exit if !(create_folder? options[:folder])
  #end
  puts program.title
  puts program.url

  downloaded_count, excluded, total_count = R_dvr::download_episodes options, program.url, program.title
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
