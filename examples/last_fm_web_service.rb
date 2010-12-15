require 'resthome'

class LastFmWebService < RESTHome
  base_uri 'http://ws.audioscrobbler.com'

  namespace '/2.0' do
    route :user_neighbors, '/', :query => {'method' => 'user.getneighbours', 'user' => :arg1} do |res|
      res['neighbours']['user']
    end

    route :track, '/', :query => {'method' => 'track.getinfo', 'artist' => :arg1, 'track' => :arg2}, :resource => 'track'

    route :user_albums, '/', :query => {'method' => 'library.getalbums', 'user' => :arg1}, :resource => 'albums'

    route :user_top_albums, '/', :query => {'method' => 'user.gettopalbums', 'user' => :arg1} do |res|
      res['topalbums']['album']
    end

    route :user_top_tracks, '/', :query => {'method' => 'user.gettoptracks', 'user' => :arg1} do |res|
      res['toptracks']['track']
    end
  end

  def initialize(api_key)
    @api_key = api_key
  end
  
  def build_options!(options)
    options[:query] ||= {}
    options[:query]['format'] = 'json'
    options[:query]['api_key'] = @api_key
  end
end
