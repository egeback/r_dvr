module Viasatplay
  def Viasatplay.download_episode options, episode
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
end
