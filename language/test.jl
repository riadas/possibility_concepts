include("base_semantics.jl")

three_slides_task = Task("three_slides", [Apparatus([Path(left), Path(right)]), Apparatus([Path(left)])], false)
four_slides_task = Task("four_slides", [Apparatus([Path(left), Path(right)]), Apparatus([Path(left), Path(right, true)])], false)

three_gumballs_task = Task("three_gumballs", [Apparatus([Gumball(purple), Gumball(red)]), Apparatus([Gumball(purple)])], true)
four_gumballs_task = Task("four_gumballs", [Apparatus([Gumball(orange), Gumball(black)]), Apparatus([Gumball(black), Gumball(black)])], true)

three_cups_task = Task("three_cups", [Apparatus([Cup(blue), Cup(yellow)]), Apparatus([Cup(green)])], false)
four_cups_task = Task("four_cups", [Apparatus([Cup(blue), Cup(yellow)]), Apparatus([Cup(red), Cup(green, true, true)])], false)

three_arm_task = Task("three_arms", [Apparatus([Arm(left), Arm(right), Arm(left, true)])], false)

# new_three_slides_task = nothing # two marbles

tasks = [
    three_cups_task,
    four_cups_task,
    three_slides_task,
    four_slides_task,
    three_gumballs_task,
    four_gumballs_task,
    # three_arm_task,
]

languages = [
    "chance_language_no_impossible",
    "minimal_language_no_impossible",
    "hybrid_language_no_impossible",
    "modal_language_no_impossible",
    "chance_language",
    "minimal_language",
    "hybrid_language",
    "modal_language",
]