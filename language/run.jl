include("configs/visualize_tasks.jl")
include("language/test.jl")

final_plots = []
for language in languages 
    for task in tasks
        include("language/$(language).jl")
        println("LANGUAGE: $(language), TASK: $(task.name)") 
        save_filename = "language/images/$(task.name)_$(language).png"

        # p = visualize_task(task, infer_distribution(task), save_filename=save_filename, show_title=true)
        p = visualize_task(task, Base.invokelatest(infer_distribution, task), show_title=false)
    
        push!(final_plots, p)
        # sleep(1)
    end
end

plot(final_plots..., layout = (8, 6), size = (300 * 6, 150 * 8))
