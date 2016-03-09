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
        fixed = false
        label.scan(/^Avsnitt (.*)/) do |match|
          fixed = true
          season = "01"
          index = match.first
          index = '0' + index if index.size < 2
          episode.title = "#{series} S#{season}E#{index} #{title}"
          episode.title = episode.title.gsub(" ", ".")
        end
        episode.title = series + " " +  label if !fixed
      end

      episodes.push episode
    }

    return series, episodes

  end

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
  end
end
