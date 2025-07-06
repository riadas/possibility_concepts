using Combinatorics
include("base_semantics.jl")

function generate_language(spec=nothing; and_or=false)
    hybrid_options = [false] # [true, false]
    hybrid_option = sample(hybrid_options)

    num_modes = 0
    if hybrid_option 
        lang1, spec1 = generate_atomic_infer_modes(spec)
        lang2, spec2 = generate_atomic_infer_modes(spec)
        num_modes = maximum(spec1["num_modes"], spec2["num_modes"])
        lang = """
        function infer_modes(task::Task)
            if task.visible
                $(lang1)
            else
                $(lang2)
            end
        end
        """
    else
        lang, spec_ = generate_atomic_infer_modes(spec)
        num_modes = spec_["num_modes"]
        lang = join(map(x -> x[3:end], split(lang, "\n")), "\n")
        lang = """
        function infer_modes(task::Task)
        $(lang)
        end
        """ 
    end

    if !isnothing(spec) && !("can_bin_op" in keys(spec))
        return "$(lang)\n\n$(can_correct_str)\n\n$(have_to_correct_str)"
    else
        can_have_to_str = generate_can_have_to(spec, num_modes)
        return "$(lang)\n\n$(can_have_to_str)"
    end

end

function generate_can_have_to(spec, num_modes)
    if !isnothing(spec)
        have_to_equals_can = spec["have_to_equals_can"]
        can_bin_op = spec["can_bin_op"]
        can_list = spec["can_list"]

        if !have_to_equals_can 
            have_to_bin_op = spec["have_to_bin_op"]
        else
            have_to_bin_op = ""
        end
    else
        have_to_equals_can = sample([true, false])

        can_bin_op = sample(["or", "and"])
        have_to_bin_op = sample(["or", "and"])

        list_options = map(l -> map(i -> [mode1, mode2, mode3][i], l), collect(combinations(collect(1:num_modes))))
        list_options = [list_options..., []]

        can_list = repr(sample(list_options))
    end

    can_str = replace(replace(can_base_str, 
        "[bin_op]" => can_bin_op), 
        "[can_list_placeholder]" => can_list)

    if have_to_equals_can
        have_to_str = """
        function have_to(verbal_task::VerbalTask, infer_alg_dist)::Bool
            Base.invokelatest(can, verbal_task, infer_alg_dist)
        end
        """
    else
        have_to_list = !isnothing(spec) ? spec["have_to_list"] : repr(sample(list_options))
        have_to_str = replace(replace(have_to_base_str, 
            "[bin_op]" => have_to_bin_op), 
            "[have_to_list_placeholder]" => have_to_list)
    end
    
    can_have_to_str = "$(can_str)\n\n$(have_to_str)"
    return can_have_to_str
end

function generate_atomic_infer_modes(spec=nothing)
    if isnothing(spec)        
        num_mode_options = [1, 2, 3]
        check_disabled_options = [false, true]
        algorithm_options = ["none", "sample", "enumerate"]

        spec = Dict([
            "num_modes" => sample(num_mode_options),
            "check_disabled" => sample(check_disabled_options),
            "algorithm" => sample(algorithm_options) 
        ])
    end

    infer_mode_str = generate_infer_modes(spec)
    # can_str, have_to_str = generate_can_and_have_to(spec)

    language_str = infer_mode_str

    return language_str, spec
end

function generate_infer_modes(spec)
    num_modes = spec["num_modes"]
    check_disabled = spec["check_disabled"]
    algorithm = spec["algorithm"]

    # base 
    if num_modes == 1 
        base_mode = "mode1"
        disabled_mode = "mode1"
    else 
        base_mode = "mode1"
        disabled_mode = "mode2"
    end

    if check_disabled 
        base_str = replace(replace(base_disable_check_str, 
            "[base_mode]" => base_mode), 
            "[disabled_mode]" => disabled_mode
        )
    else
        base_str = replace(base_no_disabled_check_str, 
            "[base_mode]" => base_mode
        )
    end

    if algorithm == "none"
        alg_str = ""
    elseif algorithm == "sample"
        if num_modes == 1 
            unselected_mode = "mode1"
        elseif num_modes == 2 
            unselected_mode = "mode2"
        elseif num_modes == 3 
            unselected_mode = "mode2"
        end

        alg_str = replace(alg_sample_str, "[unselected_mode]" => unselected_mode)
    elseif algorithm == "enumerate"
        if num_modes == 1 
            enumerated_mode = "mode1"
        elseif num_modes == 2 
            enumerated_mode = "mode1"
        elseif num_modes == 3 
            enumerated_mode = "mode3"
        end

        alg_str = replace(alg_enumerate_str, "[enumerated_mode]" => enumerated_mode)
    end

    return """    
            result = Dict()
            for a in task.apparatuses
                result[a.id] = Dict()
                $(base_str)

                $(alg_str)
            end
            result
    """
end

base_disable_check_str = """
for option in a.options 
                if option.disabled 
                    result[a.id][option] = [disabled_mode] 
                else
                    result[a.id][option] = [base_mode]
                end
            end
            valid_options = filter(x -> !x.disabled, a.options)
"""

base_no_disabled_check_str = """
for option in a.options 
                result[a.id][option] = [base_mode]
            end
            valid_options = a.options
"""

alg_sample_str = """
if length(valid_options) > 1 
                selected = sample(valid_options)
                for o in valid_options 
                    if o != selected 
                        result[a.id][o] = [unselected_mode]
                    end
                end
            end
"""

alg_enumerate_str = """
if length(valid_options) > 1 
                for o in valid_options 
                    result[a.id][o] = [enumerated_mode]
                end
            end
"""

can_base_str = """
function can(verbal_task::VerbalTask, infer_alg_dist)::Bool
    task = verbal_task.task 
    outcome = verbal_task.outcome 
    apparatus = verbal_task.apparatus 

    function bin_op(x, y)
        Base.invokelatest([bin_op], x, y)
    end

    results = filter(x -> x[2] != 0.0, infer_alg_dist(task))
    if !isnothing(apparatus)
        foldl(bin_op, map(result -> result[1][apparatus.id][outcome] in [can_list_placeholder], results), init=false)
    else
        desired_outcome = string(outcome)
        matches = []
        for a in task.apparatuses
            for o in a.options 
                if string(o) == desired_outcome
                    push!(matches, foldl(bin_op, map(result -> result[1][a.id][o] in [can_list_placeholder], results), init=false))
                end
            end
        end
        foldl(bin_op, matches, init=false)
    end
end
"""

have_to_base_str = """
function have_to(verbal_task::VerbalTask, infer_alg_dist)::Bool
    task = verbal_task.task 
    outcome = verbal_task.outcome 
    apparatus = verbal_task.apparatus 

    function bin_op(x, y)
        Base.invokelatest([bin_op], x, y)
    end

    results = filter(x -> x[2] != 0.0, infer_alg_dist(task))
    if !isnothing(apparatus)
        foldl(bin_op, map(result -> result[1][apparatus.id][outcome] in [have_to_list_placeholder], results), init=true)
    else
        desired_outcome = string(outcome)
        matches = []
        for a in task.apparatuses
            for o in a.options 
                if string(o) == desired_outcome
                    push!(matches, foldl(bin_op, map(result -> result[1][a.id][o] == [have_to_list_placeholder], results), init=true))
                end
            end
        end
        foldl(bin_op, matches, init=true)
    end
end
"""

can_correct_str = """
function can(verbal_task::VerbalTask, infer_alg_dist)::Bool
    can_correct(verbal_task, infer_alg_dist)
end
"""

have_to_correct_str = """
function have_to(verbal_task::VerbalTask, infer_alg_dist)::Bool
    have_to_correct(verbal_task, infer_alg_dist)
end
"""