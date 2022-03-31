#  Another Wordle Clone

A clone of the popular game [Wordle](https://www.nytimes.com/games/wordle/index.html) for iOS in Swift and SwiftUI.

This project was intended only as an exercise to learn Swift and SwiftUI alongside the first half of the [CS193p course](https://cs193p.sites.stanford.edu/).

## Features

* Correct implementation of letter colouring, including when multiple instances of the same letter are in the guess word or in the target word
* Hard mode
* Similar (but not exactly identical) animations, including alert pill when an invalid submission is attempted
* ~Original wordle dictionary, with only "guessable" words included as the target~

### Differences

* Only a single alert is shown at one time. If multiple invalid submission attempts are made in quick succession, the alert will only show for the most recent attempt
* Slightly different keyboard layout
* Slight differences in animation style
