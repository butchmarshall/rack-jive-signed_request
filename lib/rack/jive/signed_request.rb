require "rack"
require "rack/request"
require "rack/jive/signed_request/version"

require "jive/signed_request"

module Rack
	module Jive
		class SignedRequest
			def initialize(app, opts={}, &block)
				@app = app

				if block_given?
					if block.arity == 1
						block.call(self)
					else
						instance_eval(&block)
					end
				end
			end

			def call(env)
				request = Request.new(env)

				status, headers, body = @app.call(env)

				# Only bother authenticating if the request is identifying itself as signed
				if headers["X-Shindig-AuthType"] === "signed" || headers["Authorization"].to_s.match(/^JiveEXTN/)
					auth_header_params = ::CGI.parse headers["Authorization"].gsub(/^JiveEXTN\s/,'')

					begin
						unless ::Jive::SignedRequest.authenticate(headers["Authorization"], @secret.call(auth_header_params))
							return [401, {"Content-Type" => "text/html"}, ["Invalid"]]
						end
					rescue ArgumentError => $e
						return [401, {"Content-Type" => "text/html"}, [$e.message]]
					end
				end

				[status, headers, body]
			end

			def secret(&block)
				@secret = block
			end
		end

		class Request < ::Rack::Request
		end
	end
end
