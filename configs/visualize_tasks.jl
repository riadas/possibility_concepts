using Plots
include("../language/base_semantics.jl")

function visualize_task(task::Task, result=nothing)
    apparatus_plots = []
    for apparatus in task.apparatuses 
        p = visualize_apparatus(apparatus, result)
        push!(apparatus_plots, p)
    end
    p = plot(apparatus_plots..., layout = (1, length(apparatus_plots)),size=(200*length(task.apparatuses),200))
    return p
end

function visualize_apparatus(apparatus::Apparatus, result=nothing)
    # set up grid
    p = plot(0:2,0:2, linecolor="white")

    for i in 1:length(apparatus.options)
        option = apparatus.options[i] 
        p = visualize_option(p, option, i, length(apparatus.options), apparatus.id, result)
    end

    return p
end

function visualize_option(p, option::Cup, i, total, apparatus_id, result=nothing)
    rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    trapezoid(w, h, x, y) = Shape(x .+ [-0.2,w+0.2,w+0.3,-0.3], y .+ [0,0,h,h])

    center_x = total == 1 ? 1 : i/(total + 1) * 2
    # println(i)
    # println(total)
    # println(center_x)
    # p = plot(0:2,0:2, linecolor="white")
    c = option.disabled ? "red" : "black"
    p = plot!(p, trapezoid(0, 1, center_x, 0.5), opacity=.5, grid=false, axis=([], false), legend=false, size=(200, 200), linecolor=c, fillcolor=repr(option.color))

    if !isnothing(result)
        label = repr(result[apparatus_id][option])
        annotate!.(center_x, 0.2, text.(label, :black, 6) )
    end

    return p
end

function circle_shape(h, k, r)
    theta = LinRange(0, 2*pi, 500)
    h .+ r*sin.(theta), k .+ r*cos.(theta)
end

function visualize_option(p, option::Gumball, i, total, apparatus_id, result=nothing)
    center_x = total == 1 ? 1 : i/(total + 1) * 2
    # println(i)
    # println(total)
    # println(center_x)

    c = option.disabled ? "red" : "black"
    p = plot!(p, circle_shape(1, 1.15, 0.75), grid=false, axis=([], false), legend=false, size=(200, 200), c=c)
    p = plot!(p, circle_shape(center_x, 0.7, 0.1), grid=false, axis=([], false), legend=false, size=(200, 200), c=repr(option.color), seriestype=[:shape,], fill_alpha=0.8)

    if !isnothing(result)
        label = repr(result[apparatus_id][option])
        annotate!.(center_x, 0.3, text.(label, :black, 6) )
    end

    return p
end

function visualize_option(p, option::Path, i, total, apparatus_id, result=nothing)
    rectangle(w, h, x, y) = Shape(x .+ [0,w,w,0], y .+ [0,0,h,h])
    trapezoid(w, h, x, y) = Shape(x .+ [-0.2,w+0.2,w+0.3,-0.3], y .+ [0,0,h,h])

    center_x = 1 #total == 1 ? 1 : i/(total + 1) * 2
    # println(i)
    # println(total)
    # println(center_x)
    # p = plot(0:2,0:2, linecolor="white")
    if option.direction == left 
        # println("left")
        xs = collect((center_x - 0.3):0.1:center_x)
        ys = collect(0.5:0.25:1.25)
        if !isnothing(result)
            label = repr(result[apparatus_id][option])
            annotate!.(center_x - 0.3, 0.25, text.(label, :black, 6) )
        end
    elseif option.direction == right 
        # println("right")
        xs = collect(center_x:0.1:(center_x+0.3))
        ys = collect(1.25:-0.25:0.5)
        if !isnothing(result)
            label = repr(result[apparatus_id][option])
            annotate!.(center_x + 0.3, 0.25, text.(label, :black, 6) )        
        end
    elseif option.direction == center 
        # println("center")
        xs = center_x .* collect(1:4)
        ys = collect(0.5:0.25:1.25)
        if !isnothing(result)
            label = repr(result[apparatus_id][option])
            annotate!.(center_x, 0.25, text.(label, :black, 6) )
        end
    end
    # println(xs)
    c = option.disabled ? "red" : "black"
    p = plot!(p, xs, ys, grid=false, axis=([], false), legend=false, size=(200, 200), color=c, lw=3)

    p = plot!(p, [1, 1], [1.25, 1.75], grid=false, axis=([], false), legend=false, size=(200, 200), color="black", lw=3)

    return p
end

# trapezoid(w, h, x, y) = Shape(x .+ [-0.25,w+0.25,w+0.4,-0.4], y .+ [0,0,h,h])
# p = plot(0:2,0:2, linecolor="white")
# p = plot!(p, trapezoid(0, 1, 1, 0.5), opacity=.5, grid=false, axis=([], false), legend=false, size=(200, 200), color="white", fillcolor="blue")
# p = plot!(p, circle_shape(2.5, 2.5, 1), grid=false, axis=([], false), legend=false, size=(200, 200), c="green", seriestype=[:shape,], fill_alpha=0.8)

# p = plot(0:3,0:3, linecolor="white")
# p = plot!(p, trapezoid(0, 1, 1.5, 1), opacity=.5, grid=false, axis=([], false), legend=false, size=(200, 200), color="white", fillcolor="blue")
