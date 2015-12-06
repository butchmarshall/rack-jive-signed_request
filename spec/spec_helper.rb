$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rack/request'
require 'rack/mock'
require 'rack/jive/signed_request'
