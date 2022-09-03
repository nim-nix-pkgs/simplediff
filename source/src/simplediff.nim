## A simple diff algorithm for Nim.

import math
import streams
import strutils
import tables


type
  ChangeType* = enum
    Insertion, Deletion, NoChange

  Diff*[T] = object
    kind*: ChangeType
    tokens*: seq[T]


proc diff*[T](itemsOld, itemsNew: openArray[T]): seq[Diff[T]] =
  ## Find the differences between two `itemsOld` and `itemsNew`.
  ## Each entry of the returned seq is an instruction describing the
  ## shortest method of changing `itemsOld` into `itemsNew`.
  ##
  ## A `Diff` of kind `Insertion` means that a set of tokens were inserted
  ## into `itemsOld`, `Deletion` means that a set of tokens were removed,
  ## and `NoChange` means that the subsequence of tokens is identical.
  var oldIndexMap: Table[T, seq[int]]
  for ix, item in itemsOld:
    if item in oldIndexMap:
      oldIndexMap[item].add(ix)
    else:
      oldIndexMap[item] = @[ix]

  var overlap: Table[int, int]
  var subStartOld = 0
  var subStartNew = 0
  var subLength = 0

  # Iterate over each value in the new list. At each iteration,
  # overlap[ix] is the length of the largest suffix of itemsOld[:ix]
  # equal to a suffix of itemsNew[:ixNew].
  #
  # subLength, subStartOld, and subStartNew keep track
  # of the largest substring of the overlapping strings.
  for ixNew, value in itemsNew:
    var overlapTemp: Table[int, int]
    for ixOld in oldIndexMap.getOrDefault(value):
      var newSuffixLen = 1
      if ixOld > 0 and overlap.getOrDefault(ixOld - 1, 0) > 0:
        newSuffixLen = overlap.getOrDefault(ixOld - 1, 0) + 1
      overlapTemp[ixOld] = newSuffixLen
      if overlapTemp[ixOld] > subLength:
        subLength = overlapTemp[ixOld]
        subStartOld = ixOld - subLength + 1
        subStartNew = ixNew - subLength + 1

    overlap = overlapTemp

  if subLength == 0:
    # If there is no common substring, return an insertion and a deletion
    if itemsOld.len > 0:
      result.add(Diff[T](kind: Deletion, tokens: @itemsOld))
    if itemsNew.len > 0:
      result.add(Diff[T](kind: Insertion, tokens: @itemsNew))

  else:
    # Otherwise, the common substring is left alone and we can find the diff
    # of the elements before and after it.
    let diffBefore = diff(itemsOld[0..<subStartOld], itemsNew[0..<subStartNew])
    let same = itemsNew[subStartNew..<subStartNew+subLength]
    let unchanged = Diff[T](kind: NoChange, tokens: same)
    let diffAfter = diff(itemsOld[subStartOld+subLength..<itemsOld.len],
      itemsNew[subStartNew+subLength..<itemsNew.len])

    return diffBefore & unchanged & diffAfter


proc stringDiff*(s1, s2: string, seps: set[char] = Newlines): seq[Diff[string]] =
  ## Return the difference between `s1` and `s2` on a line-by-line basis.
  ## Each entry of the returned seq is an instruction describing the
  ## shortest method of changing `s1` into `s2`.
  ##
  ## See the documentation for `diff` for an explanation of the result.
  return diff(split(s1, seps = seps), split(s2, seps = seps))


proc prettyDiff*[T](itemsOld, itemsNew: openArray[T],
    outStream: Stream = newFileStream(stdout), insertionPrefix = "++++",
        deletionPrefix = "----") =
  ## Calculate the diff of `itemsOld` and `itemsNew`
  ## and write it to `outStream`.
  ## `insertionPrefix` is prepended to lines that were inserted,
  ## and `deletionPrefix` is prepended to lines that were deleted.
  let diffed = diff(itemsOld, itemsNew)
  var lineCounter = 1

  let linePadding = int(floor(log10(float(itemsOld.len)))) + 2
  proc formatLineCount(count: int): string =
    align($lineCounter, linePadding) & " "

  for ix, entry in diffed:
    case entry.kind
    of NoChange:
      for line in entry.tokens:
        lineCounter += 1
    of Insertion:
      if lineCounter != 1:
        lineCounter -= 1
      for line in entry.tokens:
        outStream.writeLine(formatLineCount(lineCounter) &
            insertionPrefix & " " & $line)
      # Don't increment the lines when inserting at the beginning
      # because we were adding at the zeroth line
      if lineCounter != 1:
        lineCounter += 1
    of Deletion:
      for line in entry.tokens:
        outStream.writeLine(formatLineCount(lineCounter) &
            deletionPrefix & " " & $line)
        lineCounter += 1


when isMainModule:
  import parseopt
  import terminal

  var p = initOptParser()
  var oldFile, newFile: string
  var argsSeen = 0
  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      stdout.write "unrecognized option: " & p.key & "\n"
      quit(1)
    of cmdArgument:
      if argsSeen == 0:
        oldFile = p.key
        argsSeen += 1
      elif argsSeen == 1:
        newFile = p.key
        argsSeen += 1
      else:
        argsSeen += 1

  if argsSeen != 2:
    stdout.write "usage: simplediff [old] [new]\n"
    quit(1)

  let diffed = stringDiff(readFile(oldFile), readFile(newFile))

  for entry in diffed:
    case entry.kind
    of NoChange: discard
    of Insertion:
      for line in entry.tokens:
        setForegroundColor(fgGreen)
        writeStyled("++++ " & line & "\n", {styleBright})
        setForegroundColor(fgDefault)
    of Deletion:
      for line in entry.tokens:
        setForegroundColor(fgRed)
        writeStyled("---- " & line & "\n", {styleBright})
        setForegroundColor(fgDefault)
