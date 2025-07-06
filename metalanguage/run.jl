include("metalanguage.jl")
include("../language/test.jl")
include("../configs/visualize_tasks.jl")

task = four_cups_task
l = generate_language()
println(l)
eval(Meta.parse(l))

function infer_modes_dist(task, num_samples=100)
    results = []
    for i in 1:num_samples 
        result = infer_modes(task)
        push!(results, repr(result))
    end
    unique!(results)
    weighted_results = map(x -> (eval(Meta.parse(x)), 1/length(results)), results)
    return weighted_results
end

dist = infer_modes_dist(task)
# println(dist)
visualize_NonverbalTask(task, dist, show_probs=true, show_title=true)