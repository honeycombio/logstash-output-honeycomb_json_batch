# logstash-output-honeycomb_json_batch [![Gem Version](https://badge.fury.io/rb/logstash-output-honeycomb_json_batch.svg)](https://badge.fury.io/rb/logstash-output-honeycomb_json_batch)

A logstash plugin for interacting with [Honeycomb](https://honeycomb.io) at high volumes. (See here for more information about [using Honeycomb](https://honeycomb.io/intro/) and [its libraries](https://honeycomb.io/docs/send-data/sdks).)

At lower volumes, it may be simpler to use the standard logstash `http` output plugin and provide Honeycomb-specific values. (See here for more information about [using the standard logstash http output plugin](https://honeycomb.io/docs/send-data/connectors/logstash).)

This plugin is a heavily modified version of the standard logstash [http output](https://github.com/logstash-plugins/logstash-output-http) plugin and the [Lucidworks JSON batch plugin](https://github.com/lucidworks/logstash-output-json_batch).

## Installation

The easiest way to use this plugin is by installing it through rubygems like any other logstash plugin. To get the latest version installed, you should run the following command:

```
bin/logstash-plugin install logstash-output-honeycomb_json_batch
```

## Usage

A simple config is:

```
input {
  stdin {
    codec => json_lines
  }
}
output {
  honeycomb_json_batch {
    write_key => "YOUR_TEAM_KEY"
    dataset => "Logstash Batch Test"
  }
}
```

Additional arguments to `honeycomb_json_batch`:
- `flush_size`: Maximum batch size, defaults to 50
- `retry_individual`: On failed requests, whether to retry event sends individually, defaults to true
- `api_host`: Allows you to override the Honeycomb host, defaults to https://api.honeycomb.io

Special logstash fields that will be extracted:

- `@timestamp`: Logstash events contain timestamps by default, and this output will extract it for use as the Honeycomb timestamp
- `@samplerate`: If this special field is populated (e.g. via the `filter` section, this particular event will be weighted as `@samplerate` events in Honeycomb). See the **Sampling** section below.

### Sampling

High volume sites may want to send only a fraction of all traffic to Honeycomb. The drop filter can drop a portion of your traffic, and a mutate filter will ensure that Honeycomb understands that transmitted events are coming through as the result of sampling.

```
filter {
  drop {
    # keep 1/4 of the event stream
    percentage => 75
  }
  mutate {
    add_field => {
      # the events that do make it through represent 4 events
      "@samplerate" => "4"
    }
  }
}
```

## Development

Install dependencies (this assumes you have JRuby with the Bundler gem installed.)

```
bundle install
```

Run tests

```
bundle exec rspec
```

## Run in an installed Logstash

You can build the gem and install it using:

```
gem build logstash-output-honeycomb_json_batch.gemspec
```

And install it into your local logstash instance:

```
logstash-plugin install ./path/to/logstash-output-honeycomb_json_batch-VERSION.gem
```
