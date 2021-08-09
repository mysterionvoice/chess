require './lib/chess.rb'

$players = []
COMMANDS = ['l', 'n', 'e']

def play_move(game, move)
    game.execute_move(move, true)
    game.change_player
end

def save_game(game)
    print "Please enter the name of your save file: "
    fname = gets.chomp
    game.save_state(fname)
end

def promote_piece(game)
    options = ['Q', 'R', 'B', 'K']
    piece = game.last_moved_piece
    player = piece.white == true ? game.p1 : game.p2
    color = piece.white
    if player.is_a?(Chess_AI)
        new_piece = Queen.new(color)
    else
        puts "You can now promote this pawn, what would you like it to become: "
        puts "Q - Queen"
        puts "R - Rook"
        puts "B - Bishop"
        puts "K - Knight"
        print "-> "
        input = gets.chomp.upcase
        until options.include?(input)
            print "Sorry that wasn't one of the options, just type a single letter: "
            input = gets.chomp.upcase
        end
        if input == 'Q'
            new_piece = Queen.new(color)
        elsif input == 'R'
            new_piece = Rook.new(color)
        elsif input == 'B'
            new_piece = Bishop.new(color)
        else
            new_piece = Knight.new(color)
        end
    end
    game.promote(piece, new_piece)
end

def play_game(game)
    until game.check_mate?
        game.show_board
        puts "#{game.current_player.name} is in check!" if game.check?
        if game.current_player.is_a?(Chess_AI)
            puts "It is #{game.current_player.name}'s turn, they are currently thinking..."
        else
            puts "It is #{game.current_player.name}'s turn, please type in your move in '<location from> - <location to>' format."
            puts "Example a4 - a5 would be a move for a4 to a5. Type 'save' to save the current game state."
            print "-> "
        end
        move = game.get_move
        if game.current_player.is_a?(Chess_AI)
            puts "The AI will go with #{move[0][1]}#{move[0][0].to_s} - #{move[1][1]}#{move[1][0].to_s}!"
            sleep(2)
        end
        if move == 'save'
            save_game(game)
            return nil
        else
            until game.valid_move?(move)
                print "Sorry that isn't a valid move, please try again: "
                move = game.get_move
                if move == 'save'
                    break
                end
            end
            if move == 'save'
                save_game(game)
                return nil
            else
                play_move(game, move)
                if game.promote?
                    promote_piece(game)  
                end
            end
        end
    end
    game.show_board
    puts "#{game.current_player.name} has been checkmated! #{game.other_player.name} wins!"
end

def get_player
    name = gets.chomp
    while $players.include?(name)
        print "Sorry that name is taken: "
        name = gets.chomp
    end
    $players.push(name)
    return name
end

def show_main_menu
    puts "\n"
    puts "Welcome to Ruby Chess! Playable chess on the linux console."
    puts "Please enter one of the following commands to continue: "
    puts "n - new game"
    puts "l - load game"
    puts "e - exit"
end

def get_command(commands)
    command = gets.chomp.downcase
    until commands.include?(command)
        print "That isn't a valid command: "
        command = gets.chomp.downcase
    end
    return command
end

def create_new_game
    puts "Welcome to Chess"
    print "Player 1 enter your name: "
    p1_name = get_player
    print "Player 2 enter your name: "
    p2_name = get_player
    $players = []
    return Chess.new(Player.new(p1_name, true), Player.new(p2_name, false))
end

def load_game
    if Dir.exist?("saves") && !Dir.empty?("saves")
        children = Dir.children("saves")
        puts "These are your current save states:"
        saves = []
        children.each_with_index do |child, i|
            puts "#{i + 1}: #{child}"
            saves.push(i + 1)
        end
        print "Enter the save number you wish to open: "
        input = gets.chomp
        input = input.to_i if input != 'e'
        until saves.include?(input) || input == 'e'
            print "That isn't an option please type a number or 'e' to return to the main menu: "
            input = gets.chomp
            input = input.to_i if input != 'e'
        end
        if input == 'e'
            return nil
        else
            fname = ""
            children.each_with_index do |child, i|
                fname = child if (i + 1 == input)
            end
            p1 = Player.new('placeholder', true)
            p2 = Player.new('placeholder2', false)
            game = Chess.new(p1, p2)
            return game.load_state(fname)
        end
    else
        puts "You have no current save files."
    end
end

# main loop for using the API
while true
    show_main_menu
    print "-> "
    command = get_command(COMMANDS)
    if command == 'n'
        game = create_new_game
    elsif command == 'l'
        game = load_game
    else
        puts "Have a good day!"
        break
    end
    if game == nil
        next
    else
        play_game(game)
    end
end