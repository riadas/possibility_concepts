using StatsBase 

abstract type Task end
abstract type Option end 

@enum Judgment impossible possible necessary mode1 mode2 mode3

struct Apparatus
    options::Vector{<:Option}
    id::Int
end

struct NonverbalTask <: Task 
    name::String
    apparatuses::Vector{Apparatus}
    visible::Bool
end

struct VerbalTask <: Task 
    task::NonverbalTask
    outcome::Option
    can::Bool
    apparatus::Union{Apparatus,Nothing}
end

Result = Dict{Int, Dict{Option, Judgment}}
Dist = Vector{Tuple{Result, Float64}}

@enum Color red blue green yellow pink black purple orange white
@enum Direction left center right

struct Cup <: Option 
    color::Color
    disabled::Bool
    shown_empty::Bool
    id::Int
end

struct Path <: Option
    direction::Direction 
    disabled::Bool
    id::Int
end

struct Gumball <: Option 
    color::Color
    disabled::Bool
    id::Int
end

struct Arm <: Option 
    direction::Direction
    disabled::Bool
    id::Int
end

struct ColoredPath <: Option 
    color::Color
    direction::Direction 
    disabled::Bool
    id::Int
end

global apparatus_counter = 0
global id_counter = 0

function increment_apparatus_id()
    global apparatus_counter += 1
    apparatus_counter
end

function increment_id()
    global id_counter += 1
    id_counter
end

VerbalTask(task::NonverbalTask, outcome::Option, can::Bool) = VerbalTask(task, outcome, can, nothing)
Apparatus(options::Vector{<:Option}) = Apparatus(options, increment_apparatus_id())
Cup(color::Color, disabled::Bool=false, shown_empty::Bool=false) = Cup(color, disabled, shown_empty, increment_id())
Path(direction::Direction, disabled::Bool=false) = Path(direction, disabled, increment_id())
Gumball(color::Color, disabled::Bool=false) = Gumball(color, disabled, increment_id())
Arm(direction::Direction, disabled::Bool=false) = Arm(direction, disabled, increment_id())
Base.string(x::Union{Apparatus, <:Option}) = "$(join(split(repr(x), ",")[1:end-1], ",")))"

mutable struct Function 
    name::String
    arg_names::Vector{String}
    arg_types::Vector{DataType}
    definition::String
end

# ----- default (correct) modal/logical functions -----

# default infer_modes
function infer_modes_correct(task::NonverbalTask)::Result
    result = Dict()
    for a in task.apparatuses
        result[a.id] = Dict()
        options = a.options 
        valid_options = filter(o -> !o.disabled, options)
        if length(valid_options) == 1 
            result[a.id][valid_options[1]] = necessary
        elseif length(valid_options) > 1 
            for o in valid_options 
                result[a.id][o] = possible
            end
        else
            error("all options are disabled")            
        end

        for o in options 
            if o.disabled 
                result[a.id][o] = impossible
            end
        end

    end
    result
end

function infer_modes_dist_correct(task, num_samples=100)
    results = []
    for i in 1:num_samples 
        result = infer_modes_correct(task)
        push!(results, repr(result))
    end
    unique!(results)
    weighted_results = map(x -> (eval(Meta.parse(x)), 1/length(results)), results)
    return weighted_results
end


# default can
function can(verbal_task::VerbalTask, infer_alg_dist)::Bool
    can_correct(verbal_task, infer_alg_dist)
end

function can_correct(verbal_task::VerbalTask, infer_alg_dist)::Bool
    task = verbal_task.task 
    outcome = verbal_task.outcome 
    apparatus = verbal_task.apparatus 

    results = filter(x -> x[2] != 0.0, infer_alg_dist(task))
    if !isnothing(apparatus)
        foldl(or, map(result -> result[1][apparatus.id][outcome] in [possible, necessary], results), init=false)
    else
        desired_outcome = string(outcome)
        matches = []
        for a in task.apparatuses
            for o in a.options 
                if string(o) == desired_outcome
                    push!(matches, foldl(or, map(result -> result[1][a.id][o] in [possible, necessary], results), init=false))
                end
            end
        end
        foldl(or, matches, init=false)
    end
end

# default have to
function have_to(verbal_task::VerbalTask, infer_alg_dist)::Bool
    have_to_correct(verbal_task, infer_alg_dist)
end

function have_to_correct(verbal_task::VerbalTask, infer_alg_dist)::Bool
    task = verbal_task.task 
    outcome = verbal_task.outcome 
    apparatus = verbal_task.apparatus 

    results = filter(x -> x[2] != 0.0, infer_alg_dist(task))
    if !isnothing(apparatus)
        foldl(and, map(result -> result[1][apparatus.id][outcome] == necessary, results), init=true)
    else
        desired_outcome = string(outcome)
        matches = []
        for a in task.apparatuses
            for o in a.options 
                if string(o) == desired_outcome
                    push!(matches, foldl(and, map(result -> result[1][a.id][o] == necessary, results), init=true))
                end
            end
        end
        foldl(and, matches, init=true)
    end
end

# default and 
function and(pred1, pred2)
    pred1 & pred2 # if false in [pred1, pred2], false; else true
end

# default or
function or(pred1, pred2)
    pred1 | pred2  # if true in [pred1, pred2], true; else false
end

# default not
function not(pred)
    !pred
end