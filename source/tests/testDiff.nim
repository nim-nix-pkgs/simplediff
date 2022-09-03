import streams
import strutils
import unittest

import simplediff


suite "test bare diff":
  # These tests are from the doctests in simplediff's Python implementation
  test "bare diff on ints with equal start":
    check diff(@[1, 2, 3, 4], @[1, 3, 4]) == [
      Diff[int](kind: NoChange, tokens: @[1]),
      Diff[int](kind: Deletion, tokens: @[2]),
      Diff[int](kind: NoChange, tokens: @[3, 4])
      ]

  test "bare diff on ints with deletion at start":
    check diff(@[1, 2, 3, 4], @[2, 3, 4, 1]) == [
      Diff[int](kind: Deletion, tokens: @[1]),
      Diff[int](kind: NoChange, tokens: @[2, 3, 4]),
      Diff[int](kind: Insertion, tokens: @[1])
      ]

  test "bare diff on strings with words for tokens":
    check diff(split("The quick brown fox jumps over the lazy dog"),
      split("The slow blue cheese drips over the lazy carrot")) == [
        Diff[string](kind: NoChange, tokens: @["The"]),
        Diff[string](kind: Deletion, tokens: @["quick", "brown", "fox",
            "jumps"]),
        Diff[string](kind: Insertion, tokens: @["slow", "blue", "cheese",
            "drips"]),
        Diff[string](kind: NoChange, tokens: @["over", "the", "lazy"]),
        Diff[string](kind: Deletion, tokens: @["dog"]),
        Diff[string](kind: Insertion, tokens: @["carrot"]),
      ]


suite "test stringDiff":
  test "correct diff for identical one-line strings":
    check stringDiff("abc", "abc") == [
      Diff[string](kind: NoChange, tokens: @["abc"])
      ]

  test "correct diff for identical multi-line strings":
    check stringDiff("abc def\n123 456", "abc def\n123 456") == [
      Diff[string](kind: NoChange, tokens: @["abc def", "123 456"])
      ]

  test "correct diff for different one-line strings":
    check stringDiff("abc", "def") == [
      Diff[string](kind: Deletion, tokens: @["abc"]),
      Diff[string](kind: Insertion, tokens: @["def"])
      ]

  test "correct diff for different multi-line strings":
    check stringDiff("abc\ndef", "abc 123\ndef") == [
      Diff[string](kind: Deletion, tokens: @["abc"]),
      Diff[string](kind: Insertion, tokens: @["abc 123"]),
      Diff[string](kind: NoChange, tokens: @["def"])
      ]

  test "correct diff when splitting on a different character":
    check stringDiff("abc;def", "abc 123;def", seps = {';'}) == [
      Diff[string](kind: Deletion, tokens: @["abc"]),
      Diff[string](kind: Insertion, tokens: @["abc 123"]),
      Diff[string](kind: NoChange, tokens: @["def"])
      ]

  test "correct diff when splitting on multiple characters":
    check stringDiff("abc;def,123", "abc;fed;abc", seps = {';', ','}) == [
      Diff[string](kind: NoChange, tokens: @["abc"]),
      Diff[string](kind: Deletion, tokens: @["def", "123"]),
      Diff[string](kind: Insertion, tokens: @["fed", "abc"])
      ]


suite "test prettyDiff":
  var output: Stream
  setup:
    output = newStringStream()

  test "correct output on unchanged strings":
    prettyDiff(["hello"], ["hello"], outStream = output)
    output.setPosition(0)
    check output.readAll() == ""

  test "correct output on deletion":
    prettyDiff(["hello", "world"], ["hello"], outStream = output)
    output.setPosition(0)
    check output.readAll() == " 2 ---- world\n"

  test "correct output on insertion":
    prettyDiff(["hello"], ["hello", "world"], outStream = output)
    output.setPosition(0)
    check output.readAll() == " 1 ++++ world\n"

  test "correct output on insertion, deletion, and unchanged":
    prettyDiff(["same", "deletion"], ["insertion", "same", ],
        outStream = output)
    output.setPosition(0)
    check output.readAll() == " 1 ++++ insertion\n 2 ---- deletion\n"

  test "correct output on non-string tokens":
    prettyDiff([1, 2], [3, 1], outStream = output)
    output.setPosition(0)
    check output.readAll() == " 1 ++++ 3\n 2 ---- 2\n"
