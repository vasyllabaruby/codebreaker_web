# frozen_string_literal: true

require 'rspec'
require 'rack/test'
require 'i18n'
require_relative 'spec_helper'
require 'middlewares/racker'

OUTER_APP = Rack::Builder.parse_file('config.ru').first
# rubocop:disable Metrics/BlockLength
RSpec.describe Middlewares::Racker do
  include Rack::Test::Methods

  def app
    OUTER_APP
  end

  let(:game) { Codebreaker::Game.new }

  context 'when wrong route' do
    it 'returns status not found' do
      get '/wrong_path'
      expect(last_response).to be_not_found
    end
  end

  context 'when route is ok' do
    it '/ is ok' do
      get '/'
      expect(last_response).to be_ok
    end

    it '/statistics is ok' do
      get '/statistics'
      expect(last_response).to be_ok
    end

    it '/rules is ok' do
      get '/rules'
      expect(last_response).to be_ok
    end
  end

  context '#game' do
    it 'when new game' do
      get '/game', 'player_name' => 'Tester', 'level' => 'easy'
      expect(last_response).to be_ok
    end

    it 'when resume game' do
      game.new_game('Tester', :easy)
      env('rack.session', resume: true, game:)
      get '/game', 'number' => '1111'
      expect(last_response).to be_ok
    end

    it 'when win game' do
      game.new_game('Tester', :easy)
      game.instance_variable_set(:@secret_code, '1111')
      env('rack.session', resume: true, game:)
      get '/game', 'number' => '1111'
      expect(last_response).to be_ok
    end

    it 'when lose game' do
      game.new_game('Tester', :easy)
      game.instance_variable_set(:@attempts, 0)
      env('rack.session', resume: true, game:)
      get '/game', 'number' => '1111'
      expect(last_response).to be_ok
    end
  end

  context '#show_hint' do
    it 'all is ok' do
      game.new_game('Tester', :easy)
      env('rack.session', resume: true, hints_list: [], result_arr: [1, 2, 3, 4], game:)
      get '/show_hint'
      expect(last_response).to be_ok
    end
  end
end
# rubocop:enable Metrics/BlockLength
