///|
using @parser {type Token}

///|
using @lexbuf {type StringLexbuf}

///|
priv suberror EndOfInput

///|
pub suberror Unrecognized (Int, Char)

///|
fn lex_token(lexbuf : StringLexbuf) -> (Token, Int, Int) raise {
  // The matched pattern id
  let mut _match_pattern = @int.max_value
  let mut _match_start = lexbuf.curr_pos()
  let mut _match_end = -1
  let mut _capture_0_start = -1
  let mut _capture_0_end = -1
  let mut _capture_1_start = -1
  let mut _capture_1_end = -1
  loop 0 {
    0 =>
      continue match lexbuf.next_as_int() {
          -1 => 1
          0..=8 => 2
          9 => 3
          10..=31 => 2
          32 => 3
          33..=39 => 2
          40 => 4
          41 => 5
          42 => 6
          43 => 7
          44 => 2
          45 => 8
          46..=47 => 2
          48..=57 => 9
          58..=1114111 => 2
          _ => break
        }
    1 => {
      _match_pattern = 0
      _match_end = lexbuf.curr_pos()
      break
    }
    2 => {
      _match_pattern = 8
      _match_end = lexbuf.curr_pos()
      _capture_0_start = _match_start
      _capture_0_end = _match_start + 1
      break
    }
    3 => {
      _match_pattern = 1
      _match_end = lexbuf.curr_pos()
      continue match lexbuf.next_as_int() {
          9 => 3
          32 => 3
          _ => break
        }
    }
    4 => {
      _match_pattern = 6
      _match_end = lexbuf.curr_pos()
      break
    }
    5 => {
      _match_pattern = 7
      _match_end = lexbuf.curr_pos()
      break
    }
    6 => {
      _match_pattern = 5
      _match_end = lexbuf.curr_pos()
      break
    }
    7 => {
      _match_pattern = 3
      _match_end = lexbuf.curr_pos()
      break
    }
    8 => {
      _match_pattern = 4
      _match_end = lexbuf.curr_pos()
      break
    }
    9 => {
      _match_pattern = 2
      _match_end = lexbuf.curr_pos()
      _capture_0_start = _match_start
      _capture_0_end = _match_end
      continue match lexbuf.next_as_int() {
          48..=57 => 9
          _ => break
        }
    }
    _ => panic()
  }
  guard _match_pattern <= 8 else {
    // No pattern matched
    panic()
  }
  lexbuf.reset(pos=_match_end)
  match _match_pattern {
    0 => {
      ()
      raise EndOfInput
    }
    1 => {
      ()
      lex_token(lexbuf)
    }
    2 => {
      ()
      let t = lexbuf.get_string(_capture_0_start, _capture_0_end)
      (NUMBER(try! @strconv.parse_int(t)), _match_start, _match_end)
    }
    3 => {
      ()
      (PLUS, _match_start, _match_end)
    }
    4 => {
      ()
      (MINUS, _match_start, _match_end)
    }
    5 => {
      ()
      (STAR, _match_start, _match_end)
    }
    6 => {
      ()
      (LPAREN, _match_start, _match_end)
    }
    7 => {
      ()
      (RPAREN, _match_start, _match_end)
    }
    8 => {
      ()
      let c = lexbuf.get_char(_capture_0_start, _capture_0_end)
      raise Unrecognized((_match_start, c))
    }
    _ => panic()
  }
}

///|
pub fn tokenize(input : String) -> Array[(Token, Int, Int)] raise Unrecognized {
  let lexbuf = StringLexbuf::from_string(input)
  let tokens = []
  for {
    let token = lex_token(lexbuf) catch {
      EndOfInput => break
      Unrecognized(_) as err => raise err
      _ => panic()
    }
    tokens.push(token)
  }
  tokens
}
