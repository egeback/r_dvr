#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'optparse'

require_relative 'download_episode'

options = {}
@opts = nil

optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: parse_series.rb [options] series_name"

  # Define the options, and what they do
  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more information' ) do
    options[:verbose] = true
  end

  options[:barnkanalen] = false
  opts.on( '-b', '--barnkanalen', 'Download from Barnkanalen' ) do
    options[:barnkanalen] = true
  end

  options[:url] = nil
  opts.on( '-u', '--url URL', 'Download from url' ) do |url|
    options[:url] = url
  end

  options[:folder] = nil
  opts.on( '-d', '--destination FOLDER', 'Destination folder' ) do |folder|
    options[:folder] = folder
  end

  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
  exit
  end
  @opts = opts
end

# Parse the command-line. Remember there are two forms
# of the parse method. The 'parse' method simply parses
# ARGV, while the 'parse!' method parses ARGV and removes
# any options found there, as well as any parameters for
# the options. What's left is the list of files to resize.
optparse.parse!

#Add tailing /
options[:folder]+="/" if options[:folder]!=nil && !(options[:folder][options[:folder].length-1] == '/')

baseurl = "http://www.svt.se/"

url = nil
if options[:url]!=nil
  url = options[:url]
else
  if ARGV.length<1
    puts @opts
    exit
  end

  url = baseurl
  url = "http://www.svt.se/barnkanalen/barnplay/" if options[:barnkanalen]
  puts "Setting url to barnkanalen" if options[:barnkanalen] && options[:verbose]
  url = "#{url}#{ARGV[0]}"
end


puts "Searching for #{ARGV[0]} on url: #{url}" if options[:verbose]

page = nil
begin
  page = Nokogiri::HTML(open("#{url}"))
rescue OpenURI::HTTPError => e
  puts e.message
  puts "Can't find #{ ARGV[0] }"
  exit
end

objects = page.css("div[class='bpEpisodeListNoScript']")
title = objects.css("h1[class='bpEpisodeListNoScript-Title']").text
episodes = objects.css("div[class='bpEpisodeListNoScript-ListItem']")
count = 0
episodes.css("a").each {|episode|
  count+=1
  url = episode["href"]
  title = nil
  img = nil
  if episode.css("img").length>0
    title = episode.css("img")[0]["alt"]
    img = episode.css("img")[0]["src"]
  end
  #puts "#{title}: {url: '#{url}', img: '#{img}'}"
  puts "Downloading #{title} from url #{baseurl}#{url}" if options[:verbose]

  download_episode options, "#{baseurl}#{url}"
  #cmd="ruby download_episode0.rb #{baseurl}#{url}"
  #cmd+=" -v" if options[:verbose]
  #cmd+=" -d '#{options[:folder]}'" if options[:folder]!=nil
  #system(cmd)
}
puts "Downloaded"
