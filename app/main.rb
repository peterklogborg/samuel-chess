SIZE_X = 8
SIZE_Y = 8

def tick args
  
  # build grid
  args.state.squares ||= []
  if args.state.tick_count.idiv(2) > args.state.squares.count && args.state.squares.count < (SIZE_X * SIZE_Y)
    args.state.squares << Square.new(args.state.squares.count.mod(SIZE_X),args.state.squares.count.idiv(SIZE_Y))
  end
  
  if args.inputs.mouse.click
    args.state.last_mouse_click = args.inputs.mouse.click
  end

  # render grid
  args.state.squares.each do |square|
    click = args.state.last_mouse_click
    if square.did_i_click_you?(click.point.x, click.point.y)
      if square.piece
        args.state.selected_square = square
      elsif(args.state.selected_square.move_piece(square))
        args.state.selected_square = nil
      else
        args.state.selected_square = nil  
      end
    end
  end
  
  if args.inputs.keyboard.key_held.shift
    args.outputs.labels << [100, 68, "D? #{args.state.squares.count}?", -2, 0, 0, 0, 0]
  end

  # render grid
  args.state.squares.each do |squares|
    squares.render(args.outputs )
  end
end

class King
  def initialize(team)
    @team = team
  end

  def to_s
    "K"
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

  def valid_move?(current_square, new_square)
    (current_square.x - new_square.x).abs < 2 and (current_square.y - new_square.y).abs < 2 
  end
end

class Square
  attr_accessor :piece
  attr_reader :x, :y
  TILE_SIZE = 79
  SPACING = 3
  def initialize(x, y)
    @x = x
    @y = y

    if @x == SIZE_X/2
      if(@y == 0)
        @piece = King.new(0)
      end
      if(@y == SIZE_Y - 1)
        @piece = King.new(1)
      end
    end
  end

  def move_piece(square)
    return unless piece.valid_move?(self, square)
    
    square.piece = piece
    @piece = nil        
  end

  def color
    ((@x + @y) - SIZE_X).mod(2)*255
  end

  def did_i_click_you?(x, y)
    @clicked = (x > x_begin && x < x_begin + TILE_SIZE) && (y > y_begin && y < y_begin + TILE_SIZE)
  end

  def render(outputs)
    outputs.solids << 
      [x_begin, y_begin , TILE_SIZE, TILE_SIZE, color, @clicked ? 127 : color, color ]
    if @piece
      outputs.labels << [x_begin + TILE_SIZE*2/7 + 0 , y_begin + TILE_SIZE*7/8 + 0, @piece.to_s,  (TILE_SIZE - 28)/2, 0, @piece.r , @piece.g, @piece.b ]
    end
  end

  def x_begin
    @x*(TILE_SIZE + SPACING)
  end

  def y_begin
    @y*(TILE_SIZE + SPACING)
  end
end
