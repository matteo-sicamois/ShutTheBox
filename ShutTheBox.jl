module ShutTheBox
export GameConfig, GameState

using StatsBase

#Game functions
function get_combination_lookup(n_max::Integer,chance_choices)
    combination_table = [Int[] for _ in 1:maximum(chance_choices), _ in 1: 2^n_max]
    for b in 1 : 2^n_max-1
        s = 0
        for n in 0 : n_max-1
            (b >> n & 1) == 1 && (s = s + n + 1)
        end
        if s in chance_choices
            for m in 0 : 2^n_max-1
                if m & b == b
                    push!(combination_table[s, m+1], b)
                end
            end
        end
    end
    return combination_table
end

@kwdef struct GameConfig
    N_MAX::Int = 9
    chance_distribution::Vector{Float64} = [1,2,3,4,5,6,5,4,3,2,1]./36
    chance_choices::Vector{Int} = collect(2:12)
    combinations_lookup::Matrix{Vector{Int}} = get_combination_lookup(N_MAX,chance_choices)
end

@kwdef mutable struct GameState
    numbers::Int 
    dices_sum::Int = -1
    legal_moves::Vector{Int} = Int[]
    player_turn::Bool = false
    history::Vector{Int} = Int[]
    is_terminal::Bool = false
    result::Union{Float64, Nothing} = nothing
    num_moves::Int = 0
end

GameState(config::GameConfig) = GameState(numbers = 2^config.N_MAX-1)

import Base.==
function ==(a::GameState, b::GameState)
    return all(getfield(a, f) == getfield(b, f) for f in fieldnames(GameState))
end

function ==(a::GameConfig, b::GameConfig)
    return all(getfield(a, f) == getfield(b, f) for f in fieldnames(GameConfig))
end

function reset!(state::GameState, blueprint::GameState)
    state.numbers = blueprint.numbers
    state.dices_sum = blueprint.dices_sum
    state.legal_moves = blueprint.legal_moves
    state.player_turn = blueprint.player_turn
    state.history = copy(blueprint.history)
    state.is_terminal = blueprint.is_terminal
    state.result = blueprint.result
    state.num_moves = blueprint.num_moves
end

function get_legal_moves(config::GameConfig, state::GameState)
    legal_moves = config.combinations_lookup[state.dices_sum, state.numbers+1]
    state.legal_moves = legal_moves
    return legal_moves
end

function roll(config::GameConfig, state::GameState)
    return sample(config.chance_choices,Weights(config.chance_distribution))
end

function apply_move!(config::GameConfig, state::GameState, move::Int)
    if state.player_turn
        state.numbers -= move
        push!(state.history, move)
        state.num_moves += 1
        if state.numbers == 0
            state.is_terminal = true
            state.result = 1.
        end
    else
        state.dices_sum = move
        push!(state.history, move)
        if isempty(get_legal_moves(config, state))
            state.is_terminal = true
            state.result = 0.
        end
    end
    state.player_turn = !state.player_turn
end

function rollback_move!(config::GameConfig, state::GameState)
    if state.is_terminal
        state.is_terminal = false 
        state.result = nothing
    end
    if !state.player_turn 
        move = pop!(state.history)
        state.numbers += move
        state.num_moves -= 1
        get_legal_moves(config, state)
    else
        move = pop!(state.history)
        state.dices_sum = !(state.num_moves == 0) ?  state.history[end - 1] : -1
        state.legal_moves = state.dices_sum == -1 ? Int[] : config.combinations_lookup[state.dices_sum,state.numbers+state.history[end]+1]
    end
    state.player_turn = !state.player_turn

    return move
end

function print_state(config::GameConfig, state::GameState)
    println("Turn $(state.num_moves+1)")
    print("numbers: ")
    println(join([string(i) for i in 1:config.N_MAX if isodd(state.numbers >> (i-1))],  " "))
    println("dices sum: $(state.dices_sum)")
    println("available moves: ")
    for (i, move) in enumerate(state.legal_moves)
        print("$i: ")
        println(join([string(i) for i in  1:config.N_MAX if isodd(move >> (i-1))], ", "))
    end
end

end