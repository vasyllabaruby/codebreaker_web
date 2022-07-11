require 'erb'
require 'codebreaker/game'

module Middlewares
  class Racker
    def self.call(env)
      new(env).response.finish
    end

    def initialize(env)
      @request = Rack::Request.new(env)
      @game = Codebreaker::Game.new
    end

    def render(template)
      path = File.expand_path("../../../codebreaker-web-template/#{template}", __FILE__)
      ERB.new(File.read(path)).result(binding)
    end

    def response
      case @request.path
      when '/' then menu
      when '/game' then game
      when '/statistics' then statistics
      when '/rules' then rules
      when '/win' then win
      when '/lose' then lose
      else Rack::Response.new('Not Found', 404)
      end
    end

    def menu
      return game if session_present?

      Rack::Response.new(render('menu.html.erb'))
    end

    def game
      if session_present?
        resume_game
      else
        new_game
      end
      Rack::Response.new(render('game.html.erb'))
    end

    def new_game
      @game.new_game(@request.params['player_name'], @request.params['level'].to_sym)
      @request.session[:player_name] = @request.params['player_name']
      @request.session[:level] = @request.params['level']
      save_data
    end

    def resume_game
      load_data
      play
      save_data
    end

    def save_data
      @request.session[:attempts] = @game.attempts
      @request.session[:hints] = @game.hints
      @request.session[:game] = @game
    end

    def load_data
      @game = @request.session[:game]
    end

    def step

    end

    def play
      last_result = @game.play(@request.params['number'])
      win if last_result == '++++'
      lose if last_result =~ /^[1-6]{4}$/
      result(last_result)
    end

    #mock
    def result(result_str)
      result_arr = result_str.chars
      @first = result_arr[0]
      @second = result_arr[1]
      @third = result_arr[2]
      @forth = result_arr[3]
    end

    #__________________________

    def statistics
      return game if session_present?

      Rack::Response.new(render('statistics.html.erb'))
    end

    def rules
      return game if session_present?

      Rack::Response.new(render('rules.html.erb'))
    end

    def win
      Rack::Response.new(render('win.html.erb'))
    end

    def lose
      Rack::Response.new(render('lose.html.erb'))
    end

    def last_num
      @request.params['number']
    end

    def attempts
      @request.session[:attempts]
    end

    def session_present?
      @request.session.key?(:player_name)
    end

    def player_name
      @request.session[:player_name]
    end

    def level
      @request.session[:level]
    end

    def hints
      @request.session[:hints]
    end

  end
end