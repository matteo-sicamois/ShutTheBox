using Revise
includet("ShutTheBox.jl")
using BenchmarkTools
using .ShutTheBox


#Players
function human_player(config::GameConfig, game::GameState)
    idx_move = nothing
    while isnothing(idx_move)
        print("Choose move: ")
        val = tryparse(Int, readline())
        if val !== nothing && 1 <= val <= length(game.legal_moves)
            idx_move = val
        else
            println("Invalid choice. Please enter a number between 1 and $(length(game.legal_moves)).")
        end
    end
    return game.legal_moves[idx_move]
end

function random_player(config::GameConfig, game::GameState)
    return rand(game.legal_moves)
end

function expectimax_player(config::GameConfig,state::GameState, max_depth::Int = 100)
    value_table_player = Dict{Int, Float64}()
    value_table_chance = Dict{Int, Float64}()
    function expectimax(config::GameConfig,state::GameState, depth::Int = 0, max_depth::Int = 100)
        (state.is_terminal || depth == max_depth) && return state.result
        key = (state.dices_sum << config.N_MAX) + state.numbers
        if state.player_turn
            haskey(value_table_player,key) && return value_table_player[key]
            best_move = 0
            a_max = -Inf
            for move in state.legal_moves
                ShutTheBox.apply_move!(config,state,move)
                a = expectimax(config,state,depth+1,max_depth)
                if a > a_max
                    a_max = a
                    best_move = move
                end
                ShutTheBox.rollback_move!(config,state)
            end
            value_table_player[key] = a_max
        else
            haskey(value_table_chance,key) && return value_table_chance[key]
            a_max = 0
            for i in 1:length(config.chance_choices)
                ShutTheBox.apply_move!(config,state,config.chance_choices[i])
                a_max += expectimax(config,state,depth+1,max_depth)*config.chance_distribution[i]
                ShutTheBox.rollback_move!(config,state)
                value_table_chance[key] = a_max
            end
        end
        #depth == 0 && return best_move
        return a_max
    end
    return expectimax(config ,state, 0 , max_depth)
end


#Gameplay functions
function play(config::GameConfig, game::GameState, player::Function, verbose::Bool)
    verbose && println("Starting game")
    while !game.is_terminal
        if game.player_turn
            if verbose
                ShutTheBox.print_state(config,game)
            end
            move = player(config, game)
            ShutTheBox.apply_move!(config, game, move)
        else
            ShutTheBox.apply_move!(config, game, ShutTheBox.roll(config, game))
        end
    end
    verbose && println("result: $(game.result)\n\n")
end

function play_repeat(config::GameConfig, game::GameState, player::Function, verbose::Bool, n_games::Int)
    blueprint = deepcopy(game)
    game = GameState(config)
    wins = 0
    for i in 1:n_games
        ShutTheBox.reset!(game,blueprint)
        play(config, game, player, verbose)
        if game.result > 0 wins += 1 end
    end
    print("wins: $wins\nwin rate: $(wins/n_games)")
end

function test(N = 12)
    config = GameConfig(N_MAX = N,
    chance_choices = collect(2:N),
    chance_distribution = [1/20 for i in 2:N])
    game = GameState(config)
    expectimax_player(config,game,1000)
end

function benchmark_code(N)
    for n in N
        config = GameConfig(N_MAX = n,
            chance_choices = collect(2:n),
            chance_distribution = [1/(n-1) for i in 2:n])
        game = GameState(config)
        print("N = $n: ")
        @btime expectimax_player($config,$game,1000)
    end
end


config = GameConfig()
game = GameState(config)
play(config, game,human_player,true)
#=N = 5:   36.417 μs (1787 allocations: 50.75 KiB)
N = 6:   124.291 μs (6083 allocations: 178.14 KiB)
N = 7:   372.959 μs (21216 allocations: 490.52 KiB)
N = 8:   1.047 ms (63048 allocations: 1.45 MiB)
N = 9:   2.975 ms (171110 allocations: 4.16 MiB)
N = 10:  7.817 ms (445518 allocations: 9.67 MiB)
N = 11:  20.158 ms (1129011 allocations: 25.53 MiB)
N = 12:  50.546 ms (2791266 allocations: 58.89 MiB)
N = 13:  134.549 ms (6778359 allocations: 147.40 MiB)
N = 14:  324.611 ms (16187922 allocations: 336.18 MiB)
N = 15:  967.654 ms (38176016 allocations: 828.33 MiB)
N = 18:  15.576 s (469282756 allocations: 9.72 GiB)
N = 20:  81.945 s (2400037074 allocations: 49.19 GiB)=#
using Plots
x = [5,6,7,8,9,10,11,12,13,14,15,18,20]
y = [0.036417,0.124291,0.372959,1.047,2.975,7.817,20.158,50.546,134.549,324.611,967.654,15576,81945]
plot(x, y)