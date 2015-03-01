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
  print "Do you want to create it (Y/n/q)? "
  STDOUT.flush
  c = STDIN.getch
  puts c
  exit if !(c === "q" or c === "Q")
  return false if !(c === "y" or c === "Y")
  Dir.mkdir(destination)
  true
end

class String
  def numeric?
    return true if self =~ /^\d+$/
    true if Float(self) rescue false
  end
end


#Load All models
parent_dir = File.expand_path("..", File.dirname(__FILE__))
Dir.glob(parent_dir + "/lib/model/*").each do |file|
  require file
end


#trap("SIGINT") {
  #puts "Ctrl-C pressed. Exiting.\n"
  #throw :ctrl_c
#}
