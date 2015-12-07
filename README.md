[![Gem Version](https://badge.fury.io/rb/rack-jive-signed_request.svg)](http://badge.fury.io/rb/rack-jive-signed_request)
[![Build Status](https://travis-ci.org/butchmarshall/rack-jive-signed_request.svg?branch=master)](https://travis-ci.org/butchmarshall/rack-jive-signed_request)

# Jive Signed Request Middleware

`Rack::Jive::SignedRequest` provides support for handling [Jive](https://www.jivesoftware.com/) signed requests in Rack compatible applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack-jive-signed_request', :require => 'rack-jive-signed_request'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-jive-signed_request

# Configuration

## Rack

In the `config.ru`

```ruby
use Rack::Jive::SignedRequest
	# Your app might support multiple Jive instances
	# This block allows you to determine what secret to use based on the Authorization header
	secret do |auth_header_params|
		"this_should_be_the_app_secret_for_authentication_header_params"
	end
end
```

## Rails

In `config/application.rb`
```ruby
module ExampleApp
	class Application < Rails::Application
		config.middleware.use "Rack::Jive::SignedRequest" do
			# Your app might support multiple Jive instances
			# This block allows you to determine what secret to use based on the Authorization header
			secret do |auth_header_params|
				"this_should_be_the_app_secret_for_authentication_header_params"
			end
		end
	end
end
```

# Usage

`request.env['jive.user_id']` will be populated with the authenticated users Jive ID

`request.env['jive.email']` will be populated with the authenticated users Jive Email

`request.env['jive.errors.signed_request']` will be populated if there was an error authenticating the signed request

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rack-jive-signed_request.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

