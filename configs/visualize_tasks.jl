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
    
    num_cushions_dict = nothing
    compound_plot = nothing
    for i in 1:length(task.apparatuses)
        apparatus = task.apparatuses[i]
        if apparatus.options[1] isa PlinkoPath && length(task.apparatuses) > 1
            compound_plot, num_cushions_dict = visualize_apparatus(compound_plot, apparatus, i, task.name, 1, result, show_probs=show_probs, old_num_cushions_dict=num_cushions_dict)
        else
            p, _ = visualize_apparatus(nothing, apparatus, i, task.name, task.agent_choices, result, show_probs=show_probs)
            push!(apparatus_plots, p)
        end
    end

    if !isnothing(compound_plot)
        push!(apparatus_plots, compound_plot)
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
        elseif option isa PlinkoPath 
            
            prob = 1.0
            for apparatus in task.apparatuses 
                num_cushions = occursin("two_deterministic", task.name) ? 1 : task.agent_choices
                necessary_options = filter(o -> result[apparatus.id][o] in [necessary, mode1], apparatus.options)
                undisabled_options = filter(o -> !o.disabled, apparatus.options)
                if length(necessary_options) > 0 
                    if length(necessary_options) > length(undisabled_options) # chance on deterministic or chancy
                        if length(undisabled_options) == 1 # deterministic
                            if num_cushions == 1 
                                prob = prob * 1/length(necessary_options) * sqrt(2)
                            else # num_cushions == 2
                                prob = 1 - (1 - 1/length(necessary_options))^2
                            end
                        else
                            prob = 1.0 * 2/length(necessary_options) * 1/length(necessary_options) + 0.5 * 2 * (1/length(necessary_options))^2
                        end
                    elseif length(necessary_options) < length(undisabled_options) # minimal on chancy
                        prob = prob * 0.5
                    end
                end
            end
            push!(overall_probs, prob)

        end
        overall_prob = sum(overall_probs)
    end

    if !isnothing(overall_prob)
        p = plot(apparatus_plots..., layout = (1, length(apparatus_plots)),size=(150*length(apparatus_plots),150))
        if show_title 
            p = plot(p, plot_title="overall success prob: $(round(overall_prob, digits=3))", plot_titlefont=font(6,"sans-serif"))
        end
    else
        p = plot(apparatus_plots..., layout = (1, length(apparatus_plots)),size=(150*length(apparatus_plots),150))
    end

    if save_filename != ""
        savefig(p, "$(save_filename)")
    end

    return p
end

function visualize_apparatus(compound_plot, apparatus::Apparatus, apparatus_idx, task_name, task_agent_choices, result=nothing; show_probs=true, old_num_cushions_dict=nothing)
    # @show task_agent_choices
    # println("visualize_apparatus")
    # set up grid
    if !isnothing(compound_plot)
        p = compound_plot
    else
        p = plot(0:2,0:2, linecolor="white")
    end

    # for plinko experiment, identify cushion options
    num_cushions_dict = Dict(map(o -> o => 0, apparatus.options))
    if !isnothing(result) && apparatus.options[1] isa PlinkoPath 
        necessary_options = filter(o -> result[apparatus.id][o] in [necessary, mode1], apparatus.options)
        if length(necessary_options) > 0 
            for i in 1:task_agent_choices
                o = sample(necessary_options)
                num_cushions_dict[o] += 1
            end
        else
            possible_options = filter(o -> result[apparatus.id][o] in [possible, mode3], apparatus.options)
            for o in possible_options 
                num_cushions_dict[o] = 1
            end
        end

    end

    for i in 1:length(apparatus.options)
        option = apparatus.options[i] 
        if !isnothing(old_num_cushions_dict)
            matching_option = filter(x -> x.position == option.position, [keys(old_num_cushions_dict)...])[1]
            if old_num_cushions_dict[matching_option] > 0 
                double_cushion = true
            else
                double_cushion = false
            end
        else
            double_cushion = false
        end
        p = visualize_option(p, option, i, length(apparatus.options), apparatus.id, apparatus_idx, task_name, result, show_probs=show_probs, cushions=num_cushions_dict[option], double_cushion=double_cushion)
    end

    return p, num_cushions_dict
end

label_colors = Dict(["necessary" => "green", "possible" => "orange", "impossible" => "red", "mode1" => "black", "mode2" => "black", "mode3" => "black"])
label_abbrevs = Dict(["necessary" => "nec.", "possible" => "pos.", "impossible" => "imp.", "mode1" => "mode1", "mode2" => "mode2", "mode3" => "mode3"])
label_pretty = Dict(["necessary" => "necessary", "possible" => "possible", "impossible" => "impossible", "mode1" => "mode1", "mode2" => "mode2", "mode3" => "mode3"])

function visualize_option(p, option::Cup, i, total, apparatus_id, apparatus_idx, task_name, result=nothing; show_probs=true, cushions=0, double_cushion=false)
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
        label = label_pretty[repr(result[apparatus_id][option])]
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

function visualize_option(p, option::Gumball, i, total, apparatus_id, apparatus_idx, task_name, result=nothing; show_probs=true, cushions=0, double_cushion=false)
    center_x = total == 1 ? 1 : i == total ? i/(total + 1) * 2 + 0.10 : i/(total + 1) * 2 - 0.10 
    # println(i)
    # println(total)
    # println(center_x)

    c = option.disabled ? "red" : "black"
    p = plot!(p, circle_shape(1, 1.15, 0.75), grid=false, axis=([], false), legend=false, size=(150, 150), c=c)
    p = plot!(p, circle_shape(center_x, 0.7, 0.1), grid=false, axis=([], false), legend=false, size=(150, 150), c=repr(option.color), seriestype=[:shape,], fill_alpha=0.8)

    if !isnothing(result)
        label = label_pretty[repr(result[apparatus_id][option])]
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

function visualize_option(p, option::Path, i, total, apparatus_id, apparatus_idx, task_name, result=nothing; show_probs=true, cushions=0, double_cushion=false)
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
            label = label_pretty[repr(result[apparatus_id][option])]
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
            label = label_pretty[repr(result[apparatus_id][option])]
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
            label = label_pretty[repr(result[apparatus_id][option])]
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

function visualize_option(p, option::Arm, i, total, apparatus_id, apparatus_idx, task_name, result=nothing; show_probs=true, cushions=0, double_cushion=false)
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
                label = label_pretty[repr(result[apparatus_id][option])]
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
                label = label_pretty[repr(result[apparatus_id][option])]
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
            label = label_pretty[repr(result[apparatus_id][option])]
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

function visualize_option(p, option::PlinkoPath, i, total, apparatus_id, apparatus_idx, task_name, result=nothing; show_probs=true, cushions=0, double_cushion=false)

    cup_width = (2 - 0.1) / total
    left_boundary_x = cup_width * (i - 1) + 0.05
    right_boundary_x = cup_width * i + 0.05
    center_x = (left_boundary_x + right_boundary_x)/2

    trapezoid(w, h, x, y) = Shape(x .+ [-cup_width*0.2,w+cup_width*0.2,w+cup_width*0.35,-cup_width*0.35], y .+ [0,0,h,h])

    if apparatus_idx == 1 
        # left boundary 
        p = plot!(p, [left_boundary_x, left_boundary_x], [0.5, 1.25], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=3)
        # right boundary
        p = plot!(p, [right_boundary_x, right_boundary_x], [0.5, 1.25], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=3)
        # bottom boundary
        p = plot!(p, [left_boundary_x, right_boundary_x], [0.5, 0.5], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=3)
            
    end

    if occursin("distance_chancy", task_name)
        if !option.disabled
            if i == total 
                p = plot!(p, [center_x - cup_width*0.3, center_x - cup_width*0.3], [0.55, 1.3], grid=false, axis=([], false), legend=false, size=(150, 150), color="blue", lw=1, linestyle=:dot)
            else
                p = plot!(p, [center_x + cup_width*0.3, center_x + cup_width*0.3], [0.55, 1.3], grid=false, axis=([], false), legend=false, size=(150, 150), color="blue", lw=1, linestyle=:dot)
            end
        end
    else
        if !option.disabled
            p = plot!(p, [center_x, center_x], [0.55, 1.3], grid=false, axis=([], false), legend=false, size=(150, 150), color="blue", lw=1, linestyle=:dot)
        end
    end

    if occursin("one_deterministic", task_name)
        if !option.disabled 

            # bottom 
            p = plot!(p, [center_x - cup_width * 0.9, center_x - cup_width * 0.1], [1.35, 1.35], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=1)
            
            # upright
            p = plot!(p, [center_x - cup_width * 0.9, center_x - cup_width * 0.9], [1.35, 1.35 + cup_width * 0.8], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=1)

            # diagonal
            p = plot!(p, [center_x - cup_width * 0.9, center_x - cup_width * 0.1], [1.35 + cup_width * 0.8, 1.35], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=1)

            # ball 
            p = plot!(p, circle_shape(center_x - cup_width * 0.9, 1.35 + cup_width, 0.03), grid=false, axis=([], false), legend=false, size=(150, 150), c="blue", seriestype=[:shape,], fill_alpha=1.0, color="blue", fillcolor="blue")

        end

    elseif occursin("two_deterministic", task_name)
        if !option.disabled
            if i == 1 

                # bottom 
                p = plot!(p, [center_x + cup_width * 0.1, center_x + cup_width * 0.9], [1.35, 1.35], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=1)
                
                # upright
                p = plot!(p, [center_x + cup_width * 0.9, center_x + cup_width * 0.9], [1.35, 1.35 + cup_width * 0.8], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=1)

                # diagonal
                p = plot!(p, [center_x + cup_width * 0.1, center_x + cup_width * 0.9], [1.35, 1.35 + cup_width * 0.8], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=1)

                # ball 
                p = plot!(p, circle_shape(center_x + cup_width * 0.9, 1.35 + cup_width, 0.03), grid=false, axis=([], false), legend=false, size=(150, 150), c="blue", seriestype=[:shape,], fill_alpha=1.0, color="blue", fillcolor="blue")


            else
                # upright 
                p = plot!(p, [center_x, center_x], [0.55, 1.35 + cup_width], grid=false, axis=([], false), legend=false, size=(150, 150), color="blue", lw=1, linestyle=:dot)

                # ball 
                p = plot!(p, circle_shape(center_x, 1.35 + cup_width, 0.03), grid=false, axis=([], false), legend=false, size=(150, 150), c="blue", seriestype=[:shape,], fill_alpha=1.0, color="blue", fillcolor="blue")

            end
        end

    elseif occursin("direction_chancy", task_name)
        if !option.disabled && i == total

            # bottom 
            p = plot!(p, [center_x - cup_width * 0.9, center_x - cup_width * 0.1], [1.35, 1.35], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=1)
            
            # diagonal left
            p = plot!(p, [center_x - cup_width * 0.9, center_x - cup_width * 0.5], [1.35, 1.35 + cup_width * 0.8], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=1)

            # diagonal right
            p = plot!(p, [center_x - cup_width * 0.5, center_x - cup_width * 0.1], [1.35 + cup_width * 0.8, 1.35], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=1)

            # ball 
            p = plot!(p, circle_shape(center_x - cup_width * 0.5, 1.35 + cup_width, 0.03), grid=false, axis=([], false), legend=false, size=(150, 150), c="blue", seriestype=[:shape,], fill_alpha=1.0, color="blue", fillcolor="blue")

        end

    elseif occursin("distance_chancy", task_name)
        if !option.disabled && i == total

            # bottom 
            p = plot!(p, [center_x - cup_width * 1.4, center_x - cup_width * 0.6], [1.35, 1.35], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=1)
            
            # upright
            p = plot!(p, [center_x - cup_width * 1.4, center_x - cup_width * 1.4], [1.35, 1.35 + cup_width * 0.8], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=1)

            # diagonal
            p = plot!(p, [center_x - cup_width * 1.4, center_x - cup_width * 0.6], [1.35 + cup_width * 0.8, 1.35], grid=false, axis=([], false), legend=false, size=(150, 150), color="black", lw=1)

            # ball 
            p = plot!(p, circle_shape(center_x - cup_width * 1.4, 1.35 + cup_width, 0.03), grid=false, axis=([], false), legend=false, size=(150, 150), c="blue", seriestype=[:shape,], fill_alpha=1.0, color="blue", fillcolor="blue")

        end
    end

    # plot cushions 
    # println(cushions)
    for cushion_idx in 1:cushions 
        p = plot!(p, trapezoid(0, 0.05, center_x, 0.45+0.075*(cushion_idx)), opacity=1.0, grid=false, axis=([], false), legend=false, size=(150, 150), color="black", fillcolor="pink")
        p = plot!(p, trapezoid(0, 0.05, center_x, 0.45+0.075*(cushion_idx + (double_cushion ? 1 : 0))), opacity=1.0, grid=false, axis=([], false), legend=false, size=(150, 150), color="black", fillcolor="pink")
    end

    # @show apparatus_idx

    if !isnothing(result)
        label = label_abbrevs[repr(result[apparatus_id][option])]
        label_color = label_colors[repr(result[apparatus_id][option])]

        if apparatus_idx == 1 
            # println("hello 1")
            annotate!.(center_x, 0.3, text.(label, label_color, 3) )
        else 
            # println("hello 2")
            annotate!.(center_x, 0.1, text.(label, label_color, 3) )
        end

        # translated_result = translate_synth_modes_to_real_modes(result)
        # all_values = [values(translated_result[apparatus_id])...]
        # if length(unique(all_values)) == 1 
        #     prob = round(1/length(all_values), digits=2)
        # elseif translated_result[apparatus_id][option] == necessary 
        #     prob = 1.0
        # else
        #     prob = 0.0
        # end

        # if show_probs 
        #     annotate!.(center_x, 0, text.(string(prob), :green, 6) )
        # end
    end

    p
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

function demo_task(task)
    visualize_task(task, Base.invokelatest(infer_distribution, task), show_probs=true, show_title=true)
end

# p = plot(0:2,0:2, linecolor="white")
# p = plot!(p, trapezoid(0, 1, 1, 0.5), opacity=.5, grid=false, axis=([], false), legend=false, size=(150, 150), color="white", fillcolor="blue")
# p = plot!(p, circle_shape(2.5, 2.5, 1), grid=false, axis=([], false), legend=false, size=(150, 150), c="green", seriestype=[:shape,], fill_alpha=0.8)

# p = plot(0:3,0:3, linecolor="white")
# p = plot!(p, trapezoid(0, 1, 1.5, 1), opacity=.5, grid=false, axis=([], false), legend=false, size=(150, 150), color="white", fillcolor="blue")
