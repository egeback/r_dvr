require 'open-uri'
require "json"
require_relative '../model/program'
require_relative '../model/episode'

def openPage url
  begin
    page = open(url)
    JSON.parse(page.read)
  rescue OpenURI::HTTPError => e
    puts e.message
    exit
  end
end

def parsePage contents, programs
  contents['_embedded']['formats'].each { |object|
    s = Program.new
    s.title = object['title']
    s.url = object['_links']['videos']['href']
    s.icon = object['image']
    programs.push s
  }

  return contents['_links']['next']['href'] if contents['_links'].has_key?('next')
  return nil
end


def search_episodes options, url, search_string
  puts "Searching for #{search_string} on url: #{url}" if options[:verbose]
  contents = openPage url
  objects = contents['_embedded']['videos']

  puts "Found #{objects.size} episode(s)" #if options[:verbose]

  episodes = Array.new
  series = ""

  objects.each { |object|

    episode = Episode.new

    url = object['_links']['stream']['href']

    episode.url = openPage(url)['streams']['hls']

    episode.title = object['title']
    episode.img = object['_links']['image']

    episode.description = object['summary']
    episode.pubDate = object['publish_at']

    episodes.push episode
    series = object['format_title']
  }
  return series, episodes
end

nextPage = 'https://playapi.mtgx.tv/v3/formats?device=mobile&premium=open&country=se'
contents = openPage nextPage

total_pages = contents['count']['total_pages']
total_items = contents['count']['total_items']

programs = Array.new
nextPage = parsePage contents, programs

pages = 1
begin
  contents = openPage nextPage
  nextPage = parsePage contents, programs
  pages=pages+1
end while nextPage!=nil

puts(total_items === programs.length)
puts(total_pages === pages)
puts(programs.length)
programs.each{ |program|
  #puts "#{program.title}: #{program.url}"
}
puts "#{programs[0].title}: #{programs[0].url}"


options = {:verbose => true}
series, episodes = search_episodes options, programs[0].url, ""
episodes.each{ |episode|
  puts "#{episode.title}: #{episode.url}"
}
