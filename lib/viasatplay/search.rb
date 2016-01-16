require 'rexml/document'
require 'uri'

include REXML



module Viasatplay
  def Viasatplay.openPage url
    begin
      page = open(url)
      JSON.parse(page.read)
    rescue OpenURI::HTTPError => e
      puts e.message
      exit
    end
  end

  def Viasatplay.parsePage contents, programs
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

  def Viasatplay.search_episodes options, url, search_string
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

  def Viasatplay.search_series options, search_string
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


    puts "Downloaded #{programs.length} should have been #{total_items}." if options[:verbose]
    puts "From #{pages} should have been #{total_pages}." if options[:verbose]

    programs
  end
end
