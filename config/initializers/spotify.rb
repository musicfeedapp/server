require 'rspotify'

if Rails.env.production?
  RSpotify.authenticate("08b6d8ce0a95463f9cc265637bc33c16", "057d618e231a4d07a731f2c59ffe7634")
end
