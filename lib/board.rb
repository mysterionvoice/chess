require_relative 'game_serialize'

class Board
    include GameSerialize
    attr_reader :board
    def initialize 
        @board = []
        8.times do 
            arry = []
            8.times do
                arry.push(nil)
            end
            @board.push(arry)
        end
    end

    def [](index)
        return @board[index]
    end

    def reset!
        @board = []
        8.times do 
            arry = []
            8.times do
                arry.push(nil)
            end
            @board.push(arry)
        end
    end

    def to_s
        outst = "    a    b    c    d    e    f    g    h \n"
        outst +="  -----------------------------------------\n"
        y_axis = 8
        @board.each do |array|
            outst += y_axis.to_s
            array.each do |item|
                if item == nil
                    outst += " |   "
                else
                    outst += " | #{item.to_s}"
                end
            end
            outst += " | #{y_axis}\n"
            y_axis -= 1
            outst +="  -----------------------------------------\n"
        end
        outst += "    a    b    c    d    e    f    g    h \n"
        return outst
    end

    def add_piece(piece, row, column)
        column = column.ord - 97 # converting to an array index
        row = 8 - row
        if @board[row][column] == nil
            @board[row][column] = piece
        else
            raise "There is already a piece in that spot"
        end
    end

    def get_piece(row, column)
        column = column.ord - 97 # converting to an array index
        row = 8 - row
        return @board[row][column]
    end

    def remove_piece(row, column)
        column = column.ord - 97 # converting to an array index
        row = 8 - row
        @board[row][column] = nil
    end

    def move_piece(row_f, column_f, row_t, column_t)
        piece = get_piece(row_f, column_f)
        remove_piece(row_f, column_f)
        add_piece(piece, row_t, column_t)
    end

    def find_piece(piece)
        i = 0
        while i < @board.length
            column = @board[i].index(piece)
            if column == nil
                i += 1
            else
                break
            end
        end
        if column == nil
            return nil
        else
            column = (column + 97).chr
            row = (i - 8) * -1
            return [row, column]
        end
    end
end
