# encoding: utf-8
require "enumerator"
require "logstash/outputs/base"
require "logstash/namespace"
require "logstash/json"
require "uri"
require "logstash/plugin_mixins/http_client"

class LogStash::Outputs::HoneycombJSONBatch < LogStash::Outputs::Base
  include LogStash::PluginMixins::HttpClient

  concurrency :shared

  config_name "honeycomb_json_batch"

  config :api_host, :validate => :string

  config :write_key, :validate => :string, :required => true

  config :dataset, :validate => :string, :required => true

  config :retry_individual, :validate => :boolean, :default => true

  config :flush_size, :validate => :number, :default => 75

  # The following configuration options are deprecated and do nothing.
  config :idle_flush_time, :validate => :number, :default => 5

  config :pool_max, :validate => :number, :default => 10

  VERSION = "0.3.0"

  def register
    @total = 0
    @total_failed = 0
    if @api_host.nil?
      @api_host = "https://api.honeycomb.io"
    elsif !@api_host.start_with? "http"
      @api_host = "http://#{ @api_host }"
    end
    @api_host = @api_host.chomp

    logger.info("Initialized honeycomb_json_batch with settings",
      :api_host => @api_host,
      :headers => request_headers,
      :retry_individual => @retry_individual)
  end

  def close
    client.close
  end

  def multi_receive(events)
    events.each_slice(@flush_size) do |chunk|
      documents = []
      chunk.each do |event|
        data = event.to_hash()
        timestamp = data.delete("@timestamp")
        doc = { "time" => timestamp, "data" => data }
        if samplerate = data.delete("@samplerate")
          doc["samplerate"] = samplerate.to_i
        end
        documents.push(doc)
      end
      make_request(documents)
    end
  end

  private

  def make_request(documents)
    body = LogStash::Json.dump(documents)

    url = "#{@api_host}/1/batch/#{@dataset}"
    request = client.post(url, {
      :body => body,
      :headers => request_headers
    })

    request.on_success do |response|
      if response.code >= 200 && response.code < 300
        @total = @total + documents.length
        @logger.debug("Successfully submitted batch",
          :num_docs => documents.length,
          :response_code => response.code,
          :total => @total,
          :thread_id => Thread.current.object_id,
          :time => Time::now.utc)
      else
        if documents.length > 1 && @retry_individual
          if statuses = JSON.parse(response.body).values.first
            statuses.each_with_index do |status, i|
              code = status["status"]
              if code == nil
                @logger.warn("Status code missing in response: #{status}")
                next
              elsif code >= 200 && code < 300
                next
              end
              make_request([documents[i]])
            end
          end
        else
          @total_failed += documents.length
          log_failure(
              "Encountered non-200 HTTP code #{response.code}",
              :response_code => response.code,
              :url => url,
              :response_body => response.body,
              :num_docs => documents.length,
              :retry_individual => @retry_individual,
              :total_failed => @total_failed)
        end
      end
    end

    request.on_failure do |exception|
      @total_failed += documents.length
      log_failure("Could not access URL",
        :url => url,
        :method => @http_method,
        :body => body,
        :headers => request_headers,
        :message => exception.message,
        :class => exception.class.name,
        :backtrace => exception.backtrace,
        :total_failed => @total_failed
      )
    end

    @logger.debug("Submitting batch",
          :num_docs => documents.length,
          :total => @total,
          :thread_id => Thread.current.object_id,
          :time => Time::now.utc)
    request.call

  rescue Exception => e
    log_failure("Got totally unexpected exception #{e.message}", :docs => documents.length)
  end

  # This is split into a separate method mostly to help testing
  def log_failure(message, opts)
    @logger.error("[Honeycomb Batch Output Failure] #{message}", opts)
  end

  def request_headers()
    {
      "Content-Type" => "application/json",
      "X-Honeycomb-Team" => @write_key,
      "X-Plugin-Version" => VERSION
    }
  end
end
