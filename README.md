# Honeycomb Batch JSON Logstash Plugin

This plugin is a heavily modified version of the standard logstash [http output](https://github.com/logstash-plugins/logstash-output-http) plugin and the [Lucidworks JSON batch plugin](https://github.com/lucidworks/logstash-output-json_batch).

# Usage

Please note that the name of the plugin when used is `json_batch`, since it only supports JSON in its current form.

The default batch size is 50, ...

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

# Installation

The easiest way to use this plugin is by installing it through rubygems like any other logstash plugin. To get the latest version installed, you should run the following command: `bin/logstash-plugin install logstash-output-honeycomb_json_batch`

TODO: publish to rubygems


# Running locally

Install dependencies

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
