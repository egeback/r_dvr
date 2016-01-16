require_relative 'viasatplay/download'
#require_relative 'svt-play/parse'
require_relative 'viasatplay/search'
require_relative 'r_dvr'
require 'uri'

module Viasatplay
  $baseurl = "https://playapi.mtgx.tv/v3/formats?device=mobile&premium=open&country=se"

  def Viasatplay.supports? url
    uri = URI.parse(url)
    uri.host.include? 'mtgx.tv'
  end
end
