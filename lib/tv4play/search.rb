require'json'
require "net/http"
require "uri"

module Tv4play
  def Tv4play.search_series options, search_string
    begin
      uri = URI.parse("http://webapi.tv4play.se//play/programs.json")
      response = Net::HTTP.get_response(uri)
      json = JSON.parse(response.body)#page = Nokogiri::HTML(open("http://www.tv4play.se/tv/tags?is_free=true&order_by=name"))
    rescue OpenURI::HTTPError => e
      puts e.message
      exit
    end

    count = 0
    premium = 0
    programs = Array.new
    json.each{ |object|
      #s = Series.new

      if !object["is_premium"]
        program = Program.new
        program.title = object["name"]
        program.id = object["nid"]
        program.description = object["description"]
        program.icon = object["program_image"]
        program.url = "http://webapi.tv4play.se/play/video_assets?is_live=false&platform=web&node_nids=#{object["nid"]}"
        #puts "#{object["name"]}: #{object["nid"]}"
        programs.push program
        count+=1
      else
        premium+=1
      end
    }

    programs
    #puts count
    #puts premium

    #exit
=begin
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
=end
  end
end
