# This causes rails created_at, updated_at, etc. to be formatted in JSON
# responses as seconds since 1970 instead of ISO 8601 strings
class ActiveSupport::TimeWithZone
  def as_json(options = {})
    to_f
  end
end
