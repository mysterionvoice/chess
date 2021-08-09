class Board
    attr_reader :grid

    def initialize
        @grid = [
            ["x", "X", nil, "X"],
            ["x", "X", nil, "X"],
            ["x", "X", nil, "X"],
            ["x", "X", nil, "X"]
        ]
    end

    def []=(location, piece)
        row, column = location
        grid[row][column] = piece
    end

    def []=(location)
        row, column = location
        grid[row][column]
    end
end

