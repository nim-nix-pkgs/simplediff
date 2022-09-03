# simplediff

A [Nim](https://nim-lang.org) implementaion of a simple diff algorithm, based on [Paul Butler's `simplediff`](https://github.com/paulgb/simplediff).

## Usage

`simplediff` provides a `diff` proc which takes two `openArray`s and generates a `seq` of "instructions" to turn the first into the second. Each "instruction" is of the `Diff` type, which is either an `Insertion`, a `Deletion`, or a `NoChange`. Each `Diff` also has a `tokens` field, which contains a subsequence of elements that the insertion/deletion/leaving alone should be applied to. 

For example:

```
import simplediff

echo diff([1, 2, 3], [1, 2])
# @[Diff(kind: NoChange, tokens: @[1, 2]), Diff(kind: Deletion, tokens: @[3])]
```

Any type that implements the `==` operator can be used.

`simplediff` also provides a convenience wrapper for diffing two strings. By default, the strings are split into lines for diffing, but this can be changed with the `seps` parameter.

```
import simplediff

for diff in stringDiff("the word is blue", "the word is red", seps={' '}):
  echo diff
# Diff(kind: NoChange, tokens: @["the", "word", "is"])
# Diff(kind: Deletion, tokens: @["blue"])
# Diff(kind: Insertion, tokens: @["red"])
```

Other convenience wrappers may be added in the future! Feel free to request one or submit a patch.

`simplediff` also provides `prettyDiff`, which writes a formatted version of the diff to an output stream. It can be called directly or, if you need more flexibility than it offers, used as a starting point for building your own output.

See the `when isMainModule` block within `simplediff.nim` for an example of a simple diff application.

## Contributing

Contributions are welcome! Please send patches, questions, requests, etc. to my [public inbox](mailto:~reesmichael1/public-inbox@lists.sr.ht).
