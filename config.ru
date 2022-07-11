require 'rack'
require './lib/middlewares/racker'

use Rack::Reloader
use Rack::Session::Cookie, :key => 'rack.session',
    :path => '/',
    :expire_after => 300,
    :secret => 'secret',
    :old_secret => 'old_secret'
use Rack::Static, urls: ['/assets'], root: 'public'
run Middlewares::Racker
