require 'rexml/document'
require 'uri'

include REXML

module Svt_play
  BASE_URL = 'http://www.svtplay.se'
  START_URL = BASE_URL + '/xml/start.xml'
  ALL_PROGRAMS_URL = BASE_URL + '/xml/programmes.xml'
  CATEGORIES_URL = BASE_URL + '/xml/categories.xml'
  VIDEO_URL_TEMPLATE = BASE_URL + '/video/'
  ATV_URL_TEMPATE = BASE_URL + '/xml/player/'

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
    #uri = URI.parse(url)
    #baseurl = "http://#{uri.host}"

    begin
      page = Nokogiri::HTML(open(url)) #open(url).read
    rescue OpenURI::HTTPError => e
      puts e.message
      exit
    end

    series = ""
    begin
      series = page.xpath(".//tabwithtitle/title/text()")[0].to_s
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
    end

    episodes = Array.new

    page.xpath("//navigationitem[@id='episodes']//items//twolineenhancedmenuitem").each { |item|
      title = item.xpath(".//title/text()")[0].to_s
      thumb = item.xpath(".//image/text()")[0].to_s
      label = item.xpath(".//label/text()")[0].to_s

      xml_url = item.xpath("./@onselect")[0]

      if xml_url.to_s.include?(',')
        id = xml_url.to_s.split(",")[-1].gsub("'", "").gsub(")", "").gsub(";", "").strip
      else
        id = xml_url.to_s.split("/")[-1].gsub(".xml", "").strip
      end

      url = Svt_play.getMediaUrl (ATV_URL_TEMPATE + id + '.xml')

      season = nil
      index = nil

      label.scan(/Säsong (.*) -/) do |match|
        season = match.first
        season = '0' + season if season.size < 2
      end

      label.scan(/- Avsnitt (.*)/) do |match|
        index = match.first
        index = '0' + index if index.size < 2
      end

      episode = Episode.new
      episode.url = url

      episode.img = thumb

      if season!=nil && episode!=nil
        episode.title = "#{series} S#{season}E#{index} #{title}"
        episode.title = episode.title.gsub(" ", ".")
      else
        episode.title = series + lable
      end
      #puts episode.url
      episodes.push episode
    }

    return series, episodes

  end

=begin
    #episodes_url = page.xpath("//navigationitem[@id='episodes']/url/text()")[0]
    #puts episodes_url
    #episodes_xml_data = XML.ObjectFromURL(episodes_url)



    url = nil


    series = page.css("h1[class=play_title-page-info__header-title]").text

    #part = page.css("div[id=play_js-tabpanel-more-episodes]")

    objects = page.css("li[class='play_vertical-list__item play_js-vertical-list-item']") #("a[class=play_vertical-list__header-link]")
    puts "Found #{objects.size} episode(s)" #if options[:verbose]

    episodes = Array.new
    objects.each { |object|
      info = object.css("a[class=play_vertical-list__header-link]")

      episode = Episode.new
      episode.url = baseurl + info.first['href']
      episode.title = info.text
      episode.img = object.css("img").first['src']

      episode.description = object.css("p[class=play_vertical-list__description-text]").first.text.delete!("\n").strip!
      pubDate = object.css("p[class=play_vertical-list__meta-info]")
      if pubDate.size > 0
        episode.pubDate = pubDate.first.text.strip!
        episode.pubDate = episode.pubDate.gsub('Publicerades ', '')
      end
      #puts episode.title + " #{episode.url} #{episode.pubDate}"
      #episode.pubDate.delete!("\n").strip!
      episodes.push episode
    }

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
=end

  def Svt_play.getMediaUrl url
    begin
      page = Nokogiri::HTML(open(url)) #open(url).read
    rescue OpenURI::HTTPError => e
      puts e.message
      exit
    end
    return page.xpath(".//httplivestreamingvideoasset/mediaurl/text()")[0].to_s

  end

  def Svt_play.search_series options, search_string
    begin
      page = Nokogiri::HTML(open("http://www.svtplay.se/xml/programmes.xml"))
      #page = Nokogiri::HTML(open("http://www.svtplay.se/program/"))
    rescue OpenURI::HTTPError => e
      puts e.message
      exit
    end

    programs = Array.new

    page.xpath("//items/sixteenbynineposter").each { |item|
      s = Program.new
      s.title = item.xpath(".//title/text()")[0].to_s
      item.xpath("./@onselect")[0].to_s.scan(/atv.loadURL\(\'(.*)\'\);/) do |match|
        s.url = match.first
      end

      programs.push s

    }
    programs

=begin
    objects = page.css("li[class~='play_js-filterable-item play_link-list__item']")

    programs = Array.new
    objects.each { |object|
      s = Program.new
      s.title = object.css('a').text
      s.url = "http://www.svtplay.se#{object.css('a').first['href']}"
      programs.push s
    }
    programs
=end
  end
end
