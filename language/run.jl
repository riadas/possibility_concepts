include("../configs/visualize_tasks.jl")
include("test.jl")

final_plots = []
for language in languages 
    for task in tasks
        include("$(language).jl")
        println("LANGUAGE: $(language), TASK: $(task.name)") 
        save_filename = "language/images/$(task.name)_$(language).png"

        # p = visualize_task(task, infer_distribution(task), save_filename=save_filename, show_title=true)
        p = visualize_task(task, Base.invokelatest(infer_distribution, task), show_title=false)
    
        push!(final_plots, p)
        # sleep(1)
    end
end

# plot(final_plots..., layout = (length(languages), length(tasks)), size = (300 * length(tasks), 150 * length(languages)))
plot(final_plots..., layout = (length(languages), length(tasks)), size = (150 * length(tasks), 150 * length(languages)))
