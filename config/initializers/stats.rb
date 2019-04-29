StatsD.prefix = "Musicfeed"
StatsD.default_sample_rate = 1
# we should use backend as datadog becauuse of using tags inside
StatsD.backend = StatsD::Instrument::Backends::UDPBackend.new("localhost:8125", :datadog)

STATSD_TAGS = ["env:#{Rails.env}"].freeze

STATSD_REQUEST_METRICS = {
  "request.success"               => 200,
  "request.redirect"              => 302,
  "request.bad_request"           => 400,
  "request.not_found"             => 404,
  "request.too_many_requests"     => 429,
  "request.internal_server_error" => 500,
  "request.bad_gateway"           => 502
}.freeze

# class Middleware ; end
#
# class Middleware::StatsDMonitor
#   def initialize(app)
#     @app = app
#   end
#
#   def call(env)
#     @app.call(env)
#   end
# end

# Middleware::StatsDMonitor.extend(StatsD::Instrument)
# Middleware::StatsDMonitor.statsd_measure(:call, "request.duration", tags: STATSD_TAGS)

# STATSD_REQUEST_METRICS.each do |name, code|
#  Middleware::StatsDMonitor.statsd_count_if(:call, name, tags: STATSD_TAGS) do |status, _env, _body|
#    status.to_i == code
#  end
# end
