#!/usr/bin/env ruby
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'shellwords'
require 'optparse'
require_relative 'lib/ffmpeg'

class Stream
  attr_accessor :program_id, :bandwidth, :resolution, :codecs, :url
end

def parse_playlist playlist
  streams = Array.new
  stream = nil
  playlist.each do |i|
    next if  i.match(/^\#EXTM3U/) #i[1, 6] == "EXTM3U"
    next if i.match(/^\#EXT-X-MEDIA:/)
    #Parse header
    if i.match(/^\#EXT-X-STREAM-INF:/)
      stream = Stream.new
      metadata = i[i.index(",")+1,i.length+1]
      metadata = metadata.split(",")
      stream.bandwidth = metadata[1]["BANDWITH=".length+1, metadata[1].length].to_i
      stream.resolution = metadata[2]["RESOLUTION=".length+1, metadata[2].length]
      next if(metadata.length < 4)
      stream.codecs = metadata[3]["CODECS=".length+1, metadata[3].length]
    else
      stream.url = i.strip! #[0, i.length-1]
      streams.push stream
    end
  end
  streams
end

def download_stream stream, output

  FFMpeg.convert(stream.url, output, {:acodec => 'mp3', :ab => '160k', :vcodec => 'copy'}){ |progress, frame, time, fps, bitrate, total_time|
    #print "\rProgress: #{progress}, frame #{frame}"
    print "\r                                                                                                               "
    print "\rProgress: #{progress}%, frame: #{frame}, time: #{time}, fps: #{fps}, bitrate: #{bitrate}kbit/s. Total time: #{total_time}"
  }
  #puts "Completed"

end

def highest_bandwidth_url streams
  return if streams.size == 0
  stream = streams[0]
  streams[1, streams.size+1].each {|s| stream = s if s.bandwidth > stream.bandwidth}
  return stream
end

def exists file
  File.file?(file)
end

def is_folder f
  file = Shellwords.escape(f)
  #Fix faulty escape
  file = file[1,file.length+1] if file[0,2] == '\~'
  File.directory?(f)
end

options = {}
@opts = nil

optparse = OptionParser.new do|opts|
  # Set a banner, displayed at the top
  # of the help screen.
  opts.banner = "Usage: download_episode.rb [options] url"

  # Define the options, and what they do
  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more information' ) do
    options[:verbose] = true
  end

  options[:force] = false
  opts.on( '-f', '--force', 'Force write' ) do
    options[:force] = true
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

if(ARGV.length<1)
  puts @opts
  exit
end

if options[:folder]!=nil and !is_folder options[:folder]
  puts "Specified destination folder does not exist"
  exit
end

download options, ARGV[0]


def download_episode options, url
  #Add tailing /
  options[:folder]+="/" if options[:folder]!=nil && !(options[:folder][options[:folder].length-1] == '/')

  begin
    page = Nokogiri::HTML(open(url))
  rescue OpenURI::HTTPError => e
    puts e.message
    puts "Can't find #{ ARGV[0] }"
    exit
  end

  object = page.css("object[class=svtplayer-jsremove] param[name=flashvars]")
  title = page.css("h1[class='bpTitle']").text

  if (!options[:force] and exists "#{options[:folder]}#{title}.mkv")
    puts "'#{options[:folder]}#{title}.mkv' exist skipping" if options[:verbose]
    exit
  end

  puts "Objects #{object.size}"

  if object.size > 0
    json = object[0]['value']
    json["json="] = ""
    parsed = JSON.parse(json)
    parsed["video"]["videoReferences"].each{|ref|
      if ref["playerType"] == "ios"
        url = ref["url"]
        puts "Url: #{url}" if options[:verbose]
        playlist = open(url)
        streams = parse_playlist playlist

        streams.sort! { |a,b| a.bandwidth <=> b.bandwidth }
        puts "Found streams:" if options[:verbose]
        streams.each{|stream| puts "#{stream.bandwidth}: #{stream.url}"} if options[:verbose]

        puts "Bandwith: #{(highest_bandwidth_url streams).bandwidth}" if options[:verbose]

        download_stream streams[streams.length-1], "#{options[:folder]}#{title}.mkv"
        puts "next"
        sleep(100)
      end
    }
  end
end
