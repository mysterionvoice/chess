require_relative 'player'
require_relative 'board'
require_relative 'pieces'
require_relative 'game_serialize'

class Chess
    include GameSerialize
    attr_reader :current_player, :other_player, :current_player_pieces, :board, :p1_pieces, :p2_pieces, :p1, :p2
    @@COLUMNS = ["a","b","c","d","e","f","g","h"]
    @@ROWS = [1, 2, 3, 4, 5, 6, 7, 8]
    def initialize(player1, player2)
        if player1.white == true
            @p1 = player1
            @p2 = player2
        elsif player2.white == true
            @p1 = player2
            @p2 = player1
        elsif player1.white == player2.white
            raise "players must be of different colors"
        end
        @board = Board.new
        fill_board
        @p1_pieces = get_pieces(true)
        @p2_pieces = get_pieces(false)
        @current_player = @p1
        @current_player_pieces = @p1_pieces
        @other_player = @p2
        @previous_official_move = []
        @previous_temp_move = []
        @last_removed_piece = nil
    end

    def show_board
        puts ""
        puts "#{@p2.name}".center(44)
        puts "  -----------------------------------------\n"
        puts @board
        puts "  -----------------------------------------\n"
        puts "#{@p1.name}".center(44)
        puts ""
    end

    def check_mate? #1000 iterations take 1.539 seconds
        # check_mate is when your king is currently in check and all possible moves you could make would leave you in check
        # to know if we are check mate we must first determine if we are in check
        if check?
            # generate a list of valid moves for all of our remaining pieces, then pipe those moves through valid_move?
            # with consideration for checks, if we have no valid moves available to us then we are in check mate
            valid_moves = {}
            @current_player_pieces.each do |piece|
                location = @board.find_piece(piece)
                valid_moves[location] = generate_valid_moveset(piece)
            end
            valid_moves.each_key do |start|
                valid_moves[start].each do |finish|
                    if valid_move?([start, finish], true, true)
                        return false
                    end
                end
            end
            return true
        else
            return false
        end
    end

    def last_moved_piece
        prev_finish = @previous_official_move[1]
        piece = @board.get_piece(prev_finish[0], prev_finish[1])
        return piece
    end

    def get_move
        # when a move is recieved it should be converted to a format that the board can easily use. Ex: [1, 'h']
        # or in other words [row.to_i, column] format and this should remain consistant through the program
        if @current_player.is_a?(Chess_AI)
            return @current_player.make_move(self)
        end
        input = gets.chomp.downcase
        correct = false
        until correct
            return input if input == "save"
            input = input.gsub(" ","").split("-")
            correct_length = input.length == 2
            input = input.map { |item| item = item.split("") }
            bool_arry = []
            input.each do |arry|
                bool_arry.push(@@COLUMNS.any? { |char| char == arry[0] })
                bool_arry.push(@@ROWS.any? { |char| char.to_s == arry[1] })
            end
            correct_orientation = bool_arry.all? { |bool| bool == true }
            correct = correct_length && correct_orientation
            unless correct
                if correct_length
                    puts "It seems that your values are incorrect or in the wrong orientation, make sure it is <letter><number> and within the bounds of the board."
                else
                    puts "Sorry but that isn't correct, make sure you add your '-' character between the locations."
                end
                print "Please try again: "
                input = gets.chomp.downcase
            end
        end
        move_start = [input[0][1].to_i, input[0][0]]
        move_end = [input[1][1].to_i, input[1][0]]
        return [move_start, move_end]
    end

    def promote?
        piece = last_moved_piece
        return false unless piece.is_a?(Pawn)
        if piece.white
            return @previous_official_move[1][0] == 8
        else
            return @previous_official_move[1][0] == 1
        end
    end

    def promote(piece, new_piece)
        location = @board.find_piece(piece)
        @board.remove_piece(location[0], location[1])
        @board.add_piece(new_piece, location[0], location[1])
        puts new_piece.class
        if piece.white
            @p1_pieces.delete(piece)
            @p1_pieces.push(new_piece)
        else
            @p2_pieces.delete(piece)
            @p2_pieces.push(new_piece)
        end
    end

    def check? #1000 iterations take 1.538 seconds
        opposing_pieces = @current_player == @p1 ? @p2_pieces : @p1_pieces
        considered_pieces = []
        valid_movesets = []
        king = @current_player_pieces[@current_player_pieces.index { |piece| piece.is_a?(King) }]
        king_location = @board.find_piece(king)
        king_index = convert_location_to_index(king_location[0], king_location[1])
        opposing_pieces.each do |piece|
            piece_location = @board.find_piece(piece)
            piece_index = convert_location_to_index(piece_location[0], piece_location[1])
            considered_pieces.push(piece) if piece.within_range?(piece_index, king_index)
        end
        considered_pieces.each do |piece|
            valid_movesets.push(generate_valid_moveset(piece))
        end
        valid_movesets.each do |moveset|
            moveset.each do |location|
                return true if location == king_location
            end
        end
        return false
    end

    def change_player
        @current_player_pieces = @current_player == @p1 ? @p2_pieces : @p1_pieces
        @current_player = @current_player == @p1 ? @p2 : @p1
        @other_player = @other_player == @p1 ? @p2 : @p1
    end

    def valid_move?(move, player_matters = true, silence = false)
        # valid_move? is a checklist for certain criteria to declare a move as valid
        piece = @board.get_piece(move[0][0], move[0][1])
        # check that the move is within the givin rows and columns available
        unless within_bounds?(move)
            puts "That move is out of bounds." unless silence
            return false 
        end
        # check that there is a piece at the starting location
        if piece == nil
            puts "There is no piece at that starting location." unless silence
            return false 
        end
        # check that the piece is accessible to the player trying to use it
        if @current_player.white != piece.white && player_matters
            puts "That isn't your piece." unless silence
            return false
        end
        # check that the piece is trying to be moved within its moveset
        unless within_moveset?(piece, move)
            puts "That isn't a valid move for that piece." unless silence
            return false
        end
        # check that it has a valid path
        unless valid_path_for_piece?(piece, move)
            puts "There is a piece in the way." unless silence
            return false
        end
        # check that the movement won't put the player in check
        if player_matters
            unless move_without_check?(move)
                puts "That move would put you in check" unless silence
                return false
            end
        end
        return true
    end

    def execute_move(move, official)
        start = move[0]
        finish = move[1]
        if official
            @previous_official_move = move
        else
            @previous_temp_move = move
        end
        if castle?(move)
            execute_castle(move)
        else
            if en_passant?(move)
                opposing_piece = @board.get_piece(@previous_official_move[1][0], @previous_official_move[1][1])
            else
                opposing_piece = @board.get_piece(finish[0], finish[1])
            end
            piece = @board.get_piece(start[0], start[1])
            piece.moves += 1
            @board.remove_piece(start[0], start[1])
            @last_removed_piece = opposing_piece
            if opposing_piece != nil
                location = @board.find_piece(opposing_piece)
                @board.remove_piece(location[0], location[1])
                if @current_player == @p1
                    @p2_pieces.delete(opposing_piece)
                else
                    @p1_pieces.delete(opposing_piece)
                end
            end
            @board.add_piece(piece, finish[0], finish[1])
        end
    end

    def save_state(filename)
        Dir.mkdir "saves" unless Dir.exist? "saves"
        serial_string = self.serialize
        save = File.new("saves/#{filename}", "w")
        save.puts serial_string
        save.close
    end

    def load_state(filename)
        load_contents = File.read "saves/#{filename}"
        File.delete("saves/#{filename}")
        self.unserialize(load_contents)
        @p1_pieces = get_pieces(true)
        @p2_pieces = get_pieces(false)
        @current_player = @p1.name == @current_player.name ? @p1 : @p2
        @other_player = @p1.name == @other_player.name ? @p1 : @p2
        @current_player_pieces = @current_player == @p1 ? @p1_pieces : @p2_pieces
        return self
    end

    def generate_valid_moveset(piece)
        location = @board.find_piece(piece)
        location_index = convert_location_to_index(location[0], location[1])
        valid_moves = []
        moveset = piece.get_moveset
        moveset += piece.get_special_moves if piece.is_a?(Pawn)
        moveset.each do |move|
            if piece.limited
                finish_index = [location_index[0] + move[0], location_index[1] + move[1]]
                final_pos = convert_index_to_location(finish_index[0], finish_index[1])
                finish = [final_pos[0], final_pos[1]]
                start = [location[0], location[1]]
                valid_moves.push(final_pos) if valid_move?([start, finish], false, true)
            else
                i = 1
                while i < 8
                    altered_move = [move[0] * i, move[1] * i]
                    finish_index = [location_index[0] + altered_move[0], location_index[1] + altered_move[1]]
                    final_pos = convert_index_to_location(finish_index[0], finish_index[1])
                    finish = [final_pos[0], final_pos[1]]
                    start = [location[0], location[1]]
                    if valid_move?([start, finish], false, true)
                        valid_moves.push(final_pos) 
                        i += 1
                    else
                        break
                    end
                end
            end
        end
        return valid_moves
    end

    def undo_last_move(official)
        if official
            start = @previous_official_move[0]
            finish = @previous_official_move[1]
        else
            start = @previous_temp_move[0]
            finish = @previous_temp_move[1]
        end
        piece = @board.get_piece(finish[0], finish[1])
        piece.moves -= 1
        @board.remove_piece(finish[0], finish[1])
        if @last_removed_piece != nil
            @board.add_piece(@last_removed_piece, finish[0], finish[1])
            if @current_player == @p1
                @p2_pieces.push(@last_removed_piece)
            else
                @p1_pieces.push(@last_removed_piece)
            end
        end
        @board.add_piece(piece, start[0], start[1])
    end

    private

    def get_pieces(white)
        pieces = []
        @board.board.each do |array|
            array.each do |item|
                if item.is_a?(Piece) && item.white == white
                    pieces.push(item)
                end
            end
        end
        return pieces
    end

    def castle?(move)
        # castling is when the move is for the king to move 2 space left or right while that rook and the king have yet to move
        # the path must also be clear to make this move
        movement = get_movement(move)
        return false if movement[0] > 0 || (movement[1] != 2 && movement[1] != -2)
        col = move[0][1]
        row = move[0][0]
        king = @board.get_piece(row, col)
        return false unless king.is_a?(King)
        return false if king.moves != 0
        if movement[1] > 0
            rook = @board.get_piece(row, 'h')
            start = [row, 'h']
            finish = [row, 'f']
        else
            rook = @board.get_piece(row, 'a')
            start = [row, 'a']
            finish = [row, 'd']
        end
        return false if rook == nil || rook.moves != 0
        return valid_path?(start, finish)
    end

    def en_passant?(move)
        return false if @previous_official_move == []
        final_col = move[1][1]
        final_row = move[1][0]
        final_piece = @board.get_piece(final_row, final_col)
        return false if final_piece != nil
        prev_final_col = @previous_official_move[1][1]
        prev_final_row = @previous_official_move[1][0]
        prev_piece = @board.get_piece(prev_final_row, prev_final_col)
        return false unless prev_piece.is_a?(Pawn)
        prev_start_col = @previous_official_move[0][1]
        prev_start_row = @previous_official_move[0][0]
        return false unless (prev_start_col == prev_final_col && prev_final_col == final_col)
        if final_row > prev_final_row
            return final_row < prev_start_row
        elsif final_row < prev_final_row
            return final_row > prev_start_row
        else
            return false
        end
    end

    def execute_castle(move)
        movement = get_movement(move)
        start = move[0]
        finish = move[1]
        row = move[0][0]
        king = @board.get_piece(start[0], start[1])
        if movement[1] > 0
            rook = @board.get_piece(row, 'h')
            rook_start = [row, 'h']
            rook_finish = [row, 'f']
        else
            rook = @board.get_piece(row, 'a')
            rook_start = [row, 'a']
            rook_finish = [row, 'd']
        end
        @board.remove_piece(start[0], start[1])
        @board.remove_piece(rook_start[0], rook_start[1])
        @board.add_piece(king, finish[0], finish[1])
        @board.add_piece(rook, rook_finish[0], rook_finish[1])
        king.moves += 1
        rook.moves += 1
    end

    def move_without_check?(move)
        execute_move(move, false)
        if check?
            undo_last_move(false)
            return false
        else
            undo_last_move(false)
            return true
        end
    end

    def fill_board
        i = 0
        8.times do
            piece = Pawn.new(true)
            @board.add_piece(piece, 2, @@COLUMNS[i])
            piece = Pawn.new(false)
            @board.add_piece(piece, 7, @@COLUMNS[i])
            i += 1
        end
        i = 1
        4.times do
            white = (i % 2 == 0)
            rook = Rook.new(white)
            knight = Knight.new(white)
            bishop = Bishop.new(white)
            if(i < 3)
                if(white)
                    @board.add_piece(rook, 1, "a")
                    @board.add_piece(knight, 1, "b")
                    @board.add_piece(bishop, 1, "c")
                else
                    @board.add_piece(rook, 8, "a")
                    @board.add_piece(knight, 8, "b")
                    @board.add_piece(bishop, 8, "c")
                end
            else
                if(white)
                    @board.add_piece(rook, 1, "h")
                    @board.add_piece(knight, 1, "g")
                    @board.add_piece(bishop, 1, "f")
                else
                    @board.add_piece(rook, 8, "h")
                    @board.add_piece(knight, 8, "g")
                    @board.add_piece(bishop, 8, "f")
                end
            end
            i += 1
        end
        i = 0
        2.times do
            white = i % 2 == 0
            king = King.new(white)
            queen = Queen.new(white)
            if white
                @board.add_piece(king, 1, "e")
                @board.add_piece(queen, 1, "d")
            else
                @board.add_piece(king, 8, "e")
                @board.add_piece(queen, 8, "d")
            end
            i += 1
        end
    end

    def within_bounds?(move)    
        starting_pos = move[0]
        end_pos = move[1]
        return (@@COLUMNS.include?(starting_pos[1]) && 
        @@COLUMNS.include?(end_pos[1])) && 
        (@@ROWS.include?(starting_pos[0]) && 
        @@ROWS.include?(end_pos[0]))
    end

    def get_base_movement(movement)
        if movement[0] == 0 || movement[1] == 0
            zero_value = movement[0] == 0 ? 0 : 1
            non_zero_value = movement[0] != 0 ? 0 : 1
            if movement[non_zero_value] > 0
                base_move = [1,1]
            else
                base_move = [-1,-1]
            end
            base_move[zero_value] = 0
        else
            if movement[0] % movement[1] != 0
                return movement
            else
                base_value = movement[0] > 0 ? movement[0] : movement[0] * -1
                base_move = [0,0]
                base_move[0] = movement[0].to_f / base_value.to_f
                base_move[1] = movement[1].to_f / base_value.to_f
            end
        end
        return base_move
    end

    def within_moveset?(piece, move)
        moveset = piece.get_moveset
        moveset += piece.get_special_moves if piece.is_a?(Pawn) || piece.is_a?(King)
        movement = get_movement(move)
        unless piece.limited
            movement = get_base_movement(movement)
        end
        return moveset.include?(movement)
    end
    
=begin
    def within_moveset?(piece, move) old
        moveset = piece.get_moveset
        movement = get_movement(move)
        if piece.is_a?(Pawn)
            special_move = piece.get_special_moves
            if special_move.include?(movement)
                opposing_piece = @board.get_piece(move[1][0], move[1][1])
                if en_passant?(move)
                    return true
                elsif opposing_piece == nil
                    return false
                else
                    return opposing_piece.white != piece.white
                end
            end
        end
        if piece.is_a?(King)
            return true if castle?(move)
        end
        if piece.limited
            unless moveset.include?(movement)
                return false
            end
        else
            if movement[0] == 0 || movement[1] == 0
                zero_value = movement[0] == 0 ? 0 : 1
                non_zero_value = movement[0] != 0 ? 0 : 1
                if movement[non_zero_value] > 0
                    base_move = [1,1]
                else
                    base_move = [-1,-1]
                end
                base_move[zero_value] = 0
                unless moveset.include?(base_move)
                    return false
                end
            else
                if movement[0] % movement[1] != 0
                    return false
                else
                    base_value = movement[0] > 0 ? movement[0] : movement[0] * -1
                    base_move = [0,0]
                    base_move[0] = movement[0].to_f / base_value.to_f
                    base_move[1] = movement[1].to_f / base_value.to_f
                    unless moveset.include?(base_move)
                        return false
                    end
                end
            end
        end
        return true
    end
=end
    
    def get_movement(move)
        starting_pos_index = convert_location_to_index(move[0][0], move[0][1])
        end_pos_index = convert_location_to_index(move[1][0], move[1][1])
        movement = [end_pos_index[0] - starting_pos_index[0], end_pos_index[1] - starting_pos_index[1]]
        return movement
    end

    def get_path(start, finish)
        starting_pos_index = convert_location_to_index(start[0], start[1])
        end_pos_index = convert_location_to_index(finish[0], finish[1])
        path = []
        while starting_pos_index != end_pos_index
            if end_pos_index[0] > starting_pos_index[0]
                starting_pos_index[0] += 1
            elsif end_pos_index[0] < starting_pos_index[0]
                starting_pos_index[0] -= 1
            end
            if end_pos_index[1] > starting_pos_index[1]
                starting_pos_index[1] += 1
            elsif end_pos_index[1] < starting_pos_index[1]
                starting_pos_index[1] -= 1
            end
            path.push(convert_index_to_location(starting_pos_index[0], starting_pos_index[1]))
        end
        return path
    end

    def valid_path?(start, finish)
        path = get_path(start, finish)
        final_piece = @board.get_piece(finish[0], finish[1])
        start_piece = @board.get_piece(start[0], start[1])
        path.each do |pos| 
            piece = @board.get_piece(pos[0], pos[1])
            if piece != nil
                unless piece == final_piece && start_piece.white != final_piece.white
                    return false
                end
            end
        end
        return true
    end

    def valid_path_for_piece?(piece, move)
        if piece.is_a?(Pawn)
            opposing_piece = @board.get_piece(move[1][0], move[1][1])
            movement = get_movement(move)
            if piece.get_special_moves.include?(movement)
                if en_passant?(move)
                    return true
                elsif opposing_piece == nil
                    return false
                else
                    return opposing_piece.white != piece.white
                end
            else
                return opposing_piece == nil
            end
        elsif !(piece.is_a?(Knight))
            unless valid_path?(move[0], move[1])
                return false
            end
        else
            final_piece = @board.get_piece(move[1][0], move[1][1])
            if final_piece != nil
                if final_piece.white == piece.white
                    return false
                end
            end
        end
        return true
    end

    # these functions work in opposite where the recieve 2 items and convert from one format to the other for ease
    # with the 2D array and the board object

    def convert_location_to_index(row, column)
        column = column.ord - 97
        row = 8 - row
        return [row, column]
    end

    def convert_index_to_location(row, column)
        column = (column + 97).chr
        row = (row - 8) * -1
        return [row, column]
    end
end