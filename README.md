# StegoUCT
Simple Go Engine using MonteCarlo,UCT and AMAF/RAVE written in Delphi. GTP compatible. AI Heuristics planned

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
It defines a tree using the balance between recursive minimax strategy and montecarlo winratio refinement.
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
 
 What is AMAF/RAVE?
-------------------
**AMAF** ("All moves as first") <br>
AMAF means sharing the knowledge about the value of a move X,Y in an arbitrary position with all
other moves (X,Y) in the UCT for that player.
So in basic AMAF, we would just update the wins/losses for every other node, that played the same move in another position.

This seems to be pretty biased, since the move is normally clearly context dependant, but it seems if the distribution is near to random, it provides good initial knowledge to get confidence for exploring a move.

**α-AMAF** <br>
If we want to change the node value weight of the AMAF estimation, we need to track AMAF wins and losses separately in the node,
so we can compute its own value first, and then add it partially (by a factor α) to the normal UCT value.
This is then called α-AMAF

**RAVE** (Rapid action value estimation) <br>
RAVE is basically α-AMAF, but with lowering α-factor for increasing normal playouts on that node.
This means we basically "warm up" the tree by rapidly gathering AMAF knowledge, and as the unbiased UCT knowledge grows, we slowly lower the α until its completely gone.<br>

So lets say:<br>
**R** ... Rave warmup constant<br>
**P** ... playouts for the node<br>
**N** ... UCT value of the node<br>
**Na**... RAVE value of the node<br>
**α** ... AMAF weight factor<br>
**NR**... combined RAVE+UCT value of the node<br>

Then the α value is<br>
α = (R-P)/R<br>

if α<0, then we just take 0 instead<br>

Now the final value computes as:<br>
NR = α * Na + (1-α) x N<br>

 Project status
 --------------
 
 The current state of this projects implements all of these strategies.
 It has an estimated rank of 3kyu to 1dan, based on ManyFacesOfGo rating on 7x7 board when playing with 10 seconds per move.
 On 19x19 it can still be considered a beginner player, mostly caused by performance issues and ineffective implementations.
 
 See Issues for future plans.
 
 
 
 
