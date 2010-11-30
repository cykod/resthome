require 'resthome'

class LastFmWebService < RESTHome
  route :find_albums, '/2.0/', :query => {'method' => 'library.getalbums'}, :resource => 'albums'
  # find_albums_by_user

  route :find_neighbors, '/2.0/', :query => {'method' => 'user.getneighbours'} do |res|
    res['neighbours']['user']
  end
  # find_neighbors_by_user

  route :find_top_tracks, '/2.0/', :query => {'method' => 'user.gettoptracks'} do |res|
    res['track']['track']
  end
  # find_top_tracks_by_user

  route :find_track, '/2.0/', :query => {'method' => 'track.getinfo'}, :resource => 'track'
  # find_track_by_artist_and_track

  route :find_top_albums, '/2.0/', :query => {'method' => 'user.gettopalbums'} do |res|
    res['topalbums']['album']
  end
  # find_top_albums_by_user

  def initialize(api_key)
    @api_key = api_key
    self.base_uri = "http://ws.audioscrobbler.com"
  end
  
  def build_options!(options)
    options[:query] ||= {}
    options[:query]['format'] = 'json'
    options[:query]['api_key'] = @api_key
  end
end
