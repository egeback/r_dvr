module Svt_play
  def Svt_play.parse_playlist playlist
    puts playlist
    streams = Array.new
    stream = nil
    playlist.each do |i|
      #puts i
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
end
