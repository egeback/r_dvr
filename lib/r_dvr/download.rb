module R_dvr
  def R_dvr.download_stream stream, output, force, title=nil, verbose=false
    FFMpeg.convert(stream.url, output, {:acodec => 'mp3', :ab => '160k', :vcodec => 'copy', :force => force, :verbose => verbose}){ |progress, frame, time, fps, bitrate, total_time|
      output = ""
      output = "#{title}: " if title!=nil
      #print "\r#{output}                                                                                         "
      $stdout.flush
      print "\r#{output}Progress: #{progress}%, frame: #{frame}, time: #{time}, fps: #{fps}, bitrate: #{bitrate}kbit/s. Total time: #{total_time}     "
    }
    puts ""
  end

  def R_dvr.download_episodes options, url, search_string
    series, episodes_list = nil
    if Svt_play::supports? url
      series, episodes_list = Svt_play::search_episodes options, url, search_string
    else
      puts "Url not supported."
    end

    total_count = episodes_list.size
    downloaded_count = 0
    excluded = 0

    episodes_list.each { |episode|
      puts "Downloading #{series}: #{episode.title} from url #{episode.url}" if options[:verbose]

      begin
        if Svt_play::supports? episode.url
          Svt_play::download_episode options, episode.url
          downloaded_count+=1
        end
      rescue Exception => e
        excluded+=1 if e.message==="File excluded"
        raise e if !(e.message==="File exists" or e.message==="File excluded")
      end
    }

    return downloaded_count, excluded, total_count
  end
end
