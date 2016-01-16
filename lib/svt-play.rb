require_relative 'svt-play/download'
require_relative 'svt-play/parse'
require_relative 'svt-play/search'
require_relative 'r_dvr'
require 'uri'

module Svt_play
  $baseurl = "http://www.svtplay.se/"
  #$barnurl = "http://www.svt.se/barnkanalen/barnplay/"

  def Svt_play.supports? url
    uri = URI.parse(url)
    uri.host.include? 'svtplay'
  end
end
