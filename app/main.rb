SIZE_X = 8
SIZE_Y = 8

def tick args
  
  args.state.board ||= Board.new()

  args.outputs.labels << [0, (SIZE_Y * (Square::tile_size + Square::SPACING)) + 18, "check #{team_to_name(0)}", -2, 0, 0, 0, 0] if args.state.board.in_check?(0)
  args.outputs.labels << [0, (SIZE_Y * (Square::tile_size + Square::SPACING)) + 18, "check #{team_to_name(1)}", -2, 0, 0, 0, 0] if args.state.board.in_check?(1)
  args.outputs.labels << [100, (SIZE_Y * (Square::tile_size + Square::SPACING)) + 18, turn_label_centent(args.state.board), -2, 0, 0, 0, 0]
  args.outputs.labels << [300, (SIZE_Y * (Square::tile_size + Square::SPACING)) + 18, args.state.board.message, -2, 0, 0, 0, 0]

  if args.state.board.team_turn == 1
    args.state.ai_will_move_in ||= (args.state.tick_count + rand(23) + 12 ).to_f
    if args.state.ai_will_move_in < args.state.tick_count
      team_1_squares = args.state.board.squares.select{|s| s.piece&.team == 1}.shuffle()
      team_1_squares.each do |team_one_square|
        args.state.board.squares.shuffle().each do |r|
          if team_one_square.move_piece(r)
            break
          end
        end
      end
    end
  end
  if args.state.board.team_turn == 0
    args.state.ai_will_move_in = nil
    if args.inputs.mouse.click
      click = args.inputs.mouse.click
      args.state.board.squares.each do |square|
        if square.did_i_click_you?(click.point.x, click.point.y)
          if(args.state.selected_square&.move_piece(square))
            args.state.selected_square = nil
          elsif square.piece
            args.state.selected_square = square
          else
            args.state.selected_square = nil  
          end
        end
      end
    end
  end

  # args.outputs.labels << [300, (SIZE_Y/2* (Square::tile_size + Square::SPACING)), "winner #{args.state.winner}", -2, 0, 0, 0, 0] if args.state.winner 
  
  if args.inputs.keyboard.key_held.shift
    args.outputs.labels << [100, 68, "D? #{args.state.board.squares.count}?", -2, 0, 0, 0, 0]
  end

  args.state.board.moves.each_with_index do |move, index|
    args.outputs.labels << [100 * SIZE_X , 18 * (index+1), log(move), -2, 0, 0, 0, 0]
  end

  # render grid
  args.state.board.squares.each do |squares|
    squares.render(args.outputs )
  end
end

def log(move)
  "#{team_to_name(move.piece_team)} #{move.piece} " + 
  index_to_chessletter(move.start_x) + index_to_chess_number(move.start_y) + " to " +
  index_to_chessletter(move.end_x) + index_to_chess_number(move.end_y) #{move.killed_piece_x} #{move.killed_piece_y} #{move.piece_team} #{move.killed_piece_team}"
end

def turn_label_centent(board)
  "Turn: #{board.turn}, #{board.team_turn == 0 ? "White" : "Black"}"
end

def index_to_chessletter(i)
  ([] +("a".."z"))[i]
end

def index_to_chess_number(i)
  (i+1).to_s
end

def team_to_name(team)
  (team == 0 ? "White" : "Black")
end

class Board
  attr_accessor :squares, :message
  attr_reader :moves
  attr_accessor :turn

  # build grid
  def initialize()
    @squares = []
    @moves = []
    @message = ""
    @turn = 0

    while @squares.count < (SIZE_X * SIZE_Y)
      @squares << Square.new(self, squares.count.mod(SIZE_X), @squares.count.idiv(SIZE_X))
    end
  end

  def kill(x, y)
    puts "kill #{x} , #{y}"
    square(x, y).piece = nil
  end

  def clear_path?(current_square, new_square)
    if(current_square.y == new_square.y)
      (current_square.x.upto(new_square.x).drop(1).reverse.drop(1) + current_square.x.downto(new_square.x).drop(1).reverse.drop(1)).each do |x|
        return false unless square(x, current_square.y).piece.nil?
      end
    elsif(current_square.x == new_square.x)
      (current_square.y.upto(new_square.y).drop(1).reverse.drop(1) + current_square.y.downto(new_square.y).drop(1).reverse.drop(1)).each do |y|
        return false unless square(current_square.x, y).piece.nil?
      end
    else
      return true if (new_square.x - current_square.x).abs < 2
      return true if (new_square.y - current_square.y).abs < 2
      
      x_step = new_square.x - current_square.x > 0 ? 1 : -1
      y_step = new_square.y - current_square.y > 0 ? 1 : -1
      ((new_square.x - current_square.x).abs - 1).times do |step|
        puts "square #{square(current_square.x + x_step * (step + 1), current_square.y + y_step * (step + 1))}"
        return false if square(current_square.x + x_step * (step + 1), current_square.y + y_step * (step + 1)).piece
      end
    end
    true
  end

  def moving_into_check?(current_square, new_square)
    enemy_squares = @squares.select{|s| s.piece && s.piece.team != current_square.piece.team}
    if(!current_square.piece.may_move_into_protected_square?)
      enemy_squares.each do |enemy_square|
        if enemy_square.piece.tread?(enemy_square, new_square)
          @message = "#{enemy_square.piece} tread #{team_to_name(current_square.piece.team)} #{current_square.piece.class.to_s}moved into check"
          return true
        end
      end
    end
    enemy_squares.each do |enemy_square|
      return true if enemy_square.piece.tread?(enemy_square, king_square(current_square.piece.team))
    end

    false
  end

  def other_team_in_check?
    
    king_square(current_square.piece.team)
  end

  def team_turn
    turn.mod(2)
  end

  def not_team_turn
    (turn+1).mod(2)
  end

  def to_s
     "#{team_turn} #{squares.map{|s| "#{s.piece&.team}#{s.piece&.to_s} "}.each_slice(SIZE_X).to_a} #{in_check?(0)} #{in_check?(1)}"
  end

  def in_check?(team)
    enemy_squares = squares.select{|s| s.piece && s.piece.team != (team)}
    enemy_squares.each do |enemy_square|
      if enemy_square.piece.tread?(enemy_square, king_square(team))        
        return true
      end
    end
    
    false
  end

  private 
  def square(x, y)
    squares[SIZE_X * y + x]
  end

  def king_square(team)
    squares.select{|s| s.piece && s.piece.team == team && s.piece.class == King}.first
  end

  def will_this_move_lead_to_in_check_and_not_your_turn?(current_square, new_square)
    future_board = Board.new()
    future_board.squares.each_with_index do |square, index|
      square.piece = squares[index].piece&.dup
      future_board.turn = turn
    end
    c = future_board.square(current_square.x, current_square.y)
    n = future_board.square(new_square.x, new_square.y)

    c.move_piece_yolo(n)

    if future_board.in_check?(future_board.not_team_turn)
      @message = "Not a valid move, sorry );"
      return true
    end
    
    false
  end
end

class Move
  attr_accessor :piece, :killed_piece, :start_x, :start_y, :end_x, :end_y, :killed_piece_x, :killed_piece_y, :piece_team, :killed_piece_team
end


class BasePiece
  attr_reader :team, :board
  attr_accessor :move_count
  def initialize(team)
    @move_count = 0
    @team = team
  end

  def r
    @team == 0 ? 217 : 33
  end

  def g
    @team == 0 ? 217 : 33
  end

  def b
    @team == 0 ? 217 : 33
  end

  def tread?(current_square, new_square)
    valid_move?(current_square, new_square)
  end

  def valid_kill?(current_square, new_square)
    new_square.enemy?(team) && tread?(current_square, new_square)
  end

  def may_move_into_protected_square?
    true
  end
end

class King < BasePiece
  def to_s
    "K"
  end

  def valid_move?(current_square, new_square)
    ((current_square.x - new_square.x).abs < 2 and (current_square.y - new_square.y).abs < 2 ) || castle(current_square, new_square)
  end

  def may_move_into_protected_square?
    false
  end

  def castle(current_square, new_square)
    move_count == 0 && (current_square.x - new_square.x).abs == 2 && current_square.y == new_square.y
  end
end

class Pawn < BasePiece
  def to_s
    "P"
  end

  def valid_move?(current_square, new_square)
    return unless current_square.board.clear_path?(current_square, new_square)

    if(team == 0)
      (current_square.y + 1 == new_square.y and current_square.x == new_square.x) or
      (current_square.y + 2 == new_square.y and current_square.x == new_square.x and move_count == 0)
    elsif(team == 1)
      (current_square.y - 1 == new_square.y and current_square.x == new_square.x) or
      (current_square.y - 2 == new_square.y and current_square.x == new_square.x and move_count == 0)
    end
  end

  def tread?(current_square, new_square)
    if(team == 0)
      (current_square.x - new_square.x).abs == 1 and (current_square.y + 1 == new_square.y)
    elsif(team == 1)
      (current_square.x - new_square.x).abs == 1 and (current_square.y - 1 == new_square.y)
    end
  end

  def valid_kill?(current_square, new_square)
    tread?(current_square, new_square) and (new_square.enemy?(team) or in_passing?(current_square, new_square))
  end

  def in_passing?(current_square, new_square)
    board = current_square.board
    last_move = board.moves.last
    return unless board.moves.last.piece.to_s == Pawn.to_s

    if(last_move.end_y == current_square.y)
      if last_move.end_x == new_square.x
        if team == 0
          if(last_move.end_y - last_move.start_y == -2)
            board.kill(last_move.end_x, last_move.end_y)
            true
          end
        else
          if(last_move.end_y - last_move.start_y == 2)
            board.kill(last_move.end_x, last_move.end_y)
            true
          end    
        end
      end
    end
  end

end

class Square
  attr_accessor :piece
  attr_reader :x, :y, :board

  SPACING = 3

  def initialize(board, x, y)
    @board = board
    @x = x
    @y = y

    if(SIZE_Y > 3)
      if(@y == 1)
        @piece = Pawn.new(0)
      elsif @y == SIZE_Y - 2
        @piece = Pawn.new(1)
      end
    end

    if(@y == 0)
      @piece = Knight.new(0)
    end
    if(@y == SIZE_Y - 1)
      @piece = Knight.new(1)
    end


    if @x == SIZE_X.idiv(2) + 1 or @x == SIZE_X - SIZE_X.idiv(2) - 2
      if(@y == 0)
        @piece = Bishop.new(0)
      end
      if(@y == SIZE_Y - 1)
        @piece = Bishop.new(1)
      end
    end

    if @x == SIZE_X - 1 or @x == 0
      if(@y == 0)
        @piece = Rook.new(0)
      end
      if(@y == SIZE_Y - 1)
        @piece = Rook.new(1)
      end
    end

    if @x == SIZE_X/2 - 1
      if(@y == 0)
        @piece = Queen.new(0)
      end
      if(@y == SIZE_Y - 1)
        @piece = Queen.new(1)
      end
    end

    if @x == SIZE_X.idiv(2)
      if(@y == 0)
        @piece = King.new(0)
      end
      if(@y == SIZE_Y - 1)
        @piece = King.new(1)
      end
    end
  end

  def empty?
    @piece.nil?
  end

  def enemy?(team)
    return false if empty?
    team != @piece.team
  end

  def self.tile_size
    632/SIZE_Y
  end

  def move_piece(square)
    return unless board.team_turn == piece.team
    return unless (piece.valid_move?(self, square) && square.empty?) || piece.valid_kill?(self, square)
    return if board.will_this_move_lead_to_in_check_and_not_your_turn?(self, square)
    board.message = ""
    move_piece_yolo(square)
  end

  def move_piece_yolo(square)
    move = Move.new
    move.piece = piece.class
    move.piece_team = piece.team
    move.start_x = @x
    move.start_y = @y
    move.end_x = square.x
    move.end_y = square.y

    @board.moves << move
    square.piece = piece

    if piece.class == Pawn
      if piece.team == 1 and square.y == 0
        square.piece = Queen.new(1)
      end
      if piece.team == 0 and square.y == SIZE_Y - 1
        square.piece = Queen.new(0)
      end 
    end
    
    square.piece.move_count += 1 
    board.turn += 1

    @piece = nil
    true
  end

  def color
    if ((@x + @y) - SIZE_X).mod(2) == 0
      [110, 170, 105]
    else
      [247, 255, 247]
    end
  end

  def color_clicked
    if ((@x + @y) - SIZE_X).mod(2) == 0
      [255, 111, 63]
    else
      [255, 141, 93]
    end
  end

  def did_i_click_you?(x, y)
    @clicked = (x > x_begin && x < x_begin + Square.tile_size) && (y > y_begin && y < y_begin + Square.tile_size)
  end

  def render(outputs)
    outputs.solids << 
      [x_begin, y_begin , Square.tile_size, Square.tile_size, @clicked ? color_clicked[0] : color[0],  @clicked ? color_clicked[1] : color[1] , @clicked ? color_clicked[2] : color[2] ]
    if @piece
      outputs.labels << [x_begin + Square.tile_size*2/7 + 0 , y_begin + Square.tile_size*7/8 + 0, @piece.to_s,  (Square.tile_size - 28)/2, 0, @piece.r , @piece.g, @piece.b ]
    end
  end

  def x_begin
    @x*(Square.tile_size + SPACING)
  end

  def y_begin
    @y*(Square.tile_size + SPACING)
  end
end


class Rook < BasePiece
  def to_s
    "R"
  end

  def valid_move?(current_square, new_square)
    return unless current_square.board.clear_path?(current_square, new_square)

    current_square.x == new_square.x or current_square.y == new_square.y
  end
end

class Knight < BasePiece
  def to_s
    "N"
  end

  def valid_move?(current_square, new_square)
    (current_square.x + 2 == new_square.x and current_square.y + 1 == new_square.y) or
    (current_square.x + 2 == new_square.x and current_square.y - 1 == new_square.y) or
    (current_square.x - 2 == new_square.x and current_square.y + 1 == new_square.y) or
    (current_square.x - 2 == new_square.x and current_square.y - 1 == new_square.y) or
    (current_square.x + 1 == new_square.x and current_square.y + 2 == new_square.y) or
    (current_square.x + 1 == new_square.x and current_square.y - 2 == new_square.y) or
    (current_square.x - 1 == new_square.x and current_square.y + 2 == new_square.y) or
    (current_square.x - 1 == new_square.x and current_square.y - 2 == new_square.y)
  end
end

class Bishop < BasePiece
  def to_s
    "B"
  end

  def valid_move?(current_square, new_square)
    return unless current_square.board.clear_path?(current_square, new_square)

    (current_square.x - new_square.x == current_square.y - new_square.y) or
    (current_square.x + current_square.y == new_square.x + new_square.y)
  end
end

class Queen < BasePiece
  def to_s
    "Q"
  end

  def valid_move?(current_square, new_square)
    return unless current_square.board.clear_path?(current_square, new_square)

    current_square.x == new_square.x or current_square.y == new_square.y or
    (current_square.x - new_square.x == current_square.y - new_square.y) or
    (current_square.x + current_square.y == new_square.x + new_square.y)
  end
end