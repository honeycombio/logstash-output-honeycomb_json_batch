# logstash-output-honeycomb_json_batch

A logstash plugin for interacting with [Honeycomb](https://honeycomb.io) at high volumes. (See here for more information about [using Honeycomb](https://honeycomb.io/intro/) and [its libraries](https://honeycomb.io/docs/send-data/sdks).)

At lower volumes, it may be simpler to use the standard logstash `http` output plugin and provide Honeycomb-specific values. (See here for more information about [using the standard logstash http output plugin](https://honeycomb.io/docs/send-data/connectors/logstash).)

This plugin is a heavily modified version of the standard logstash [http output](https://github.com/logstash-plugins/logstash-output-http) plugin and the [Lucidworks JSON batch plugin](https://github.com/lucidworks/logstash-output-json_batch).

## Installation

The easiest way to use this plugin is by installing it through rubygems like any other logstash plugin. To get the latest version installed, you should run the following command: `bin/logstash-plugin install logstash-output-honeycomb_json_batch`

*TODO*: publish to rubygems

## Usage

The default batch size is 50, the default flush interval is 5 seconds, and each of those can be overridden via the plugin config.

A simple config to test this might be:

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
