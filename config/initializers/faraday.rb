ActiveSupport::Notifications.subscribe('request.faraday') do |name, starts, ends, _, env|
  url = env[:url]
  http_method = env[:method].to_s.upcase
  duration_seconds = ends - starts
  metadata = {
    http_method: http_method,
    host: url.host,
    path: url.path,
    duration_ms: duration_seconds * 1000,
    status: env.status,
  }
  Rails.logger.info(
    metadata.to_json
  )
end
