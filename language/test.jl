include("minimal_language.jl")

three_slides_task = Task([Apparatus([Path(left), Path(right)]), Apparatus([Path(center)])], false)
four_slides_task = Task([Apparatus([Path(left), Path(right)]), Apparatus([Path(left), Path(right, true)])], false)

three_gumballs_task = Task([Apparatus([Gumball(purple), Gumball(red)]), Apparatus([Gumball(purple)])], true)
four_gumballs_task = Task([Apparatus([Gumball(orange), Gumball(black)]), Apparatus([Gumball(black), Gumball(black)])], true)

three_cups_task = Task([Apparatus([Cup(blue), Cup(yellow)]), Apparatus([Cup(green)])], false)
four_cups_task = Task([Apparatus([Cup(blue), Cup(yellow)]), Apparatus([Cup(green), Cup(red, true)])], false)

new_three_slides_task = nothing # two marbles