module Svt_play
  def Svt_play.parse_playlist playlist
    streams = Array.new
    stream = nil
    split_file = false
    next_f = false
    playlist.each do |i|
      #puts i
      if i.match (/^\#EXT-X-TARGETDURATION/)
        split_file = true
        stream = Stream.new
        stream.bandwidth = 0
        stream.url = "concat:"
      end
      next if  i.match(/^\#EXTM3U/) #i[1, 6] == "EXTM3U"
      next if i.match(/^\#EXT-X-MEDIA:/)
      #Parse header
      if split_file
        if i =~ /#EXTINF:/
          next_f = true
        elsif next_f
          next_f = false
          stream.url = stream.url + i.strip! + "|"
        end
      elsif i.match(/^\#EXT-X-STREAM-INF:/)
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
    streams.push stream if split_file
    streams
  end
end
