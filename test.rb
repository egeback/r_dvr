require 'open-uri'
require 'rubygems'
require 'streamio-ffmpeg'

movie = FFMPEG::Movie.new(open("http://svtplay16o-f.akamaihd.net/i/se/open/20150212/1332329-036A/EPISOD-1332329-036A-07b6b38d61e0d2f3_,892,144,252,360,540,1584,2700,.mp4.csmil/index_6_av.m3u8?null="))
puts movie.duration
puts movie.bitrate
