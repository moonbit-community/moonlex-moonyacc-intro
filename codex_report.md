# Dependency build failure

Repository: `moonlex-moonyacc-intro`

## What was run

- `moon check`
- `moon add moonbitlang/yacc`
- `moon add moonbitlang/ulex`

## Result

`moon check` fails while building binary dependencies, before checking this repository's own source.

The initial failure is from direct bin dependency `moonbitlang/yacc@0.7.5` and nested dependency `moonbitlang/x@0.4.37`.

Representative errors:

- `.mooncakes/moonbitlang/yacc/src/lib/util/hashmap2/hashmap2.mbt`: `Iter::new(fn(yield_) { ... })` is rejected because `Iter::new` now expects a zero-argument iterator function returning an optional value.
- `.mooncakes/moonbitlang/yacc/src/lib/util/hashmap2/hashmap2.mbt`: `IterContinue` and `IterEnd` are no longer valid constructors for the inferred optional iterator return type.
- `.mooncakes/moonbitlang/yacc/src/lib/util/small_int_set/small_int_set.mbt`: the same deprecated iterator API produces `Iter::new` and `IterEnd`/`IterContinue` errors.
- `.mooncakes/moonbitlang/yacc/.mooncakes/moonbitlang/x/internal/ffi/string_convert.mbt`: `UInt16` values are used where `Int` is expected, integer literal `0x10000` is out of range for the inferred type, and `String.charcode_at` is not available in newer dependency attempts.

`moon add moonbitlang/yacc` was attempted as requested. It downloaded newer cached dependency versions (`moonbitlang/yacc@0.7.13`, `moonbitlang/x@0.4.38`, etc.) but still failed during dependency build, at that point through `moonbitlang/ulex`.

`moon add moonbitlang/ulex` was also attempted because `moonbitlang/ulex` is a direct bin dependency. It downloaded `moonbitlang/ulex@0.3.27`, but dependency build still failed. The final failure again includes `moonbitlang/yacc` iterator API errors.

## Current dependency declarations

`moon.mod.json` still contains:

```json
{
  "name": "moonlex_moonyacc_intro",
  "deps": {},
  "bin-deps": {
    "moonbitlang/yacc": "0.7.5",
    "moonbitlang/ulex": "0.3.23"
  }
}
```

The `moon add` commands exited non-zero and did not leave version changes in `moon.mod.json`.

## Conclusion

This is a dependency compatibility failure involving `moonbitlang/yacc` and `moonbitlang/ulex` against the installed MoonBit toolchain. Per the requested workflow, current-repository warning/error fixes were not attempted after entering the dependency-error path.
