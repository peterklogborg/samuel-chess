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

  args.state.turn ||= 0
  args.outputs.labels << [100, (SIZE_Y * (Square::TILE_SIZE + Square::SPACING)) + 18, turn_label_centent(args.state.turn), -2, 0, 0, 0, 0]

  # render grid
  args.state.squares.each do |square|
    click = args.state.last_mouse_click
    if square.did_i_click_you?(click.point.x, click.point.y)
      if square.piece
        args.state.selected_square = square
      elsif(args.state.selected_square.move_piece(square, args.state.turn))
        args.state.turn += 1
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

def turn_label_centent(turn)
  "Turn: #{turn}, #{turn.mod(2) == 0 ? "White" : "Black"}"
end

class King
  attr_reader :team
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

  def move_piece(square, turn)
    return unless turn.mod(2) == piece.team
    return unless piece.valid_move?(self, square)
    
    square.piece = piece
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
    @clicked = (x > x_begin && x < x_begin + TILE_SIZE) && (y > y_begin && y < y_begin + TILE_SIZE)
  end

  def render(outputs)
    outputs.solids << 
      [x_begin, y_begin , TILE_SIZE, TILE_SIZE, @clicked ? color_clicked[0] : color[0],  @clicked ? color_clicked[1] : color[1] , @clicked ? color_clicked[2] : color[2] ]
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
