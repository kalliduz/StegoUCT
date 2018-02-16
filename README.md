# StegoUCT
Simple Go Engine using MonteCarlo and UCT written in Delphi. GTP compatible. AI Heuristics planned

What is MonteCarlo?
-------------------

MonteCarlo is a stochastic approach of approximating ratios or similar by random distribution of all possibilities.
For games like go, this means, playing out a game from a certain position by choosing random moves.
The higher the playouts done, the more accurate is the win/loss-ratio for the current position.
Ofcourse, pure MonteCarlo introduces a lot of biases, like not caring for very important moves, that are "easy" to see,
therefore you don't see the MonteCarlo approach on very tactic sided games. 
But since Go deals with a big amount of possible moves, that follow very simple rules, there is a big potential to randomize moves
without missing too much critical moves.
Pure MonteCarlo would be very lousy though even for Go, that's why the moves chosen for the playouts are not completely random,
but follow some simple heuristics/policies, that influences the probability of that move being played.

What is UCT?
------------

UCT stands for "Upper Confidence Tree".
It defines a balance between recursive minimax strategy and montecarlo winratio refinement.
It is represented by the following formula:

**(wi/ni) + c*sqrt(ln(Ni)/ni)** 

where 

 * **wi** number of wins for the node considered after the i-th move <br> 
 * **ni** number of simulations for the node after the i-th move <br>
 * **Ni** number of total simulations after i-th move <br> 
 * **c**  exploration parameter <br> 
 * **ln** the logarithmus naturalis function <br>
 
 (wi/ni) is the winrate of the node, let's call it the exploitation factor
 c*sqr(ln(Ni)/ni) is a part that grows, when the number of simulations on this node is small, we call it the exploration factor
 
 So by finding a good c, you try to maintain the balance between going deep into important branches on the movetree and determining
 what actually is important to exploit.
 
 
 The current state of this projects implements both of these strategies.
 It has an estimated rank of 3kyu to 1dan, based on ManyFacesOfGo rating) on 9x9 board when playing with 10 seconds per move.
 On 19x19 it can still be considered a beginner player, even when giving around 2 minutes per move, it only achives around
 15kyu to 20kyu playing strength. This is mostly because of a missing implementation of a good AMAF algorithm (see https://github.com/kalliduz/StegoUCT/issues/2 for reference)
 
 
 
 
