module R_dvr
  def R_dvr.download_stream stream, output, force, title=nil, verbose=false
    FFMpeg.convert(stream.url, output, {:acodec => 'mp3', :ab => '160k', :vcodec => 'copy', :force => force, :verbose => verbose}){ |progress, frame, time, fps, bitrate, total_time|
      output = ""
      output = "#{title}: " if title!=nil
      print "\r#{output}                                                                                                               "
      print "\r#{output}Progress: #{progress}%, frame: #{frame}, time: #{time}, fps: #{fps}, bitrate: #{bitrate}kbit/s. Total time: #{total_time}"
    }
    puts ""
  end
end
