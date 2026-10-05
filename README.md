# ShutTheBox
This is a Julia environment for the game shut the box.

## Rules
Shut the box is a single player dice game. At the start of the game there are N available numbers (9 by default) that will be "shut" during the game. Every turn the player rolls 2 dice and decides any combination of still available numbers that sums up to the resul of the dice. For example after rolling a 9 the possible combinations are (9) (8,1) (7,2) (6,3) (5,4) (6,2,1) (5,3,1). The game ends either when there are no available moves, in which case it results in a loss, or when all the numbers are shut, which results in a win.

## Implementation
This implementation of shut the box uses a bitboard to represent board states and it alternates between a player node where the move is chosen, and a chance node where the dices are rolled. The game module is divided into a configuration struct and a game state struct. Some methodes like apply_move!, rollback_move! and roll! are also avalilable. 

Three types of player have been implemented: human_player takes the input from the terminal, random_player chooses a random legal move and expectimax_player is able to calculate the best possible move to increase winrate. 

The expectimax algorithm explores every node to asses its value. Every player node has as childs the board states achieved by playing the legal moves. A chance node has as childs the board state achieved by rolling any available number on dices. On player nodes the value is the maximum of the value of its childs. On chance nodes the value is the weighted sum of the value of each child. 

## Benchmarks
The game scales exponentially with respect to the maximum number N. All legal moves are precalculated to improve performance at the cost of memory usage. There are 2^N possible board states and 11 possible dices states so during the initialization of configuration struct a matrix of 2^N*11 is created and filled with arrays of possible moves. 

What follows are the time and memory for expectimax to calculate the value of the root node for different values of N
- N = 5:   36.417 μs (1787 allocations: 50.75 KiB)
- N = 6:   124.291 μs (6083 allocations: 178.14 KiB)
- N = 7:   372.959 μs (21216 allocations: 490.52 KiB)
- N = 8:   1.047 ms (63048 allocations: 1.45 MiB)
- N = 9:   2.975 ms (171110 allocations: 4.16 MiB)
- N = 10:  7.817 ms (445518 allocations: 9.67 MiB)
- N = 11:  20.158 ms (1129011 allocations: 25.53 MiB)
- N = 12:  50.546 ms (2791266 allocations: 58.89 MiB)
- N = 13:  134.549 ms (6778359 allocations: 147.40 MiB)
- N = 14:  324.611 ms (16187922 allocations: 336.18 MiB)
- N = 15:  967.654 ms (38176016 allocations: 828.33 MiB)
- N = 18:  15.576 s (469282756 allocations: 9.72 GiB)
- N = 20:  81.945 s (2400037074 allocations: 49.19 GiB)
