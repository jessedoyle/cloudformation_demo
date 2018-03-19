class HealthChecksController < ActionController::Metal
  def new
    self.response_body = '{"success":true}'
    self.content_type = 'application/json'
    self.status = 200
  end
end
