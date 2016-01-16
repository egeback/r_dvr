module Svt_play
  def Svt_play.download_episode options, episode
    return download_episode_barn options, episode.url, title if episode.url.include? 'barnkanalen'
    download_episode_svt_play options, episode
  end

  def Svt_play.download_episode_svt_play options, episode
    playlist = open(episode.url)
    streams = parse_playlist playlist

    streams.sort! { |a,b| a.bandwidth <=> b.bandwidth }
    puts "Found stream:" if options[:verbose]
    puts puts "#{streams[-1].bandwidth}: '#{streams[-1].url}'" if options[:verbose]

    R_dvr::download_stream streams[-1], "#{options[:folder]}#{episode.title}.mkv", options[:force], episode.title, options[:verbose]
  end
=begin
    #Add tailing /
    options[:folder]+="/" if options[:folder]!=nil && !(options[:folder][options[:folder].length-1] == '/')


    puts url
    begin
      page = open(url).read #Nokogiri::HTML(open(url))
    rescue OpenURI::HTTPError => e
      puts e.message
      puts "Can't find #{ url}"
      exit
    end

    url = nil
    title = nil

    page.scan(/data-title=\"(.*)\"/) do |match|
       title = match.first
       if options[:exclude] and title.include? options[:exclude_string]
         puts "Episode excluded, #{title}." if options[:verbose]
         raise "File excluded"
       end
       break
    end

    if title.index("&ouml;")
      title["&ouml;"] = "ö"
    end
    if title.index("&auml;")
      title["&auml;"] = "ä"
    end
    if title.index("&aring;")
      title["&aring;"] = "å"
    end

    page.scan(/data-json-href=\"(.*)\"/) do |match|
       url = "#{$baseurl}#{match.first}?output=json&format=json"
       break
    end


    if url == nil || title == nil
      raise 'Couldn\'t retrieve episode list'
      puts page
    end

    puts url

    json = open(url).read

    parsed = JSON.parse(json)
    puts parsed

    if parsed["video"]===nil
      puts "nil"
      #doc = Nokogiri::HTML(page)
      #video = doc.css("div").css('video').each{|div|
      #  puts div
      #}
      #[class='play_js-svtvideoplayer*']
      #puts video
      page.scan(/data-popout-href=\"(.*)\"/) do |match|
        url = "http://www.svtplay.se#{match.first}"
        puts "Url: #{url}" if options[:verbose]
        playlist = open(url)

        streams = parse_playlist playlist

        streams.sort! { |a,b| a.bandwidth <=> b.bandwidth }
        puts "Found streams:" if options[:verbose]
        streams.each{|stream| puts "#{stream.bandwidth}: #{stream.url}"} if options[:verbose]

        #puts "Bandwith: #{(highest_bandwidth_url streams).bandwidth}" if options[:verbose]

        R_dvr::download_stream streams[streams.length-1], "#{options[:folder]}#{title}.mkv", options[:force], title, options[:verbose]
      end
      return
    end


    parsed["video"]["videoReferences"].each{|ref|
      if ref["playerType"] == "ios"
        url = ref["url"]
        puts "Url: #{url}" if options[:verbose]
        playlist = open(url)

        streams = parse_playlist playlist

        streams.sort! { |a,b| a.bandwidth <=> b.bandwidth }
        puts "Found streams:" if options[:verbose]
        streams.each{|stream| puts "#{stream.bandwidth}: #{stream.url}"} if options[:verbose]

        #puts "Bandwith: #{(highest_bandwidth_url streams).bandwidth}" if options[:verbose]

        R_dvr::download_stream streams[streams.length-1], "#{options[:folder]}#{title}.mkv", options[:force], title, options[:verbose]
      end
    }
  end

  def Svt_play.download_episode_barn options, url
    #Add tailing /
    options[:folder]+="/" if options[:folder]!=nil && !(options[:folder][options[:folder].length-1] == '/')

    begin
      page = Nokogiri::HTML(open(url))
    rescue OpenURI::HTTPError => e
      puts e.message
      puts "Can't find #{ url}"
      exit
    end

    object = page.css("object[class=svtplayer-jsremove] param[name=flashvars]")
    title = page.css("h1[class='bpTitle']").text

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

          R_dvr::download_stream streams[streams.length-1], "#{options[:folder]}#{title}.mkv", options[:force], title, options[:verbose]
        end
      }
    end
    return 1
  end
=end

  def Svt_play.download_episodes options, url, search_string
    series, episodes_list = search_episodes options, url, search_string

    total_count = episodes_list.size
    downloaded_count = 0
    excluded = 0

    episodes_list.each { |episode|
      puts "Downloading #{series}: #{episode.title} from url #{episode.url}" if options[:verbose]

      begin
        download_episode options, episode.url
        downloaded_count+=1
      rescue Exception => e
        excluded+=1 if e.message==="File excluded"
        raise e if !(e.message==="File exists" or e.message==="File excluded")
      end
    }

    return downloaded_count, excluded, total_count
  end
end
