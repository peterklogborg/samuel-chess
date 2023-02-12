SIZE_X = 8
SIZE_Y = 8

def tick args

  # build grid
  args.state.squares ||= []
  if args.state.tick_count.idiv(4) > args.state.squares.count && args.state.squares.count < (SIZE_X * SIZE_Y)
    args.state.squares << Square.new(args.state.squares.count.mod(SIZE_X),args.state.squares.count.idiv(SIZE_Y))
  end
  
  # render grid
  args.state.squares.each do |squares|
    click = args.state.last_mouse_click
    squares.clicked(squares.did_i_click_you?(click.point.x, click.point.y))
  end


  tick_instructions args, "Sample app shows how mouse events are registered and how to measure elapsed time."
  x = 660

  args.outputs.labels << small_label(args, x, 11, "Mouse input: args.inputs.mouse")

  if args.inputs.mouse.click
    args.state.last_mouse_click = args.inputs.mouse.click
  end

  if args.state.last_mouse_click
    click = args.state.last_mouse_click
    args.outputs.labels << small_label(args, x, 12, "Mouse click happened at: #{click.created_at}")

    args.outputs.labels << small_label(args, x, 14, "Mouse click location: #{click.point.x}, #{click.point.y}")
  else
    args.outputs.labels << small_label(args, x, 12, "Mouse click has not occurred yet.")
    args.outputs.labels << small_label(args, x, 13, "Please click mouse.")
  end

  
  if args.inputs.keyboard.key_held.shift
    args.outputs.labels << [100, 68, "D? #{args.state.squares.first.inspect}?", -2, 0, 0, 0, 0]
  end

  # render grid
  args.state.squares.each do |squares|
    squares.render(args.outputs.solids )
  end
end

class Square
  TILE_SIZE = 79
  SPACING = 3
  def initialize(x, y)
    @x = x
    @y = y
  end

  def color
    ((@x + @y) - SIZE_X).mod(2)*255
  end

  def did_i_click_you?(x, y)
    (x > @x*(TILE_SIZE + SPACING) && x < @x*(TILE_SIZE + SPACING) + TILE_SIZE) && (y > @y*(TILE_SIZE + SPACING) && y < @y*(TILE_SIZE + SPACING) + TILE_SIZE)
  end

  def clicked(b)
    @clicked = b
  end

  def render(solids)
    solids << [
      [@x*(TILE_SIZE + SPACING), @y*(TILE_SIZE + SPACING), TILE_SIZE, TILE_SIZE, color, @clicked ? 127 : color, color ]
    ]
  end

  def serialize
    { }
  end
end

def small_label args, x, row, message
  # This method effectively combines the row_to_px and small_font methods
  # It changes the given row value to a DragonRuby pixel value
  # and adds the customization parameters
  { x: x, y: row_to_px(args, row), text: message, alignment_enum: -2 }
end

def row_to_px args, row_number
  args.grid.top.shift_down(5).shift_down(20 * row_number)
end

def tick_instructions args, text, y = 715
  return if args.state.key_event_occurred
  if args.inputs.mouse.click ||
     args.inputs.keyboard.directional_vector ||
     args.inputs.keyboard.key_down.enter ||
     args.inputs.keyboard.key_down.escape
    args.state.key_event_occurred = true
  end

  args.outputs.debug << { x: 0,   y: y - 50, w: 1280, h: 60 }.solid!
  args.outputs.debug << { x: 640, y: y, text: text, size_enum: 1, alignment_enum: 1, r: 255, g: 255, b: 255 }.label!
  args.outputs.debug << { x: 640, y: y - 25, text: "(click to dismiss instructions)", size_enum: -2, alignment_enum: 1, r: 255, g: 255, b: 255 }.label!
end
