require 'spec_helper'

describe Rack::Jive::SignedRequest do
	CLIENT_ID = "682a638ba74a4ff5fa6afa344b163e03.i"
	TENANT_ID = "b22e3911-28ef-480c-ae3b-ca791ba86952"
	ALGORITHM = "sha256";
	JIVE_URL = "https://sandbox.jiveon.com:8443"
	SECRET = "8bd2952b851747e8f2c937b340fed6e1.s";

	let(:app) { proc { |env|
		[200, env, ['succes']] }
	}
	let(:middleware) {
		Rack::Jive::SignedRequest.new(app, {}) do
			secret do |auth_header_params|
				SECRET
			end
		end
	}

	def env_for url, opts={}
		Rack::MockRequest.env_for(url, opts)
	end

	describe 'when signed request header is valid' do
		it 'should not process requests that dont identify themselves as signed jive requests' do
			timestamp = (Time.now.to_i)*1000
			str = "algorithm=HmacSHA256&client_id=#{CLIENT_ID}&jive_url=#{CGI.escape(JIVE_URL)}&tenant_id=#{TENANT_ID}&timestamp=#{timestamp}";
			signature = ::Jive::SignedRequest.sign(str, SECRET, ALGORITHM)
			authorization_header = "#{str}&signature=#{CGI::escape(signature)}";

			code, env, body = middleware.call env_for('/', {
				:method => "POST",
				"HTTP_AUTHORIZATION" => authorization_header,
			})

			expect(env["jive.errors.signed_request"]).to eq(nil)
		end
		
		it 'should populate the env with jive variables', :focus => true do
			timestamp = (Time.now.to_i)*1000
			str = "algorithm=HmacSHA256&client_id=#{CLIENT_ID}&jive_url=#{CGI.escape(JIVE_URL)}&tenant_id=#{TENANT_ID}&timestamp=#{timestamp}";
			signature = ::Jive::SignedRequest.sign(str, SECRET, ALGORITHM)
			authorization_header = "JiveEXTN #{str}&signature=#{CGI::escape(signature)}";

			code, env, body = middleware.call env_for('/', {
				:method => "POST",
				"HTTP_AUTHORIZATION" => authorization_header,
				"HTTP_X_JIVE_USER_ID" => "123",
				"HTTP_X_JIVE_USER_EMAIL" => "unit-test@jive.com"
			})

			expect(env["jive.errors.signed_request"]).to eq(nil)
			expect(env["jive.user_id"]).to eq("123")
			expect(env["jive.email"]).to eq("unit-test@jive.com")
			expect(env["jive.client_id"]).to eq(CLIENT_ID)
			expect(env["jive.tenant_id"]).to eq(TENANT_ID)
			expect(env["jive.external"]).to eq(false)
		end
	end

	describe 'when signed request header is invalid' do
		it 'rejects the request when expired' do
			# First build a valid signature
			timestamp = (Time.now.to_i-(6*60))*1000
			str = "algorithm=HmacSHA256&client_id=#{CLIENT_ID}&jive_url=#{CGI.escape(JIVE_URL)}&tenant_id=#{TENANT_ID}&timestamp=#{timestamp}";
			signature = ::Jive::SignedRequest.sign(str, SECRET, ALGORITHM)
			authorization_header = "JiveEXTN #{str}&signature=#{CGI::escape(signature)}";

			code, env, body = middleware.call env_for('/', {
				:method => "POST",
				"HTTP_X_SHINDIG_AUTHTYPE" => "signed",
				"HTTP_AUTHORIZATION" => authorization_header,
			})

			expect(env["jive.errors.signed_request"]).to_not equal(nil)
			expect(env["jive.user_id"]).to equal(nil)
			expect(env["jive.email"]).to equal(nil)
			expect(env["jive.client_id"]).to eq(nil)
			expect(env["jive.tenant_id"]).to eq(nil)
		end

		it 'rejects the request when malformed' do
			# First build a valid signature
			timestamp = (Time.now.to_i-(3*60))*1000
			str = "algorithm=HmacSHA256&client_id=#{CLIENT_ID}-err&jive_url=#{CGI.escape(JIVE_URL)}&tenant_id=#{TENANT_ID}&timestamp=#{timestamp}";
			signature = ::Jive::SignedRequest.sign(str, SECRET, ALGORITHM)
			authorization_header = "JiveEXTN #{str}&signature=#{CGI::escape(signature)}-malform";

			code, env, body = middleware.call env_for('/', {
				:method => "POST",
				"HTTP_X_SHINDIG_AUTHTYPE" => "signed",
				"HTTP_AUTHORIZATION" => authorization_header,
			})

			expect(env["jive.errors.signed_request"]).to_not equal(nil)
			expect(env["jive.user_id"]).to equal(nil)
			expect(env["jive.email"]).to equal(nil)
			expect(env["jive.client_id"]).to eq(nil)
			expect(env["jive.tenant_id"]).to eq(nil)
		end
	end
end
