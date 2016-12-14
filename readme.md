# Poker AI

Poker AI is a Texas Hold'em poker tournament simulator which uses player strategies that "evolve" using a John Holland style [genetic algorithm](https://en.wikipedia.org/wiki/Genetic_algorithm).

![Poker AI](http://i.imgur.com/ZLqaPWF.png)

The user can configure a "Evolution Trial" of tournaments with up to 10 players, or simply play ad-hoc tournaments against the AI players.  Between tournaments,
the performance of each player's strategy is analyzed and classified according to a fitness function, the best of which are bred and supplied to the following
generation used in the subsequent tournament.  Over many generations, the strategies improve to become more likely to win.  State data is continuously logged to
an Oracle database for analysis.

Player strategies are represented as Python programs corresponding to a chromosome.  Manipulation of the chromosome (crossover and mutation) result in changes
to the Python program.  The program is called whenever it is that player's turn.

The Python program has access to various sets of data:

* Possible moves currently available given the current game state (fold, bet, raise)
* The player's private state information (hole cards)
* Public game state information (current round of play, last to raise, etc.)
* Public competitor player state information (how much money each player currently has, how many folds each player has made in previous rounds, how many games each player has won, etc.).

The program is responsible for returning what move the player should make and whatever money is involved (ex, raise 50).

For high quality data for analysis, evolution trials are typically very large.  As such, the program allows for multithreaded tournament play, and contribution to
evolution trial runs from an arbitrary number of machines.  Every move is logged, which provides the ability to load any historical state to observe the strategies in action.






