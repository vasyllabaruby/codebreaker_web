require 'rack'
require 'thin'
require './lib/middlewares/racker'

use Rack::Reloader
use Rack::Session::Cookie, :key => 'rack.session',
    :path => '/',
    :expire_after => 1,
    :secret => 'secret',
    :old_secret => 'old_secret'
use Rack::Static, urls: ['/assets'], root: 'codebreaker-web-template'
run Middlewares::Racker
