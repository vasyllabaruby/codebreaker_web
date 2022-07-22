# frozen_string_literal: true

require 'erb'
require 'codebreaker/game'
require 'i18n'

module Middlewares
  # Main controller class
  # rubocop:disable Metrics/ClassLength
  class Racker
    def self.call(env)
      new(env).response.finish
    end

    def initialize(env)
      @request = Rack::Request.new(env)
      @hints_list = []
      @result_arr = %w[X X X X]
    end

    def render(template)
      path = File.expand_path("../../../public/#{template}", __FILE__)
      ERB.new(File.read(path)).result(binding)
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    def response
      case @request.path
      when '/' then menu
      when '/game' then game
      when '/statistics' then statistics
      when '/rules' then rules
      when '/win' then win
      when '/lose' then lose
      when '/show_hint' then show_hint
      else Rack::Response.new('Not Found', 404)
      end
    end

    # rubocop:enable Metrics/CyclomaticComplexity

    def menu
      return Rack::Response.new(render('game.html.erb')) if resume?

      Rack::Response.new(render('menu.html.erb'))
    end

    def game
      @redirect = 'game.html.erb'
      if resume?
        resume_game
      else
        new_game
      end
      Rack::Response.new(render(@redirect))
    end

    def new_game
      @game = Codebreaker::Game.new
      @request.session[:resume] = true
      @game.new_game(@request.params['player_name'], @request.params['level'].to_sym)
      @request.session[:hints_list] = []
      @result_arr = %w[X X X X]
      save_data
    end

    def resume_game
      play
      save_data
    end

    def save_data
      @request.session[:game] = @game
      @request.session[:result_arr] = @result_arr
    end

    def play
      @hints_list = @request.session[:hints_list] || []
      @game = @request.session[:game]
      @request.session[:last_number] = @request.params['number']
      @last_result = @game.play(@request.params['number'])
      return win if @last_result == '++++'
      return lose if @last_result =~ /^[1-6]{4}$/

      result(@last_result)
    end

    def result(result_str)
      result_str = 'XXXX' if result_str.nil?
      @result_arr = result_str.chars
      4.times do |i|
        @result_arr[i] = 'X' if @result_arr[i].nil?
      end
    end

    def button_class(result)
      case result
      when '+' then 'btn btn-success marks'
      when '-' then 'btn btn-primary marks'
      else 'btn btn-danger marks'
      end
    end

    def statistics
      @game = Codebreaker::Game.new
      return Rack::Response.new(render('game.html.erb')) if resume?

      Rack::Response.new(render('statistics.html.erb'))
    end

    def rules
      return Rack::Response.new(render('game.html.erb')) if resume?

      Rack::Response.new(render('rules.html.erb'))
    end

    def win
      @request.session[:resume] = false
      @redirect = 'win.html.erb'
    end

    def lose
      @request.session[:resume] = false
      @redirect = 'lose.html.erb'
    end

    def session_present?
      @request.session.key?(:player_name)
    end

    def resume?
      @request.session[:resume]
    end

    def player_name
      @request.session[:game].player.name
    end

    def level
      @request.session[:game].player.difficulty
    end

    def attempts
      @request.session[:game].attempts
    end

    def attempts_total
      @request.session[:game].player.attempts_total
    end

    def hints_total
      @request.session[:game].player.hints_total
    end

    def players_stats
      @game.statistic
    end

    def last_number
      @request.session[:last_number] || '1234'
    end

    def hints
      @request.session[:game].hints
    end

    def hints_left
      @game.player.hints_used
    end

    def show_hint
      @game = @request.session[:game]
      @hints_list = @request.session[:hints_list] || []
      new_hint = @game.hint
      @hints_list.push(new_hint) unless new_hint.nil?
      @request.session[:hints_list] = @hints_list
      @result_arr = @request.session[:result_arr]

      Rack::Response.new(render('game.html.erb'))
    end
  end
  # rubocop:enable Metrics/ClassLength
end
