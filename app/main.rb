TRUE_BLACK = { r: 0, g: 0, b: 0 }
WHITE = { r: 255, g: 255, b: 255 }

# Access in code with `SPATHS[:my_sprite]`
# Replace with your sprites!
SPATHS = {
  cursor: "sprites/cursor.png",
}

def debug?
  !$gtk.production
end

CONFIRM_KEYS = [:j, :z, :enter, :space]
def confirm?(inputs)
  inputs.controller_one.key_down&.a ||
    (CONFIRM_KEYS & inputs.keyboard.keys[:down]).any?
end

UP_KEYS = [:up, :w]
def up?(inputs)
  inputs.controller_one.key_down&.up ||
    (UP_KEYS & inputs.keyboard.keys[:down]).any?
end

DOWN_KEYS = [:down, :s]
def down?(inputs)
  inputs.controller_one.key_down&.down||
    (DOWN_KEYS & inputs.keyboard.keys[:down]).any?
end


module Scene
  TITLE = :title
  INTRO = :intro
  AUDIT = :audit
  OUTRO = :outro
end

def tick_title(args)
  args.outputs.labels << { x: 120, y: args.grid.h - 120, text: "XENO.TEST", size_enum: 4 }.merge(WHITE)
  args.outputs.labels << { x: 120, y: args.grid.h - 180, text: "Prove you're not human.", size_enum: 0 }.merge(WHITE)
  args.outputs.labels << { x: 120, y: 260, text: "Z or Enter to Confirm | WASD/arrow keys to change selection", size_enum: 2 }.merge(WHITE)
  args.outputs.labels << { x: 120, y: 120, text: "A game by Brett Chalupa", size_enum: 0 }.merge(WHITE)

  if confirm?(args.inputs)
    args.state.scene = Scene::INTRO
  end
end

INTRO_TEXT = [
  "> An officer stops you in the streets. Their Enforcer hovers at their side.",
  "OFFICER: I need you to come with me.",
  "> With no choice, you follow.",
  "> You arrive at the station. It's seen better days.",
  "> The officer and their Enforcer lead you to a white room.",
  "> All you see is a screen next to a camera with a keyboard beneath it.",
  "OFFICER: We've had reports of humans in the area.",
  "OFFICER: Step up to the terminal.",
  "OFFICER: The audit will only take 20 seconds.",
  "OFFICER: You have nothing to worry about.",
]
def tick_intro(args)
  args.state.intro.index ||= 0

  if confirm?(args.inputs)
    args.state.intro.index += 1
  end

  if (args.state.intro.index >= INTRO_TEXT.length)
    args.state.scene = Scene::AUDIT
  end

  args.outputs.labels << { x: 120, y: 180, text: INTRO_TEXT[args.state.intro.index], size_enum: 2 }.merge(WHITE)
end

OUTRO_TEXT = {
  pass: "OFFICER: Carry on.",
  fail: "> Before you even realize you've failed the test, the officer's Enforcer tazes you...",
}
def tick_outro(args)
  args.state.pass ||= args.state.audit.score > (args.state.audit.answered_questions.length.to_f * 0.66)

  text = if args.state.pass
           OUTRO_TEXT[:pass]
         else
           OUTRO_TEXT[:fail]
         end
  args.outputs.labels << { x: 120, y: 120, text: text, size_enum: 2 }.merge(WHITE)

  if confirm?(args.inputs)
    $gtk.reset
  end
end

def random_index(array)
  rand(array.length)
end

QUESTIONS = [
  { q: "Your best friend falls in love with your dog.", a_human: "End the friendship", a_xeno: "Give the dog to them" },
  { q: "You find $20.00 on the ground. You haven't eaten in 7 hours.", a_human: "Take it", a_xeno: "Eat it" },
  { q: "A bird steals your favorite pen.", a_human: "Cry", a_xeno: "Jump up, grab the bird, reclaim the pen" },
  # { q: "A man driving a vehicle with a bumper sticker that says \"How's my driving? Call 1-800-FUCK-OFF\" cuts you off in traffic.", a_human: "Flip the bird", a_xeno: "Call the number" },
  { q: "A song you hate comes on the radio.", a_human: "Begrudgingly listen to it", a_xeno: "Destroy the radio" },
  { q: "Your spouse tells you they're in love with your best friend.", a_human: "Deeply contemplate polygamy", a_xeno: "Explode, literally" },
  { q: "Your roommate left 3 chips at the bottom of the bag.", a_human: "Buy a new bag", a_xeno: "Move" },
]
AUDIT_TITLE_BASE = "Audit in progress"
def tick_audit(args)
  state = args.state
  state.audit.count_down ||= 20 * 60
  state.audit.answered_questions ||= []
  state.audit.score ||= 0
  state.audit.title ||= AUDIT_TITLE_BASE + "."
  state.audit.current_question_index ||= rand(QUESTIONS.length)
  state.audit.current_answer_index ||= 0

  if (args.tick_count % 22 == 0)
    state.audit.title = AUDIT_TITLE_BASE + ("." * ((args.tick_count % 3) + 1))
  end

  args.outputs.labels << { x: 120, y: 600, text: state.audit.title }.merge(WHITE)

  args.outputs.labels << { x: 120, y: 540, text: "Time remaining: #{state.audit.count_down.idiv(60)}" }.merge(WHITE)

  question = QUESTIONS[state.audit.current_question_index]

  args.outputs.labels << args.string.wrapped_lines(question[:q], 60).map_with_index do |s, i|
    { x: 120, y: 400 - (i * 32), text: s, size_enum: 4, alignment: 0 }.merge(WHITE)
  end

  state.audit.current_answers ||= [
    { x: 120, text: question[:a_human], size: 0, alignment: 0 }.merge(WHITE),
    { x: 120, text: question[:a_xeno], size: 0, alignment: 0 }.merge(WHITE),
  ].sort_by { rand }.map.with_index do |a, i|
    a[:y] = 240 - (i * 40)
    a
  end
  args.outputs.labels << state.audit.current_answers

  state.audit.count_down -= 1

  if state.audit.count_down < 0
    state.scene = Scene::OUTRO
    return
  end

  if confirm?(args.inputs)
    if state.audit.current_answers[state.audit.current_answer_index][:text] == question[:a_xeno]
      state.audit.score += 1
    end
    state.audit.answered_questions << state.audit.current_question_index
    @i = rand(QUESTIONS.length)
    puts state.audit.answered_questions.to_a
    puts state.audit.answered_questions.include?(@i)
    while state.audit.answered_questions.include?(@i) && state.audit.answered_questions.length < QUESTIONS.length
      @i = rand(QUESTIONS.length)
    end
    state.audit.current_question_index = @i
    state.audit.current_answer_index = 0
    state.audit.current_answers = nil
    return
  end

  if up?(args.inputs)
    state.audit.current_answer_index -= 1
    if state.audit.current_answer_index < 0
      state.audit.current_answer_index = state.audit.current_answers.length - 1
    end
  elsif down?(args.inputs)
    state.audit.current_answer_index += 1
    if state.audit.current_answer_index > state.audit.current_answers.length - 1
      state.audit.current_answer_index = 0
    end
  end

  active_answer = state.audit.current_answers[state.audit.current_answer_index]
  args.outputs.sprites << { x: active_answer[:x] - 32, y: active_answer[:y] - 16, w: 16, h: 16, path: SPATHS[:cursor] }
end

def tick(args)
  args.outputs.background_color = TRUE_BLACK.values
  args.state.scene ||= Scene::TITLE

  send("tick_#{args.state.scene}", args)

  debug_tick(args)
end

def debug_tick(args)
  return unless debug?

  args.outputs.debug << [args.grid.w - 12, args.grid.h, "#{args.gtk.current_framerate.round}", 0, 1, *WHITE.values].label

  if args.inputs.keyboard.key_down.i
    SPATHS.each { |_, v| args.gtk.reset_sprite(v) }
    args.gtk.notify!("Sprites reloaded")
  end

  if args.inputs.keyboard.key_down.r
    $gtk.reset
  end
end
