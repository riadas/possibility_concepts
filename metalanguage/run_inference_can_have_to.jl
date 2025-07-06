include("metalanguage.jl")
include("../language/test.jl")
include("../configs/visualize_tasks.jl")

global alpha_num_modes = 0.1
global alpha_check_disabled = 0.8 # 0.48
global alpha_alg_variant = 0.0001
global num_repeats = 30

num_mode_options = [1, 2, 3]
check_disabled_options = [false, true]
algorithm_options = ["none", "sample", "enumerate"]

spec = Dict([
    "num_modes" => sample(num_mode_options),
    "check_disabled" => sample(check_disabled_options),
    "algorithm" => sample(algorithm_options) 
])

function compute_prior(language_spec)
    prob = 1.0 

    # prior on num modes
    num_modes_probs = map(x -> alpha_num_modes^x, [1,2,3])
    num_modes_sum = sum(num_modes_probs)
    num_modes_probs = num_modes_probs ./ num_modes_sum

    num_modes_prob = num_modes_probs[language_spec["num_modes"]]
    prob = prob * num_modes_prob 

    # prior on check disabled 
    if language_spec["check_disabled"]
        prob = prob * alpha_check_disabled
    else
        prob = prob * (1 - alpha_check_disabled)
    end

    # prior on alg options 
    alg_options_probs = map(x -> alpha_alg_variant^x, [1,2,5])
    alg_options_sum = sum(alg_options_probs)
    alg_options_probs = alg_options_probs ./ alg_options_sum 

    alg_options_prob = alg_options_probs[findall(x -> x == language_spec["algorithm"],  ["none", "sample", "enumerate"])[1]]
    prob = prob * alg_options_prob 

    # TODO: prior on can/have to definitions
    # current patch: un-normalized score 
    if language_spec["have_to_equals_can"]
        prob = prob * 100
    end

    # patch 2 
    if language_spec["can_bin_op"] == "or"
        prob = prob * 5
    end

    return prob
end

function compute_likelihood_verbal(task::VerbalTask, language_spec)
    l = generate_language(language_spec)
    println(l)
    parts = split(l, "end\n\n\nfunction")
    for i in 1:length(parts)
        part = parts[i] 
        if i != 1
            part = "function$(part)"
        end

        if i != length(parts)
            part = "$(part)\nend"
        end
        eval(Meta.parse(part)) # redefines the infer_modes, can, and have_to functions
    end
    
    function infer_modes_dist(task, num_samples=100)
        results = []
        for i in 1:num_samples 
            result = Base.invokelatest(infer_modes, task)
            push!(results, repr(result))
        end
        unique!(results)
        weighted_results = map(x -> (eval(Meta.parse(x)), 1/length(results)), results)
        return weighted_results
    end

    if task.can 
        answer = Base.invokelatest(can, task, infer_modes_dist)
        correct_answer = can_correct(task, infer_modes_dist_correct)
    else
        answer = Base.invokelatest(have_to, task, infer_modes_dist)
        correct_answer = have_to_correct(task, infer_modes_dist_correct)
    end

    if answer == correct_answer 
        1.0
    else
        0.0
    end
end

function compute_likelihood_nonverbal(task::NonverbalTask, language_spec)
    l = generate_language(language_spec)
    println(l)
    parts = split(l, "end\n\n\nfunction")
    for i in 1:length(parts)
        part = parts[i] 
        if i != 1
            part = "function$(part)"
        end

        if i != length(parts)
            part = "$(part)\nend"
        end
        eval(Meta.parse(part)) # redefines the infer_modes, can, and have_to functions
    end

    function infer_modes_dist(task, num_samples=100)
        results = []
        for i in 1:num_samples 
            result = Base.invokelatest(infer_modes, task)
            push!(results, repr(result))
        end
        unique!(results)
        weighted_results = map(x -> (eval(Meta.parse(x)), 1/length(results)), results)
        return weighted_results
    end

    results = Base.invokelatest(infer_modes_dist, task)

    overall_prob = nothing
    overall_probs = []

    translated_results = []
    for result in results 
        translated_result = translate_synth_modes_to_real_modes(result[1])
        push!(translated_results, (translated_result, result[2]))
    end 
    results = translated_results

    # @show results 
    option = task.apparatuses[1].options[1]
    if option isa Cup || option isa Path # prize is an option
        for result in results
            result, dist_prob = result
            prize_apparatus = task.apparatuses[end]
            prize_option = prize_apparatus.options[1]
            prize_str = string(prize_option)
            # @show prize_apparatus.id
            prize_result = result[prize_apparatus.id][prize_option]
            prize_prob = result[prize_apparatus.id][prize_option] == possible ? 0.5 : (result[prize_apparatus.id][prize_option] == impossible ? 0.0 : 1.0)
            
            alt_options = filter(x -> result[task.apparatuses[1].id][x] != impossible, task.apparatuses[1].options)
            alt_probs = map(x -> result[task.apparatuses[1].id][x] == possible ? 0.5 : 1.0, alt_options)
            
            # println(alt_probs)
            # println(prize_prob)
            if alt_probs == []
                overall_prob = 1.0
            elseif maximum(alt_probs) > prize_prob
                overall_prob = 0.0
            elseif maximum(alt_probs) == prize_prob 
                overall_prob = 1/(length(alt_probs) + count(x -> x == prize_result, [values(result[prize_apparatus.id])...]))
            elseif maximum(alt_probs) < prize_prob
                overall_prob = 1.0
            end
            push!(overall_probs, overall_prob * dist_prob)
        end
    elseif option isa Gumball # prize is an apparatus            
        for result in results 
            result, dist_prob = result
            prize_apparatus = task.apparatuses[end]
            prize_option = prize_apparatus.options[1]
            prize_str = string(prize_option)
            prize_result = result[prize_apparatus.id][prize_option]
            prize_prob = 1.0 # result[prize_apparatus.id][prize_option] == possible ? 0.5 : 1.0
            
            alt_options = filter(x -> string(x) == prize_str && result[task.apparatuses[1].id][x] != impossible, task.apparatuses[1].options)
            alt_probs = map(x -> result[task.apparatuses[1].id][x] == possible ? 0.5 : 1.0, alt_options)
            
            if length(prize_apparatus.options) == 2 && unique([values(result[prize_apparatus.id])...]) == [necessary]
                overall_prob = 0.5
            else
                if alt_probs == []
                    overall_prob = 1.0
                elseif maximum(alt_probs) > prize_prob
                    overall_prob = 0.0
                elseif maximum(alt_probs) == prize_prob 
                    overall_prob = 1/(length(alt_probs) + 1)
                elseif maximum(alt_probs) < prize_prob
                    overall_prob = 1.0
                end
            end
            push!(overall_probs, overall_prob * dist_prob)
        end
    elseif option isa Arm 
        overall_probs = [results[1][1][task.apparatuses[1].id][task.apparatuses[1].options[end]] == impossible ? 1.0 : 2/3]
    end
    overall_prob = sum(overall_probs)
    return overall_prob
end

function compute_likelihood_mixed(tasks::Vector{<:Task}, language_spec)
    println("COMPUTE_LIKELIHOOD")
    nonverbal_tasks = filter(x -> x isa NonverbalTask, tasks)
    probs = map(task -> compute_likelihood_nonverbal(task, language_spec), nonverbal_tasks)
    nonverbal_likelihood = foldl(*, probs, init=1.0)

    verbal_tasks = filter(x -> x isa VerbalTask, tasks)
    probs = map(task -> compute_likelihood_verbal(task, language_spec), verbal_tasks)
    @show probs
    verbal_likelihood = foldl(+, probs, init=0.0)/length(probs)

    nonverbal_likelihood * verbal_likelihood
end

chance_spec = Dict([
    "num_modes" => 1,
    "check_disabled" => false,
    "algorithm" => "none" 
])

intermediate_spec = Dict([
    "num_modes" => 2,
    "check_disabled" => true,
    "algorithm" => "none" 
])

minimal_spec = Dict([
    "num_modes" => 2,
    "check_disabled" => true,
    "algorithm" => "sample" 
])

modal_spec = Dict([
    "num_modes" => 3,
    "check_disabled" => true,
    "algorithm" => "enumerate" 
])

# specs = [chance_spec, intermediate_spec, minimal_spec, modal_spec]

specs = []
for num_modes in [1,2,3]
    list_options = map(l -> map(i -> [mode1, mode2, mode3][i], l), collect(combinations(collect(1:num_modes))))
    list_options = [list_options..., []]
    for check_disabled in [false, true]
        for algorithm in ["none", "sample", "enumerate"]
            spec = Dict([
                "num_modes" => num_modes,
                "check_disabled" => check_disabled,
                "algorithm" => algorithm
            ])

            for can_bin_op in ["or", "and"]
                spec["can_bin_op"] = can_bin_op
                for can_list in list_options 
                    spec["can_list"] = can_list
                    for have_to_equals_can in [true, false]
                        spec["have_to_equals_can"] = have_to_equals_can
                        if !have_to_equals_can 
                            for have_to_bin_op in ["or", "and"]
                                spec["have_to_bin_op"] = have_to_bin_op
                                for have_to_list in list_options 
                                    spec["have_to_list"] = have_to_list
                                    push!(specs, deepcopy(spec))
                                end
                            end
                        else
                            push!(specs, deepcopy(spec))
                        end
                    end
                end
            end
        end
    end
end

tasks = [
    # three_cups_task,
    # four_cups_task,
    three_slides_task,
    four_slides_task,
    # three_gumballs_task,
    # four_gumballs_task,
    # three_arm_task,
    four_cups_task_verbal_option1_can,
    four_cups_task_verbal_option1_have_to,
    four_cups_task_verbal_option2_can,
    four_cups_task_verbal_option2_have_to,

    four_cups_task_verbal_option3_can,
    four_cups_task_verbal_option3_have_to,
    four_cups_task_verbal_option4_can,
    four_cups_task_verbal_option4_have_to,
]

spec_names = []
posteriors = Dict()
priors = []
likelihoods = []
for i in 1:length(specs)
    println("SPEC NUMBER: $(i)")
    spec = specs[i] 
    spec_name = join(map(k -> "$(k)=$(spec[k])", sort([keys(spec)...])), ", ")
    push!(spec_names, spec_name)
    posteriors[spec_name] = []

    prior = compute_prior(spec)
    likelihood = compute_likelihood_mixed(tasks, spec)
    push!(priors, prior)
    push!(likelihoods, likelihood)
    for repeats in 1:num_repeats
        push!(posteriors[spec_name], prior*(likelihood)^repeats)
    end
end

println()

for repeats in 1:num_repeats
    println("REPEATS: $(repeats)")
    i = findall(name -> posteriors[name][repeats] == maximum(map(n -> posteriors[n][repeats], spec_names)),  spec_names)[1]
    map_spec_name = spec_names[i]
    println(map_spec_name)
end

sums = map(r -> sum(map(n -> posteriors[n][r], spec_names)), 1:num_repeats)

# pretty_spec_names = ["chance language, no impos", "chance language, with impos", "minimal language, i.e. propositional logic", "modal language, i.e. first-order logic"]

p = plot(1:num_repeats, collect(1:num_repeats) * 1/num_repeats, color="white", label=false)
for i in 1:length(spec_names)
    spec_name = spec_names[i]
    println(spec_name)
    println("\tprior: $(priors[i])")
    println("\tlikelihood: $(likelihoods[i])")
    p = plot!(collect(1:num_repeats), posteriors[spec_name] ./ sums, label = "$(spec_name)", legend=false)
end
xlabel!("Training Data Volume", xguidefontsize=9)
ylabel!("Proportion", yguidefontsize=9)
title!("Relative Proportions of Possibility Concept LoTs", titlefontsize=10)

p