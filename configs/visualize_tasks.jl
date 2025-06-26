using Plots
include("../language/base_semantics.jl")

function visualize_task(task::Task, results=nothing; save_filename="", show_probs=true, show_title=true)
    apparatus_plots = []
    result = nothing
    if results isa Vector 
        result = sample(results)[1]
    else
        result = results
    end
    
    for apparatus in task.apparatuses 
        p = visualize_apparatus(apparatus, result, show_probs=show_probs)
        push!(apparatus_plots, p)
    end

    # annotate overall success rate
    overall_prob = nothing
    if !isnothing(result) && show_title
        overall_probs = []
        if !(results isa AbstractArray) 
            results = [(result, 1.0)]
        end

        translated_results = []
        for result in results 
            translated_result = translate_synth_modes_to_real_modes(result[1])
            push!(translated_results, (translated_result, result[2]))
        end 
        results = translated_results

        @show results 
        option = task.apparatuses[1].options[1]
        if option isa Cup || option isa Path # prize is an option
            for result in results
                result, dist_prob = result
                prize_apparatus = task.apparatuses[end]
                prize_option = prize_apparatus.options[1]
                prize_str = string(prize_option)
                @show prize_apparatus.id
                prize_result = result[prize_apparatus.id][prize_option]
                prize_prob = result[prize_apparatus.id][prize_option] == possible ? 0.5 : (result[prize_apparatus.id][prize_option] == impossible ? 0.0 : 1.0)
                
                alt_options = filter(x -> result[task.apparatuses[1].id][x] != impossible, task.apparatuses[1].options)
                alt_probs = map(x -> result[task.apparatuses[1].id][x] == possible ? 0.5 : 1.0, alt_options)
                
                println(alt_probs)
                println(prize_prob)
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
    end

    if !isnothing(overall_prob)
        p = plot(apparatus_plots..., layout = (1, length(apparatus_plots)),size=(150*length(task.apparatuses),150))
        if show_title 
            p = plot(p, plot_title="overall success prob: $(round(overall_prob, digits=2))", plot_titlefont=font(6,"sans-serif"))
        end
    else
        p = plot(apparatus_plots..., layout = (1, length(apparatus_plots)),size=(150*length(task.apparatuses),150))
    end

    if save_filename != ""
        savefig(p, "$(save_filename)")
    end

    return p
end

function visualize_apparatus(apparatus::Apparatus, result=nothing; show_probs=true)
    # set up grid
    p = plot(0:2,0:2, linecolor="white")

    for i in 1:length(apparatus.options)
        option = apparatus.options[i] 
        p = visualize_option(p, option, i, length(apparatus.options), apparatus.id, result, show_probs=show_probs)
    end

    return p
end

label_abbrevs = Dict(["necessary" => "nec.", "possible" => "poss.", "impossible" => "imposs.", "mode1" => "mode1", "mode2" => "mode2", "mode3" => "mode3"])
label_abbrevs = Dict(["necessary" => "necessary", "possible" => "possible", "impossible" => "impossible", "mode1" => "mode1", "mode2" => "mode2", "mode3" => "mode3"])

function visualize_option(p, option::Cup, i, total, apparatus_id, result=nothing; show_probs=true)
    rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    trapezoid(w, h, x, y) = Shape(x .+ [-0.2,w+0.2,w+0.3,-0.3], y .+ [0,0,h,h])

    center_x = total == 1 ? 1 : i == total ? i/(total + 1) * 2 + 0.10 : i/(total + 1) * 2 - 0.10 
    # println(i)
    # println(total)
    # println(center_x)
    # p = plot(0:2,0:2, linecolor="white")
    c = option.disabled ? "red" : "black"
    p = plot!(p, trapezoid(0, 1, center_x, 0.5), opacity=.5, grid=false, axis=([], false), legend=false, size=(150, 150), linecolor=c, fillcolor=repr(option.color))

    if !isnothing(result)
        label = label_abbrevs[repr(result[apparatus_id][option])]
        annotate!.(center_x, 0.2, text.(label, :black, 6) )

        translated_result = translate_synth_modes_to_real_modes(result)
        all_values = [values(translated_result[apparatus_id])...]
        if length(unique(all_values)) == 1 
            prob = round(1/length(all_values), digits=2)
        elseif translated_result[apparatus_id][option] == necessary 
            prob = 1.0
        else
            prob = 0.0
        end
        if show_probs
           annotate!.(center_x, 0, text.(string(prob), :green, 6) )
        end
    end

    return p
end

function circle_shape(h, k, r)
    theta = LinRange(0, 2*pi, 500)
    h .+ r*sin.(theta), k .+ r*cos.(theta)
end

function visualize_option(p, option::Gumball, i, total, apparatus_id, result=nothing; show_probs=true)
    center_x = total == 1 ? 1 : i == total ? i/(total + 1) * 2 + 0.10 : i/(total + 1) * 2 - 0.10 
    # println(i)
    # println(total)
    # println(center_x)

    c = option.disabled ? "red" : "black"
    p = plot!(p, circle_shape(1, 1.15, 0.75), grid=false, axis=([], false), legend=false, size=(150, 150), c=c)
    p = plot!(p, circle_shape(center_x, 0.7, 0.1), grid=false, axis=([], false), legend=false, size=(150, 150), c=repr(option.color), seriestype=[:shape,], fill_alpha=0.8)

    if !isnothing(result)
        label = label_abbrevs[repr(result[apparatus_id][option])]
        annotate!.(center_x, 0.3, text.(label, :black, 6) )

        translated_result = translate_synth_modes_to_real_modes(result)
        all_values = [values(translated_result[apparatus_id])...]
        if length(unique(all_values)) == 1 
            prob = round(1/length(all_values), digits=2)
        elseif translated_result[apparatus_id][option] == necessary 
            prob = 1.0
        else
            prob = 0.0
        end
        if show_probs 
            annotate!.(center_x, 0, text.(string(prob), :green, 6) )
        end
    end

    return p
end

function visualize_option(p, option::Path, i, total, apparatus_id, result=nothing; show_probs=true)
    rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    trapezoid(w, h, x, y) = Shape(x .+ [-0.2,w+0.2,w+0.3,-0.3], y .+ [0,0,h,h])

    center_x = 1 #total == 1 ? 1 : i/(total + 1) * 2
    # println(i)
    # println(total)
    # println(center_x)
    # p = plot(0:2,0:2, linecolor="white")
    if !isnothing(result)
        translated_result = translate_synth_modes_to_real_modes(result)
        all_values = [values(translated_result[apparatus_id])...]
        if length(unique(all_values)) == 1 
            prob = round(1/length(all_values), digits=2)
        elseif translated_result[apparatus_id][option] == necessary 
            prob = 1.0
        else
            prob = 0.0
        end
    end

    if option.direction == left 
        # println("left")
        xs = collect((center_x - 0.3):0.1:center_x)
        ys = collect(0.5:0.25:1.25)
        if !isnothing(result)
            label = label_abbrevs[repr(result[apparatus_id][option])]
            annotate!.(center_x - 0.5, 0.25, text.(label, :black, 6) )
            if show_probs 
                annotate!.(center_x - 0.3, 0, text.(string(prob), :green, 6))
            end
        end
    elseif option.direction == right 
        # println("right")
        xs = collect(center_x:0.1:(center_x+0.3))
        ys = collect(1.25:-0.25:0.5)
        if !isnothing(result)
            label = label_abbrevs[repr(result[apparatus_id][option])]
            annotate!.(center_x + 0.5, 0.25, text.(label, :black, 6) )
            if show_probs 
                annotate!.(center_x + 0.3, 0, text.(string(prob), :green, 6))        
            end
        end
    elseif option.direction == center 
        # println("center")
        xs = center_x .* collect(1:4)
        ys = collect(0.5:0.25:1.25)
        if !isnothing(result)
            label = label_abbrevs[repr(result[apparatus_id][option])]
            annotate!.(center_x, 0.25, text.(label, :black, 6) )
            if show_probs 
                annotate!.(center_x, 0, text.(string(prob), :green, 6))
            end
        end
    end
    # println(xs)
    c = option.disabled ? "red" : "black"
    p = plot!(p, xs, ys, grid=false, axis=([], false), legend=false, size=(150, 150), color=c, lw=3)

    p = plot!(p, [1, 1], [1.25, 1.75], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=3)

    return p
end

function visualize_option(p, option::Arm, i, total, apparatus_id, result=nothing; show_probs=true)
    rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    trapezoid(w, h, x, y) = Shape(x .+ [-0.2,w+0.2,w+0.3,-0.3], y .+ [0,0,h,h])

    center_x = 0.5 #total == 1 ? 1 : i/(total + 1) * 2
    # println(i)
    # println(total)
    # println(center_x)
    # p = plot(0:2,0:2, linecolor="white")
    if !isnothing(result)
        translated_result = translate_synth_modes_to_real_modes(result)
        all_values = [values(translated_result[apparatus_id])...]
        if length(unique(all_values)) == 1 
            prob = round(1/length(all_values), digits=2)
        elseif translated_result[apparatus_id][option] == necessary 
            prob = 1/length(filter(x -> x == necessary, all_values))
        elseif translated_result[apparatus_id][option] == impossible
            prob = 0.0
        elseif translated_result[apparatus_id][option] == possible 
            prob = 1/length(filter(x -> x == possible, all_values))
        end
    end

    if !option.disabled
        if option.direction == left 
            # println("left")
            xs = collect((center_x - 0.3):0.1:center_x)
            ys = collect(0.5:0.25:1.25)
            if !isnothing(result)
                label = label_abbrevs[repr(result[apparatus_id][option])]
                annotate!.(center_x - 0.3, 0.25, text.(label, :black, 3) )
                if show_probs 
                    annotate!.(center_x - 0.3, 0, text.(string(prob), :green, 3))
                end
            end
        elseif option.direction == right 
            # println("right")
            xs = collect(center_x:0.1:(center_x+0.3))
            ys = collect(1.25:-0.25:0.5)
            if !isnothing(result)
                label = label_abbrevs[repr(result[apparatus_id][option])]
                annotate!.(center_x + 0.3, 0.25, text.(label, :black, 3) )
                if show_probs 
                    annotate!.(center_x + 0.3, 0, text.(string(prob), :green, 3))        
                end
            end
        end
    else
        # println("center")
        xs = collect((center_x + 0.3 * 3):0.1:(center_x + 0.3 * 4))
        ys = collect(0.5:0.25:1.25)
        if !isnothing(result)
            label = label_abbrevs[repr(result[apparatus_id][option])]
            annotate!.(center_x + 0.3 * 3, 0.25, text.(label, :black, 3) )
            if show_probs 
                annotate!.(center_x + 0.3 * 3, 0, text.(string(prob), :green, 3))
            end
        end
    end
    # println(xs)
    c = option.disabled ? "red" : "black"
    p = plot!(p, xs, ys, grid=false, axis=([], false), legend=false, size=(150, 150), color=c, lw=3)

    p = plot!(p, [center_x, center_x], [1.25, 1.9], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=3)
    p = plot!(p, [center_x + 0.3 * 4, center_x + 0.3 * 4], [1.25, 1.9], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=3)
    p = plot!(p, [center_x, center_x + 0.3 * 4], [1.9, 1.9], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=3)

    return p
end

function translate_synth_modes_to_real_modes(result_)
    result = deepcopy(result_)
    for id in keys(result)
        for o in keys(result[id])
            synth_mode = result[id][o]
            if synth_mode == mode1 
                result[id][o] = necessary
            elseif synth_mode == mode2 
                result[id][o] = impossible
            elseif synth_mode == mode3 
                result[id][o] = possible
            end
        end
    end
    result
end

# trapezoid(w, h, x, y) = Shape(x .+ [-0.25,w+0.25,w+0.4,-0.4], y .+ [0,0,h,h])
# p = plot(0:2,0:2, linecolor="white")
# p = plot!(p, trapezoid(0, 1, 1, 0.5), opacity=.5, grid=false, axis=([], false), legend=false, size=(150, 150), color="white", fillcolor="blue")
# p = plot!(p, circle_shape(2.5, 2.5, 1), grid=false, axis=([], false), legend=false, size=(150, 150), c="green", seriestype=[:shape,], fill_alpha=0.8)

# p = plot(0:3,0:3, linecolor="white")
# p = plot!(p, trapezoid(0, 1, 1.5, 1), opacity=.5, grid=false, axis=([], false), legend=false, size=(150, 150), color="white", fillcolor="blue")
