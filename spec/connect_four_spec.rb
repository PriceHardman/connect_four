require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "ConnectFour" do
	before :each do
		@game = Game.new
		@game.player1.name = "Me"
		@game.player2.name = "You"
	end

	it "Should feature a Game object" do
		@game.kind_of?(Game).should be_true
	end

	it "Should randomly decide who goes first" do
		@game.who_goes_first
		[@game.player1,@game.player2].should include @game.current_player
	end

	it "Should go to the next player's turn when told to" do
		@game.current_player = @game.player1
		@game.other_player = @game.player2
		@game.switch_current_player
		@game.current_player.should eq @game.player2
		@game.other_player.should eq @game.player1
	end

	it "Should properly assign search paths to the cells on the board" do
		@game.board.grid[5][0].search_paths.should_not include :S
	end

end
