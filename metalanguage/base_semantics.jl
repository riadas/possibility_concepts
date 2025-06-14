abstract type Option end 

@enum Judgment impossible possible necessary

struct Apparatus
    options::Vector{Option}
    id::Int
end

struct Task 
    apparatuses::Vector{Apparatus}
    visible::Bool
end

Result = Dict{Int, Dict{Option, Judgment}}
Dist = Vector{Tuple{Result, Float64}}

@enum Color red blue green yellow pink black 
@enum Direction left center right

struct Cup <: Option 
    color::Color
    disabled::Bool
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

Apparatus(options::Vector{Option}) = Apparatus(options, increment_apparatus_id())
Cup(color::Color, disabled::Bool=false) = Cup(color, disabled, increment_id())
Path(direction::Direction, disabled::Bool=false) = Path(direction, disabled, increment_id())
Gumball(color::Color, disabled::Bool=false) = Gumball(color, disabled, increment_id())
string(x::Union{Apparatus, Option}) = join(split(string(x), ",")[1:end-1], ",")

function minimal_infer(task::Task)::Result
    result = Dict()
    for a in task.apparatuses
        result[a.id] = Dict()
        options = a.options 
        valid_options = filter(o -> !o.disabled, options)
        if length(valid_options) == 1 
            result[a.id][valid_options[1]] = necessary
        elseif length(valid_options) > 1 
            o = sample(valid_options) # TODO figure out probability computation
            result[a.id][o] = necessary 
            for o_ in valid_options
                if o_ != o 
                    result[a.id][o_] = impossible
                end
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

function modal_infer(task::Task)::Result
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

function minimal_infer_dist(task::Task)::Dist 
    os = []
    for a in task.apparatuses
        result[a.id] = Dict()
        options = a.options 
        valid_options = filter(o -> !o.disabled, options)
        if >= 1
            push!(os, options) 
        else
            error("all options are disabled")            
        end
    end

    variants = [Iterators.product(os...)]
    prob = 1.0/length(variants)

    results = []
    for variant in variants 
        result = Dict()
        for i in 1:length(task.apparatuses)
            a = task.apparatuses[i]
            result[a.id] = Dict()

            variant_o = variant[i]
            result[a.id][variant_o] = necessary

            options = a.options 
            valid_options = filter(o -> !o.disabled, options)
            if length(valid_options) > 1 
                for o_ in valid_options
                    if o_ != variant_o
                        result[a.id][o_] = impossible
                    end
                end
            end

            for o in options 
                if o.disabled 
                    result[a.id][o] = impossible
                end
            end

        end
        push!(results, result)
    end

    map(r -> (r, prob), results)
end

function modal_infer_dist(task::Task)::Dist 
    result = modal_infer(task)
    [(result, 1.0)]
end

function infer_sample(task::Task)
    if task.visible 
        modal_infer(task)
    else
        minimal_infer(task)
    end
end

function infer_distribution(task::Task)
    if task.visible 
        modal_infer_dist(task)
    else
        minimal_infer_dist(task)
    end
end

function can(task::Task, outcome::Option, infer_alg, apparatus)::Bool
    result = infer_alg(task)
    if !isnothing(apparatus)
        result[apparatus.id][outcome] in [possible, necessary]
    else
        desired_outcome = string(outcome)
        matches = []
        for a in task.apparatuses
            for o in a.options 
                if string(o) == string(desired_outcome)
                    push!(matches, result[a.id][o])
                end
            end
        end
        foldl(|, map(r -> r in [possible, necessary], matches), init=false)
    end
end

function must(task::Task, outcome::Option, infer_alg, apparatus)::Bool
    result = infer_alg(task)
    if !isnothing(apparatus)
        result[apparatus.id][outcome] == necessary
    else
        desired_outcome = string(outcome)
        matches = []
        for a in task.apparatuses
            for o in a.options 
                if string(o) == string(desired_outcome)
                    push!(matches, result[a.id][o])
                end
            end
        end
        foldl(&, map(r -> r == necessary, matches), init=true)
    end
end

function and(pred1, pred2)
    pred1 && pred2
end

function or(pred1, pred2)
    pred1 || pred2
end

function not(pred)
    !pred
end

# Vector{WeightedResult}, WeightedResult = Tuple{Result, Float64}