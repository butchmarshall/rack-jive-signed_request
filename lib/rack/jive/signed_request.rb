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

				# Only bother authenticating if the request is identifying itself as signed
				if env["HTTP_X_SHINDIG_AUTHTYPE"] === "signed" || env["HTTP_AUTHORIZATION"].to_s.match(/^JiveEXTN/)
					auth_header_params = ::CGI.parse env["HTTP_AUTHORIZATION"].gsub(/^JiveEXTN\s/,'')

					begin
						unless ::Jive::SignedRequest.authenticate(env["HTTP_AUTHORIZATION"], @secret.call(auth_header_params))
							return [401, {"Content-Type" => "text/html"}, ["Invalid"]]
						end
					rescue ArgumentError => $e
						return [401, {"Content-Type" => "text/html"}, [$e.message]]
					end
				end

				env["jive.user_id"] = env["HTTP_X_JIVE_USER_ID"]
				env["jive.email"] = env["HTTP_X_JIVE_USER_EMAIL"]
				env["jive.external"] = (env["HTTP_X_JIVE_USER_EXTERNAL"] === "true")

				@app.call(env)
			end

			def secret(&block)
				@secret = block
			end
		end

		class Request < ::Rack::Request
		end
	end
end
