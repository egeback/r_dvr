require_relative 'ffmpeg/convert'
require_relative 'ffmpeg/output_processor'
require_relative 'ffmpeg/io_patch'
require_relative 'ffmpeg/movie'

module FFMPEG
  # Set the path of the ffmpeg binary.
  # Can be useful if you need to specify a path such as /usr/local/bin/ffmpeg
  #
  # @param [String] path to the ffmpeg binary
  # @return [String] the path you set
  def self.ffmpeg_binary=(bin)
    @ffmpeg_binary = bin
  end

  # Get the path to the ffmpeg binary, defaulting to 'ffmpeg'
  #
  # @return [String] the path to the ffmpeg binary
  def self.ffmpeg_binary
    @ffmpeg_binary || 'ffmpeg'
  end
end
