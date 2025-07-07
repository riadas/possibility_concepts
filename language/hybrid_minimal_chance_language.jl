include("base_semantics.jl")

function minimal_infer(task::Task)::Result
    result = Dict()
    for a in task.apparatuses
        result[a.id] = Dict()
        options = a.options 
        valid_options = filter(o -> !o.disabled, options)
        if length(valid_options) == 1 
            result[a.id][valid_options[1]] = necessary
        elseif length(valid_options) > 1 
            o = sample(valid_options)
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

function minimal_infer_dist(task::Task)::Dist 
    os = []
    for a in task.apparatuses
        options = a.options 
        valid_options = filter(o -> !o.disabled, options)
        if length(valid_options) >= 1
            push!(os, valid_options) 
        else
            error("all options are disabled")            
        end
    end

    variants = [Iterators.product(os...)...]
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

function chance_infer(task::Task)
    result = Dict()
    for a in task.apparatuses
        result[a.id] = Dict()
        options = a.options 
        for o in options 
            result[a.id][o] = necessary
        end
    end
    result
end

function chance_infer_dist(task::Task)
    result = chance_infer(task)
    [(result, 1.0)]
end

function infer_sample(task::Task)
    if occursin("deterministic", task.name)
        minimal_infer(task)
    else
        chance_infer(task)
    end
end

function infer_distribution(task::Task)
    if occursin("deterministic", task.name)
        minimal_infer_dist(task)
    else
        chance_infer_dist(task)
    end
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
    can(task, outcome, infer_alg_dist, apparatus)
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