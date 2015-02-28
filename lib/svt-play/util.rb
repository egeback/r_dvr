def highest_bandwidth_url streams
  return if streams.size == 0
  stream = streams[0]
  streams[1, streams.size+1].each {|s| stream = s if s.bandwidth > stream.bandwidth}
  return stream
end

def exists file
  File.file?(file)
end

def is_folder f
  file = Shellwords.escape(f)
  #Fix faulty escape
  file = file[1,file.length+1] if file[0,2] == '\~'
  File.directory?(f)
end

def read_input
  print 'Enter choice (q for quit): '
  STDOUT.flush
  STDIN.readline #getch
end

def create_folder? destination
  puts "The folder '#{destination}' does not exist."
  print "Do you want to create it (Y/n)? "
  STDOUT.flush
  c = STDIN.getch
  puts c
  if !(c === "y" or c === "Y")
    exit
  end
  Dir.mkdir(destination)
end

class String
  def numeric?
    return true if self =~ /^\d+$/
    true if Float(self) rescue false
  end
end

#trap("SIGINT") {
  #puts "Ctrl-C pressed. Exiting.\n"
  #throw :ctrl_c
#}

$baseurl = "http://www.svtplay.se/"
#$barnurl = "http://www.svt.se/barnkanalen/barnplay/"
