parent_dir = File.expand_path("..", File.dirname(__FILE__))
Dir.glob(parent_dir + "/lib/r_dvr/*").each do |file|
  require file
end

module R_dvr

end
