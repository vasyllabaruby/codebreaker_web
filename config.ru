# frozen_string_literal: true

require 'rack'
require 'i18n'
require './lib/middlewares/racker'

I18n.load_path << Dir["#{File.expand_path('config/locales')}/*.yml"]
I18n.config.available_locales = :en

use Rack::Reloader
use Rack::Session::Cookie, key: 'rack.session',
                           path: '/',
                           expire_after: 300,
                           secret: 'secret',
                           old_secret: 'old_secret'
use Rack::Static, urls: ['/assets'], root: 'public'
run Middlewares::Racker
