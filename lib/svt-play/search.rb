require 'rexml/document'
require 'uri'

include REXML

module Svt_play
  def Svt_play.search_episodes options, url, search_string
    return search_episodes_barnkanalen options, url, search_string if url.include? 'barnkanalen'
    search_episodes_svt_play options, url, search_string
  end

  def search_episodes_barnkanalen options, url, search_string
    puts "Searching for #{search_string} on url: #{url}" if options[:verbose]

    page = nil
    begin
      page = Nokogiri::HTML(open("#{url}"))
    rescue OpenURI::HTTPError => e
      puts e.message
      puts "Can't find #{ url }"
      exit
    end

    objects = page.css("div[class='bpEpisodeListNoScript']")
    series = objects.css("h1[class='bpEpisodeListNoScript-Title']").text
    episodes = objects.css("div[class='bpEpisodeListNoScript-ListItem']")

    episodes_list = Array.new

    uri = URI.parse(url)
    baseurl = "http://#{uri.host}"

    episodes.css("a").each {|episode|
      url = episode["href"]
      title = nil
      img = nil
      if episode.css("img").length>0
        title = episode.css("img")[0]["alt"]
        img = episode.css("img")[0]["src"]
      end

      episodes_list.push Episode.new title, "#{baseurl}#{url}", img
    }

    return series, episodes_list
  end

  def Svt_play.search_episodes_svt_play options, url, search_string
    puts "Searching for #{search_string} on url: #{url}" if options[:verbose]

    begin
      page = open(url).read
    rescue OpenURI::HTTPError => e
      puts e.message
      exit
    end

    url = nil

    page.scan(/<link rel=\"alternate\" type=\"application\/rss\+xml\" [^>]* href=\"(.*)\"/) do |match|
       url = match.first
    end

    if url === nil
      raise 'Couldn\'t retrieve episode list'
    end

    begin
      page = Document.new(open(url))
    rescue OpenURI::HTTPError => e
      puts e.message
      exit
    end

    episodes = Array.new

    series = page.elements['rss/channel/title'].text

    page.elements.each('rss/channel/item') do |e|
      episode = Episode.new
      episode.url = e.elements["link"].text
      episode.title = e.elements["title"].text
      episode.img = e.elements["enclosure"].attributes["url"]
      episode.description = e.elements["description"].text
      episode.dcDate = e.elements["dc:date"].text
      episode.pubDate = e.elements["pubDate"].text
      episodes.push episode
    end

    return series, episodes

  end

  def Svt_play.search_series options, search_string
    begin
      page = Nokogiri::HTML(open("http://www.svtplay.se/program/"))
    rescue OpenURI::HTTPError => e
      puts e.message
      exit
    end

    objects = page.css("li[class~='play_alphabetic-list__video-list-item']")

    series = Array.new
    objects.each { |object|
      s = Series.new
      s.title = object.css('a').text
      s.url = "http://www.svtplay.se/#{object.css('a').first['href']}"
      series.push s
    }

    puts "Number of programs #{series.size} found." if options[:verbose]

    #search_string
    puts "Search text: #{search_string}" if options[:verbose]
    serie = nil

    map = Blurrily::Map.new
    series.each_with_index { |s, index|
      if(search_string===s.title)
        serie = s
        break
      end
      map.put(s.title, index)
    }

    if serie!=nil
      #puts "Found series #{serie.title}"
    elsif
      p "Found:"

      search_series = Array.new
      search_results = map.find(search_string)

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

    serie
  end
end
