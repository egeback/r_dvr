module Svt_play
  def Svt_play.download_episode options, episode
=begin
    playlist = open(episode.url)
    streams = parse_playlist playlist

    streams.sort! { |a,b| a.bandwidth <=> b.bandwidth }

    puts "Found stream:" if options[:verbose]
    puts puts "#{streams[-1].bandwidth}: '#{streams[-1].url}'" if options[:verbose]

    puts streams[-1].url if options[:verbose]
    if streams[-1].url.include? "m3u8?null="
      playlist = open(streams[-1].url)
      streams = Svt_play::parse_playlist playlist
    end

    R_dvr::download_stream streams[-1], "#{options[:folder]}#{episode.title}.mkv", options[:force], episode.title, options[:verbose]
=end

  puts "Url: #{episode.url}" if options[:verbose]
  playlist = open(episode.url)

  streams = Svt_play::parse_playlist playlist

  streams.sort! { |a,b| a.bandwidth <=> b.bandwidth }

  puts "Found streams:" if options[:verbose]
  streams.each{|stream| puts "#{stream.bandwidth}: #{stream.url}"} if options[:verbose]


=begin
  if streams[-1].url.include? "m3u8?null="
    playlist = open(streams[-1].url)
    #streams = Svt_play::parse_playlist playlist
    stream = streams[-1]
    stream.url = "'#{streams[-1].url}'"
    streams = [stream]
  end
=end

  puts streams[-1].url if options[:verbose]

  puts "Bandwith: #{(highest_bandwidth_url streams).bandwidth}" if options[:verbose]

  R_dvr::download_stream streams[streams.length-1], "#{options[:folder]}#{episode.title}.mkv", options[:force], episode.title, options[:verbose]

  end

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
