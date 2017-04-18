require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/honeycomb_json_batch"

PORT = rand(65535-1024) + 1025
WRITE_KEY = "YOUR_WRITE_KEY"
DATASET = "YOUR_DATASET"

describe LogStash::Outputs::HoneycombJSONBatch do
  let(:port) { PORT }
  let(:event) { LogStash::Event.new("message" => "hi") }
  let(:api_host) { "http://localhost:#{port}"}
  let(:flush_size) { 15 }
  let(:client) { @honeycomb.client }

  before do
    @honeycomb = LogStash::Outputs::HoneycombJSONBatch.new(
      "write_key" => WRITE_KEY,
      "dataset" => DATASET,
      "api_host" => api_host,
      "flush_size" => flush_size
    )
  end

  before do
    allow(@honeycomb).to receive(:client).and_return(client)
    @honeycomb.register
    allow(client).to receive(:post).and_call_original
  end

  after do
    @honeycomb.close
  end

  it "should receive a single post request" do
    expect(client).to receive(:post).
                        with("#{ api_host }/1/batch/#{DATASET}", hash_including(:body, :headers)).
                        once.
                        and_call_original

    @honeycomb.multi_receive([event])
  end

  it "should attach the right headers for Honeycomb ingestion" do
    expect(client).to receive(:post).
                        with("#{ api_host }/1/batch/#{DATASET}", hash_including(:headers => {
                          "Content-Type" => "application/json",
                          "X-Honeycomb-Team" => WRITE_KEY,
                          "X-Plugin-Version" => LogStash::Outputs::HoneycombJSONBatch::VERSION
                        })).once.
                        and_call_original

    @honeycomb.multi_receive([event])
  end

  it "should wrap events in the right structure for Honeycomb ingestion" do
    data = event.to_hash()
    data.delete("@timestamp")
    expect(client).to receive(:post).
                        with("#{ api_host }/1/batch/#{DATASET}", hash_including(:body => LogStash::Json.dump(
                          [ { "time" => event.timestamp.to_s, "data" => data } ]
                        ))).once.
                        and_call_original
    @honeycomb.multi_receive([event])
  end

  it "should extract timestamp and samplerate from the data" do
    with_samplerate = LogStash::Event.new("alpha" => 1.0, "@samplerate" => "17.5",
                                          "@timestamp" => "2014-11-17T20:37:17.223Z")
    data = with_samplerate.to_hash()
    data.delete("@timestamp")
    data.delete("@samplerate")

    expect(client).to receive(:post).
                        with("#{ api_host }/1/batch/#{DATASET}", hash_including(:body => LogStash::Json.dump(
                          [ { "time" => with_samplerate.timestamp.to_s, "data" => data, "samplerate" => 17 } ]
                        ))).once.
                        and_call_original

    @honeycomb.multi_receive([with_samplerate])
  end

  it "should wrap multiple events up in the right structure" do
    event1 = LogStash::Event.new("alpha" => 1.0)
    event2 = LogStash::Event.new("beta" => 2.0)
    event3 = LogStash::Event.new("gamma" => 3.0)

    expect(client).to receive(:post).
                        with("#{ api_host }/1/batch/#{DATASET}", hash_including(:body => LogStash::Json.dump(
                          [
                            { "time" => event1.timestamp.to_s, "data" => { "alpha" => 1.0, "@version" => "1" } },
                            { "time" => event2.timestamp.to_s, "data" => { "@version" => "1", "beta" => 2.0 } },
                            { "time" => event3.timestamp.to_s, "data" => { "@version" => "1", "gamma" => 3.0 } }
                          ]
                        ))).once.
                        and_call_original

    @honeycomb.multi_receive([event1, event2, event3])
  end

  it "should chunk large batches" do
    events = []
    (1..3*@honeycomb.flush_size).each do |i|
      events.push(LogStash::Event.new("index" => i))
    end
    expect(client).to receive(:post).exactly(3).times.
        and_call_original
    @honeycomb.multi_receive(events)
  end
end
