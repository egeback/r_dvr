require_relative 'svt-play/model/stream'
require_relative 'svt-play/model/series'
require_relative 'svt-play/model/episode'
require_relative 'svt-play/download'
require_relative 'svt-play/parse'
require_relative 'svt-play/search'
require 'uri'

module SVT_PLAY
  $baseurl = "http://www.svtplay.se/"
  #$barnurl = "http://www.svt.se/barnkanalen/barnplay/"

  def supported url
    uri = URI.parse(url)
    uri.host.include? 'www.svtplay.se'
  end
end
