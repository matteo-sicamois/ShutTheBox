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

function expectimax_player(config::GameConfig,state::GameState, max_depth::Int = 100, return_move::Bool = true)
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
        depth == 0 && return_move && return best_move
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

function get_win_probability(N = 12)
    config = GameConfig(N_MAX = N,
    chance_choices = collect(2:N),
    chance_distribution = [1/20 for i in 2:N])
    game = GameState(config)
    expectimax_player(config,game,1000, false)
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
