include("base_semantics.jl")

function modal_infer(task::Task)::Result
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
    sample([true, false])
end

function must(task::Task, outcome::Option, infer_alg_dist, apparatus)::Bool
    sample([true, false])
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