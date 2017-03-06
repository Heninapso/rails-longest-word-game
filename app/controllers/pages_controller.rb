require 'open-uri'
require 'json'

GRID = Array.new(9) { ('A'..'Z').to_a[rand(26)] }
class PagesController < ApplicationController
  def game
    @grid = GRID
  end

  def score
    @guess = params[:guess]
    @grid = GRID
    @start_time = Time.now
    @end_time = Time.now

    def included?(guess, grid)
      @guess.all? { |letter| @guess.count(letter) <= @grid.count(letter) }
    end

    def compute_score(guess, start_time, end_time)
      ((@end_time - @start_time) > 60.0) ? 0 : @guess.size * (1.0 - (@end_time - @start_time) / 60.0)
    end

    def run_game(guess, grid, start_time, end_time)
      result = { time: @end_time - @start_time }
      result[:translation] = get_translation(@guess)
      @result = result[:score], @result[:message] = score_and_message(@guess, result[:translation], @grid, result[:time])
    end

    def score_and_message(guess, translation, grid, time)
      if included?(@guess.upcase, @grid)
        if @guess_translated
          @score = compute_score(@guess, time)
          [@score, "well done"]
        else
          [0, "not an english word"]
        end
      else
        [0, "not in the grid"]
      end
    end

    def get_translation(guess)
      api_key = "bb0585d9-e4f5-49c4-b74a-5ca962973a68"
      begin
        response = open("https://api-platform.systran.net/translation/text/translate?source=en&target=fr&key=#{api_key}&input=#{@guess}")
        json = JSON.parse(response.read.to_s)
        if json['outputs'] && json['outputs'][0] && json['outputs'][0]['output'] && json['outputs'][0]['output'] != word
          @guess_translated = json['outputs'][0]['output']
        end
      rescue
        if File.read('/usr/share/dict/words').upcase.split("\n").include? guess.upcase
          @guess = guess
        else
          return nil
        end
      end
    end
  end
end
