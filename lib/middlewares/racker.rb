# frozen_string_literal: true

require 'erb'
require 'codebreaker/game'

module Middlewares
  # Main controller class
  class Racker
    def self.call(env)
      new(env).response.finish
    end

    def initialize(env)
      @request = Rack::Request.new(env)
      @game = Codebreaker::Game.new
      @hints_list = []
    end

    def render(template)
      path = File.expand_path("../../../public/#{template}", __FILE__)
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
      when '/show_hint' then show_hint
      else Rack::Response.new('Not Found', 404)
      end
    end

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
      @request.session[:resume] = true
      @game.new_game(@request.params['player_name'], @request.params['level'].to_sym)
      @request.session[:player_name] = @request.params['player_name']
      @request.session[:level] = @request.params['level']
      save_data
    end

    def resume_game
      play
      save_data
    end

    def save_data
      @request.session[:attempts] = @game.attempts
      @request.session[:hints] = @game.hints
      @request.session[:game] = @game
    end

    def play
      @hints_list = @request.session[:hints_list] || []
      @game = @request.session[:game]
      @request.session[:last_number] = @request.params['number']
      last_result = @game.play(@request.params['number'])
      return win if last_result == '++++'
      return lose if last_result =~ /^[1-6]{4}$/

      result(last_result)
    end

    def result(result_str)
      result_arr = result_str.chars
      @first = result_arr[0] || 'X'
      @second = result_arr[1] || 'X'
      @third = result_arr[2] || 'X'
      @forth = result_arr[3] || 'X'
    end

    def button_class(result)
      case result
      when '+' then 'btn btn-success marks'
      when '-' then 'btn btn-primary marks'
      else 'btn btn-danger marks'
      end
    end

    def statistics
      return Rack::Response.new(render('game.html.erb')) if resume?

      @number = 0
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
      @request.session[:player_name]
    end

    def level
      @request.session[:level]
    end

    def attempts
      @request.session[:attempts]
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

    def number
      @number += 1
    end

    def last_number
      @request.session[:last_number] || '1234'
    end

    def show_hint
      @game = @request.session[:game]
      @hints_list = @request.session[:hints_list] || []
      new_hint = @game.hint
      @hints_list.push(new_hint) unless new_hint.nil?
      @request.session[:hints_list] = @hints_list

      Rack::Response.new(render('game.html.erb'))
    end
  end
end
