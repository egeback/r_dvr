#module R_dvr
  class Episode
    attr_accessor :title, :url, :img, :pubDate, :dcDate, :description

    def initialize(title=nil, url=nil, img=nil, pubDate=nil, dcDate=nil, description=nil)
          @title = title
          @url = url
          @img = img
          @pubDate = pubDate
          @dcDate = dcDate
          @description = description
    end
  end
#end
