require 'colorize'

class Cell
	#Each spot on the board is represented by a cell object, which contains the state of that spot
	# (e.g. empty, player1, player2)
	attr_accessor :state
	attr_reader :row, :column, :search_paths
	def initialize(args)
		@state = " " #available to have a move made in it.
		@row = args[:row] #set at initialization
		@column = args[:column] #set at initialization
		@search_paths = [] #will become set based on position on the board.
	end

	def add_search_path(path)
		@search_paths << path
	end
end


class Board
	#the board class is, at its core, a 6x7 array of cell objects. The board class is also responsible for setting the
	#correct searchpaths for the cells, which will be how the game searches for a winner.
	attr_accessor :path_coords
	attr_reader :rows, :columns, :winner, :grid
	def initialize
		@grid = create_board
		@rows = ("A".."F").to_a
		@columns = ("1".."7").to_a
		@path_coords = {:N =>[-1,0],:NE =>[-1,1],:E =>[0,1],:SE =>[1,1],:S =>[1,0],:SW =>[1,-1],:W =>[0,-1],:NW =>[-1,-1]}
	end

	def cell(a1,column = nil)
		#takes either an alphanumeric string argument (e.g. B3), or two Fixnums, and returns cell at those coordinates.
		a1.is_a?(String) ? @grid[@rows.index(a1[0].upcase)][@columns.index(a1[1])] : @grid[a1][column]
	end

	def offset(cell_x_y, x_offset, y_offset)
		@grid[cell_x_y.row + x_offset][cell_x_y.column + y_offset]
	end

	private
	def create_board #creates the board as 6x7 multidimensional array of Cell objects.
		board = Array.new(6){Array.new(7)}
		board.each_with_index do |row,row_number|
			row.each_index do |column_number|
				board[row_number][column_number] = Cell.new({:row => row_number,:column => column_number})
				set_search_paths(board[row_number][column_number])
			end
		end
		board #return the populated array of cell objects.
	end

	def set_search_paths(cell)
		#adds search paths to the appropriate cells. For example, the bottom left cell will get N, NE, and E searchpaths,
		#since SE,S,SW,W,or NW paths would take us off the board. These searchpaths are how we test for a winner,
		#without searching every possible winning configuration.
		if cell.row > 2
			cell.add_search_path(:N) 
		end

		if (cell.row >2) && (cell.column < 4)
			cell.add_search_path(:NE) 
		end

		if cell.column < 4
			cell.add_search_path(:E) 
		end

		if (cell.row<3) && (cell.column < 4)
			cell.add_search_path(:SE)
		end

		if cell.row < 3
			cell.add_search_path(:S)
		end

		if (cell.row<3)&&(cell.column>2)
			cell.add_search_path(:SW)
		end

		if (cell.column > 2)
			cell.add_search_path(:W)
		end

		if (cell.row>2)&&(cell.column>2)
			cell.add_search_path(:NW)
		end
	end
end


class Game
	#This class initialized instances of all the other classes, contains the main game loop, and handles IO.
	attr_accessor :player1,:player2, :current_player, :other_player, :board

	def initialize
		@board = Board.new #initialize the board, along with all the cells
		@player1 = Player.new #initialize player 1
		@player2 = Player.new #initialize player 2
		@current_player = who_goes_first #this var will keep track of whose turn it is.
		@other_player = other_player
		@moves_remaining = 42 #counts down the number of moves remaining
		@game_over = false #
		@winner = nil
	end

	def set_player_symbols
		@player1.symbol = rand>0.5 ? "X".red : "O".blue  #randomly assigns player 1 red X's or blue O's as their symbol
		@player2.symbol = (@player1.symbol == "X".red) ? "O".blue : "X".red #assigns player 2 the other symbol.
	end

	def who_goes_first
		rand>0.5 ? @player1 : @player2 #randomly decides who will go first
	end

	def other_player
		@current_player==@player1 ? @player2 : @player1
	end

	def switch_current_player
		buffer = @current_player
		@current_player = @other_player
		@other_player = buffer
	end

	def state(a1)
		@board.cell(a1).state
	end

	def game_setup
		puts <<-eos
		
		WELCOME TO RUBY CONNECT FOUR


				eos

		print "\nPlayer 1, please enter your name: "
		@player1.name = gets.chomp
		print "\n\nPlayer 2, please enter your name: "
		@player2.name = gets.chomp

		set_player_symbols #randomly sets their symbols

		puts <<-eos

By luck of the draw, #{@current_player.name} will go first, and their symbol is #{@current_player.symbol}.
#{@other_player.name} will go second, and their symbol is #{@other_player.symbol}.

				eos
	end

	def show_board #prints a heredoc showing the board.
		puts <<-eos
   ===============================
   || #{state("A1")} | #{state("A2")} | #{state("A3")} | #{state("A4")} | #{state("A5")} | #{state("A6")} | #{state("A7")} ||
   -------------------------------
   || #{state("B1")} | #{state("B2")} | #{state("B3")} | #{state("B4")} | #{state("B5")} | #{state("B6")} | #{state("B7")} ||
   -------------------------------
   || #{state("C1")} | #{state("C2")} | #{state("C3")} | #{state("C4")} | #{state("C5")} | #{state("C6")} | #{state("C7")} ||
   -------------------------------
   || #{state("D1")} | #{state("D2")} | #{state("D3")} | #{state("D4")} | #{state("D5")} | #{state("D6")} | #{state("D7")} ||
   -------------------------------
   || #{state("E1")} | #{state("E2")} | #{state("E3")} | #{state("E4")} | #{state("E5")} | #{state("E6")} | #{state("E7")} ||
   -------------------------------
   || #{state("F1")} | #{state("F2")} | #{state("F3")} | #{state("F4")} | #{state("F5")} | #{state("F6")} | #{state("F7")} ||
   ===============================
      1   2   3   4   5   6   7   
		eos
	end

	def buffer_space
		puts "\n\n\n\n"
	end

	def turn
		#the procedure every turn
		print "It is #{@current_player.name}'s turn. Make your move by entering the desired column number: "
		input = gets.chomp.to_i #get the move as a string
		validate_turn(input)
		check_for_winner
		switch_current_player
	end

	def validate_turn(column) #checks to see if the move is in bounds and on a vacant cell. If not, asks for another.
		if (1..7).member?(column)
				for i in 0..5
				if (i==5)&&(@board.cell(0,column-1).state!=" ")
					print "Oops, that column is full! Pick a different column: "
					input = gets.chomp.to_i
					validate_turn(input)
				elsif @board.cell(5-i,column-1).state == " "
					@board.cell(5-i,column-1).state = @current_player.symbol #places their symbol in that cell
					@current_player.add_move(@board.cell(5-i,column-1)) #adds that cell into their moves array
					break
				else	
				end
			end			
		else
			print "Uh-oh! Please enter a valid column number:"
			input = gets.chomp.to_i
			validate_turn(input)	
		end
	end

	def check_for_winner
		#For each cell in current player's moves array (i.e. the cells on which they've made moves),
		#perform searches on each search path in that cell's list of valid search_paths.
		@current_player.moves.each do |move|
			#perform searches on each search_path
			move.search_paths.each do |path|
				#initiate a counter at 1. Travel along the given search path and increment the counter if the next cell
				#in the path is in that player's moves array.
				counter = 1
				for i in 1..3
					if @current_player.moves.any?{|x| x==@board.offset(move,
																	   i*(@board.path_coords[path][0]),
																	   i*(@board.path_coords[path][1]))}
						counter+=1
					else
					end
					if counter==4
						@game_over = true
						@winner = @current_player
						break
					else
					end
				end
			end
		end

		#check for a draw
		if (@game_over==false) && (@player1.moves.length+@player2.moves.length==42)
			@game_over = true
		end
	end

	def play
		buffer_space #put blank space at the start
		game_setup
		until @game_over #main game loop, continues until the board reports a winner, which it checks for after every move.
		show_board
		turn
		buffer_space
		end
		show_board
		if @winner==nil
			puts "The game is a draw!"
		else
		puts "Congratulations! #{@winner.name} is the winner. Bye bye!"
		end
	end
end

class Player
	attr_accessor :symbol, :name, :color, :moves
	#we're going to be passing @moves to the board object to check for a winner, so it should be able to
	#read the moves.

	def initialize
		@symbol = nil
		@name = nil
		@moves = []
	end

	def add_move(cell) #adds a cell object to player's moves array
		@moves << cell
	end
end