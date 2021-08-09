require_relative 'game_serialize'

class Player
    include GameSerialize
    attr_reader :name, :white
    def initialize(name, white)
        @name = name
        @white = white
    end
end