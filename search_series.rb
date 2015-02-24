#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'optparse'
require 'amatch'
require 'bio'
require 'blurrily'
require 'blurrily/map'
require 'io/console'
require 'shellwords'

class Series
  attr_accessor :title, :url
end

def read_input
  print 'Enter choice (q for quit): '
  STDOUT.flush
  STDIN.readline #getch
end

def is_folder f
  file = Shellwords.escape(f)
  #Fix faulty escape
  file = file[1,file.length+1] if file[0,2] == '\~'
  File.directory?(f)
end

class String
  def numeric?
    return true if self =~ /^\d+$/
    true if Float(self) rescue false
  end
end

options = {}
@opts = nil

optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: search_series.rb [options] series_name"

  # Define the options, and what they do
  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more information' ) do
    options[:verbose] = true
  end

  options[:barnkanalen] = false
  opts.on( '-b', '--barnkanalen', 'Download from Barnkanalen' ) do
    options[:barnkanalen] = true
  end

  options[:destination] = nil
  opts.on( '-d', '--destination FOLDER', 'Destination folder' ) do |folder|
    options[:destination] = folder
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
begin
  optparse.parse!
  mandatory = [:destination]
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

#Add tailing /
options[:destination]+="/" if options[:destination]!=nil && !(options[:destination][options[:destination].length-1] == '/')

begin
  page = Nokogiri::HTML(open("http://www.svt.se/program/"))
rescue OpenURI::HTTPError => e
  puts e.message
  exit
end

objects = page.css("li[class~='svtLegendMarkerLayoutItem']")
series = Array.new
objects.each { |object|
  s = Series.new
  s.title = object.css('a').text
  s.url = object.css('a').first['href']
  series.push s
}

puts "Number of series #{series.size}"

search = ARGV[0]
puts "Search text: #{search}"
serie = nil

map = Blurrily::Map.new
series.each_with_index { |s, index|
  if(search===s.title)
    serie = s
    break
  end
  map.put(s.title, index)
}

if serie!=nil
  puts "Found series #{serie.title}"
elsif
  p "Found:"

  search_series = Array.new
  search_results = map.find(search)

  search_results.each_with_index { |item , index|
    puts "#{index+1}. #{series[item[0]].title} (rating: #{item[1]})"
    search_series.push item
  }

  c = nil
  while
    c = read_input
    exit if c[0] === 'q'
    break if c.numeric? and c.to_i > 0 and c.to_i <= search_results.size
  end
  serie = series[search_results[c.to_i-1][0]]
end

destination = "#{options[:destination]}#{serie.title}"

cmd ="ruby parse_series.rb -u '#{serie.url}'"
cmd+=" -v" if options[:verbose]
cmd+=" -d '#{destination}'" if options[:destination]!=nil
#puts cmd

if !is_folder "#{destination}"
  puts "The folder '#{destination}' does not exist."
  print "Do you want to create it (Y/n)? "
  STDOUT.flush
  c = STDIN.getch
  puts c
  if !(c === "y" or c === "Y")
    exit
  end
  Dir.mkdir(destination)
end

system(cmd)
