# slow... should use bottom-up approach (dynamic programming) instead
function generate_all_combinations(num_categories, num_samples, prefix=[])
    combos = []
    if num_categories == 1 
        full_combo = Tuple([prefix..., num_samples])
        return [full_combo]
    else
        for i in 0:num_samples 
            remaining_samples = num_samples - i
            remaining_categories = num_categories - 1
            push!(combos, generate_all_combinations(remaining_categories, remaining_samples, [prefix..., i])...)
        end
    end
    combos
end

function compute_prob(combo, weights)
    prob = 1.0 
    for i in 1:length(combo)
        prob = prob * (weights[i])^combo[i] 
    end
    n_choose_k = factorial(big(length(weights)))/foldl(*,map(x -> factorial(big(x)), combo), init=1.0)
    prob = prob * n_choose_k
end

function compute_log_prob(combo, weights)
    logprob = 0.0 
    for i in 1:length(combo)
        logprob += log(weights[i]) * combo[i]
    end
    log_n_choose_k = log(factorial(big(length(weights)))/foldl(*,map(x -> factorial(big(x)), combo), init=1.0))
    logprob += log_n_choose_k
end

function sample_from_category_dist(weights; num_samples=1)
    num_categories = length(weights)
    all_combos = generate_all_combinations(num_categories, num_samples)
    all_combo_weights = map(combo -> compute_prob(combo, weights), all_combos)

    combo = sample(all_combos, Weights(all_combo_weights))

    # visualize combo
    @show combo
    p = bar(["a", "b", "c", "d"][1:length(combo)], collect(combo) ./ num_samples, legend=false)
    t = "Total Samples = $(num_samples)"
    title!(t)
    xlabel!("Category")
    ylabel!("Proportion of Samples")
end