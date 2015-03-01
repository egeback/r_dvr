module R_dvr
  def R_dvr.search_program options, search_string

    puts "Service: #{options[:service]}" if options[:verbose]
    programs = nil
    if options[:service] === "svtplay"
      programs = Svt_play::search_series options, ARGV[0]
    elsif options[:service] === "tv4play"
      programs = Tv4play::search_series options, ARGV[0]
    else
      puts "#{options[:service]} not supported."
      exit
    end

    puts "Number of programs #{programs.size} found." if options[:verbose]

    #search_string
    puts "Search text: #{search_string}" if options[:verbose]
    program = nil

    map = Blurrily::Map.new
    programs.each_with_index { |p, index|
      if(search_string===p.title)
        program = p
        break
      end
      map.put(p.title, index)
    }

    if program!=nil
      #puts "Found series #{serie.title}"
    elsif
      p "Found:"

      search_programs = Array.new
      search_results = map.find(search_string)

      search_results.each_with_index { |item , index|
        puts "#{index+1}. #{programs[item[0]].title} (rating: #{item[1]})"
        search_programs.push item
      }

      c = nil
      while
        c = read_input
        exit if c[0] === 'q'
        break if c.numeric? and c.to_i > 0 and c.to_i <= search_results.size
      end
      program = programs[search_results[c.to_i-1][0]]
    end

    program
  end
end
