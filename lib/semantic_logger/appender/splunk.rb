require 'splunk-sdk-ruby'

# Note: Not recommended to use the colorized formatter.
class SemanticLogger::Appender::Splunk < SemanticLogger::Appender::Base
  attr_reader :config, :index, :service, :service_index

  # Allow the level for this appender to be overwritten
  #   Default: :error
  def initialize(options, level=:error, &block)
    # Parse input options for setting up splunk connection
    parse_options(options)

    reopen

    # Pass on the level and custom formatter if supplied
    super(level, &block)
  end

  # After forking an active process call #reopen to re-open
  # open the handles to resources
  def reopen
    # Connect to splunk. Connect is a synonym for creating a Service by hand and calling login.
    @service       = Splunk::connect(@config)

    # The index we are logging to
    @service_index = @service.indexes[@index]
  end

  # Log the message to Splunk
  def log(log)
    # Ensure minimum log level is met, and check filter
    return false if (level_index > (log.level_index || 0)) || !include_message?(log)
    # Submit the log message
    @service_index.submit(formatter.call(log))
    true
  end

  private

  def parse_options(options)
    @config = {
      scheme:   options[:scheme] || :https,
      host:     options[:host] || 'localhost',
      port:     options[:port] || 8089,
      username: options[:username],
      password: options[:password]
    }

    @index = options[:index] || 'main'

    if @config[:username].nil?
      raise ArgumentError, 'Must supply a username.'
    elsif @config[:password].nil?
      raise ArgumentError, 'Must supply a password.'
    elsif @index.nil?
      raise ArgumentError, 'Must supply an index.'
    end
  end
end
