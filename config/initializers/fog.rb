if Rails.env.production?
  CarrierWave.configure do |config|
    config.fog_credentials = {
      provider:                'AWS',
      aws_access_key_id:       Rails.configuration.s3.id,
      aws_secret_access_key:   Rails.configuration.s3.access_key,
      endpoint:                "https://s3.amazonaws.com",
      region:                  'us-east-1'
    }
    config.fog_directory  = Rails.configuration.s3.bucket
    config.fog_public     = true
  end
end
