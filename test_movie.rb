require_relative 'lib/ffmpeg'

movie = FFMpeg::Movie.new ARGV[0]
puts movie.duration
