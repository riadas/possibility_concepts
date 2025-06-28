include("base_semantics.jl")

function generate_language(spec=nothing)
    hybrid_options = [false] # [true, false]
    hybrid_option = sample(hybrid_options)

    if hybrid_option 
        lang1, spec1 = generate_atomic_language(spec)
        lang2, spec2 = generate_atomic_language(spec)
        return """
        function infer_modes(task::Task)
            if task.visible
                $(lang1)
            else
                $(lang2)
            end
        end
        """
    else
        lang, spec = generate_atomic_language(spec)
        lang = join(map(x -> x[3:end], split(lang, "\n")), "\n")
        return """
        function infer_modes(task::Task)
        $(lang)
        end
        """ 
    end
end

function generate_atomic_language(spec=nothing)
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

function generate_can_and_have_to(spec)

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