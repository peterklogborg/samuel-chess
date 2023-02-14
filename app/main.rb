SIZE_X = 8
SIZE_Y = 7

def tick args
  
  args.state.board ||= Board.new(args)
  if args.inputs.mouse.click
    args.state.last_mouse_click = args.inputs.mouse.click
  end

  args.state.turn ||= 0
  args.outputs.labels << [100, (SIZE_Y * (Square::tile_size + Square::SPACING)) + 18, turn_label_centent(args.state.turn), -2, 0, 0, 0, 0]

  # render grid
  args.state.board.squares.each do |square|
    click = args.state.last_mouse_click
    if square.did_i_click_you?(click.point.x, click.point.y)
      if(args.state.selected_square&.move_piece(square, args.state.turn))
        args.state.turn += 1
        args.state.selected_square = nil
      elsif square.piece
        args.state.selected_square = square
      else
        args.state.selected_square = nil  
      end
    end
  end
  
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

def turn_label_centent(turn)
  "Turn: #{turn}, #{turn.mod(2) == 0 ? "White" : "Black"}"
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
  attr_accessor :squares, :moves

  # build grid
  def initialize(args)
    @squares = []
    @moves = []

    while @squares.count < (SIZE_X * SIZE_Y)
      @squares << Square.new(self, squares.count.mod(SIZE_X), @squares.count.idiv(SIZE_X))
    end
  end

  def kill(x, y)
    puts "kill #{x} , #{y}"
    @squares[SIZE_X * y + x].piece = nil
  end
end

class Move
  attr_accessor :piece, :killed_piece, :start_x, :start_y, :end_x, :end_y, :killed_piece_x, :killed_piece_y, :piece_team, :killed_piece_team
end


class BasePiece
  attr_reader :team, :board
  attr_accessor :move_count
  def initialize(board, team)
    @move_count = 0
    @team = team
    @board = board
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

  def valid_kill?(current_square, new_square)
    new_square.enemy?(team) && valid_move?(current_square, new_square)
  end

  def self.to_s
    "|#{self.class}|"
  end
end

class King < BasePiece
  def to_s
    "K"
  end

  def valid_move?(current_square, new_square)
    (current_square.x - new_square.x).abs < 2 and (current_square.y - new_square.y).abs < 2 
  end
end

class Pawn < BasePiece
  def to_s
    "P"
  end

  def valid_move?(current_square, new_square)
    if(team == 0)
      (current_square.y + 1 == new_square.y and current_square.x == new_square.x) or
      (current_square.y + 2 == new_square.y and current_square.x == new_square.x and move_count == 0)
    elsif(team == 1)
      (current_square.y - 1 == new_square.y and current_square.x == new_square.x) or
      (current_square.y - 2 == new_square.y and current_square.x == new_square.x and move_count == 0)
    end
  end

  def valid_kill?(current_square, new_square)
    if(team == 0)
      (current_square.x - new_square.x).abs == 1 and (current_square.y + 1 == new_square.y) and (new_square.enemy?(team) or in_passing?(current_square, new_square))
    elsif(team == 1)
      (current_square.x - new_square.x).abs == 1 and (current_square.y - 1 == new_square.y) and (new_square.enemy?(team) or in_passing?(current_square, new_square))
    end
  end

  def in_passing?(current_square, new_square)
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
  attr_reader :x, :y

  SPACING = 3
  def initialize(board, x, y)
    @board = board
    @x = x
    @y = y

    if @x == SIZE_X.idiv(2)
      if(@y == 0)
        @piece = King.new(board, 0)
      end
      if(@y == SIZE_Y - 1)
        @piece = King.new(board, 1)
      end
    end

    if(@y == 1)
      @piece = Pawn.new(board, 0)
    elsif @y == SIZE_Y - 2
      @piece = Pawn.new(board, 1)
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

  def move_piece(square, turn)
    return unless turn.mod(2) == piece.team
    return unless (piece.valid_move?(self, square) && square.empty?) || piece.valid_kill?(self, square)
    
    move = Move.new
    move.piece = piece.class
    move.piece_team = piece.team
    move.start_x = @x
    move.start_y = @y
    move.end_x = square.x
    move.end_y = square.y
    
    # :killed_piece, :killed_piece_x, :killed_piece_y, :killed_piece_team

    @board.moves << move
    square.piece = piece
    
    square.piece.move_count += 1 
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

class Numeric
  Alph = ("a".."z").to_a
  def alph
    s, q = "", self
    (q, r = (q - 1).divmod(26)); s.prepend(Alph[r]) until q.zero?
    s
  end
end