///|
fn calc(input : String) -> Int raise {
  let tokens = @lexer.tokenize(input)
  @parser.start(tokens, initial_pos=0)
}

///|
test "example" {
  inspect(calc("3 + 2 - 5"), content="0")
  inspect(calc("3 + 2 - 5 * 0"), content="5")
  inspect(calc("3 + (2 - 5) * 0"), content="3")
}
