include("base_semantics.jl")

function modal_infer(task::Task)::Result
    result = Dict()
    for a in task.apparatuses
        result[a.id] = Dict()
        options = a.options 
        valid_options = filter(o -> true, options) # !o.disabled
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
            if false # o.disabled 
                result[a.id][o] = impossible
            end
        end

    end
    result
end

function modal_infer_dist(task::Task)::Dist 
    result = modal_infer(task)
    [(result, 1.0)]
end

function infer_sample(task::Task)
    modal_infer(task)
end

function infer_distribution(task::Task)
    modal_infer_dist(task)
end

function can(task::Task, outcome::Option, infer_alg_dist, apparatus)::Bool
    results = filter(x -> x[2] != 0.0, infer_alg_dist(task))
    if !isnothing(apparatus)
        foldl(|, map(result -> result[1][apparatus.id][outcome] in [possible, necessary], results), init=false)
    else
        desired_outcome = string(outcome)
        matches = []
        for a in task.apparatuses
            for o in a.options 
                if string(o) == desired_outcome
                    push!(matches, foldl(|, map(result -> result[1][a.id][o] in [possible, necessary], results), init=false))
                end
            end
        end
        foldl(|, matches, init=false)
    end
end

function must(task::Task, outcome::Option, infer_alg_dist, apparatus)::Bool
    results = filter(x -> x[2] != 0.0, infer_alg_dist(task))
    if !isnothing(apparatus)
        foldl(&, map(result -> result[1][apparatus.id][outcome] == necessary, results), init=true)
    else
        desired_outcome = string(outcome)
        matches = []
        for a in task.apparatuses
            for o in a.options 
                if string(o) == desired_outcome
                    push!(matches, foldl(&, map(result -> result[1][a.id][o] == necessary, results), init=true))
                end
            end
        end
        foldl(&, matches, init=true)
    end
end

# function and(pred1, pred2)
#     pred1 && pred2
# end

# function or(pred1, pred2)
#     pred1 || pred2
# end

function not(pred)
    !pred
end

# Vector{WeightedResult}, WeightedResult = Tuple{Result, Float64}