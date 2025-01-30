class StructuredLogging
  def self.configure(config)
    # Configure Lograge structured request logging
    config.lograge.enabled = true
    config.lograge.logger = ActiveSupport::Logger.new STDOUT
    config.lograge.formatter = Lograge::Formatters::Json.new
    config.lograge.custom_options = ->(event) do
      request = event.payload[:request]
      e_object = event.payload[:exception_object]
      stacktrace = Rails.backtrace_cleaner.clean(e_object.backtrace) if e_object

      {
        exception: event.payload[:exception],
        params: request.filtered_parameters.except(:controller, :action),
        request_id: request.request_id,
        stacktrace:
      }.compact
    end

    # Configure structured logging for non-lograge logs
    config.colorize_logging = false
    config.logger = StructuredLogging::Logger.new STDOUT
    config.logger.formatter = StructuredLogging::Logger.formatter
  end

  class Logger < ActiveSupport::Logger
    def self.formatter
      Proc.new do |severity, time, progname, msg|
        metadata = { level: severity, time:, app: progname }
        msg = { message: msg } if msg.is_a?(String)
        "#{metadata.merge(msg).compact.to_json}\n"
      end
    end

    def debug(*msg, &block)
      value = as_hash(msg[0], msg[1], &block)
      super(value, &nil)
    end

    def info(*msg, &block)
      value = as_hash(msg[0], msg[1], &block)
      super(value, &nil)
    end

    def warn(*msg, &block)
      value = as_hash(msg[0], msg[1], &block)
      super(value, &nil)
    end

    def error(*msg, &block)
      value = as_hash(msg[0], msg[1], &block)
      super(value, &nil)
    end

    private

    def as_hash(msg, attribs = {})
      msg = yield if block_given?

      raise ArgumentError.new "message must be a string" unless msg.is_a? String
      { message: msg }.merge(attribs || {}).merge request_id: Current.request_id
    end
  end
end
