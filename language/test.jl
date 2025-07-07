include("base_semantics.jl")

three_slides_task = NonverbalTask("three_slides", [Apparatus([Path(left), Path(right)]), Apparatus([Path(left)])], false)
four_slides_task = NonverbalTask("four_slides", [Apparatus([Path(left), Path(right)]), Apparatus([Path(left), Path(right, true)])], false)

three_gumballs_task = NonverbalTask("three_gumballs", [Apparatus([Gumball(purple), Gumball(red)]), Apparatus([Gumball(purple)])], true)
four_gumballs_task = NonverbalTask("four_gumballs", [Apparatus([Gumball(orange), Gumball(black)]), Apparatus([Gumball(black), Gumball(black)])], true)

three_cups_task = NonverbalTask("three_cups", [Apparatus([Cup(blue), Cup(yellow)]), Apparatus([Cup(green)])], false)
four_cups_task = NonverbalTask("four_cups", [Apparatus([Cup(blue), Cup(yellow)]), Apparatus([Cup(red), Cup(green, true, true)])], false)

three_arm_task = NonverbalTask("three_arms", [Apparatus([Arm(left), Arm(right), Arm(left, true)])], false)

# new_three_slides_task = nothing # two marbles

# plinko experiments
plinko_one_deterministic_task = NonverbalTask(
    "plinko_one_deterministic",
    [Apparatus([
        PlinkoPath(1, true),
        PlinkoPath(2, true),
        PlinkoPath(3, true),
        PlinkoPath(4, true),
        PlinkoPath(5, true),
        PlinkoPath(6, false),
    ])],
    false,
    2
)

plinko_two_deterministic_task = NonverbalTask(
    "plinko_two_deterministic",
    [Apparatus([
        PlinkoPath(1, false),
        PlinkoPath(2, true),
        PlinkoPath(3, true),
        PlinkoPath(4, true),
        PlinkoPath(5, true),
        PlinkoPath(6, true),
    ]), 
    Apparatus([
        PlinkoPath(1, true),
        PlinkoPath(2, true),
        PlinkoPath(3, true),
        PlinkoPath(4, false),
        PlinkoPath(5, true),
        PlinkoPath(6, true),
    ])],
    false,
    2
)

plinko_one_direction_chancy_task = NonverbalTask(
    "plinko_one_direction_chancy",
    [Apparatus([
        PlinkoPath(1, true),
        PlinkoPath(2, true),
        PlinkoPath(3, true),
        PlinkoPath(4, true),
        PlinkoPath(5, false),
        PlinkoPath(6, false),
    ])],
    false,
    2
)

plinko_one_distance_chancy_task = NonverbalTask(
    "plinko_one_distance_chancy",
    [Apparatus([
        PlinkoPath(1, true),
        PlinkoPath(2, true),
        PlinkoPath(3, true),
        PlinkoPath(4, true),
        PlinkoPath(5, false),
        PlinkoPath(6, false),
    ])],
    false,
    2
)

# verbal tasks 
four_cups_task_verbal_option1_can = VerbalTask(four_cups_task, four_cups_task.apparatuses[1].options[1], true, four_cups_task.apparatuses[1])
four_cups_task_verbal_option1_have_to = VerbalTask(four_cups_task, four_cups_task.apparatuses[1].options[1], false, four_cups_task.apparatuses[1])

four_cups_task_verbal_option2_can = VerbalTask(four_cups_task, four_cups_task.apparatuses[1].options[2], true, four_cups_task.apparatuses[1])
four_cups_task_verbal_option2_have_to = VerbalTask(four_cups_task, four_cups_task.apparatuses[1].options[2], false, four_cups_task.apparatuses[1])

four_cups_task_verbal_option3_can = VerbalTask(four_cups_task, four_cups_task.apparatuses[2].options[1], true, four_cups_task.apparatuses[2])
four_cups_task_verbal_option3_have_to = VerbalTask(four_cups_task, four_cups_task.apparatuses[2].options[1], false, four_cups_task.apparatuses[2])

four_cups_task_verbal_option4_can = VerbalTask(four_cups_task, four_cups_task.apparatuses[2].options[2], true, four_cups_task.apparatuses[2])
four_cups_task_verbal_option4_have_to = VerbalTask(four_cups_task, four_cups_task.apparatuses[2].options[2], false, four_cups_task.apparatuses[2])

tasks = [
    three_cups_task,
    four_cups_task,
    three_slides_task,
    four_slides_task,
    three_gumballs_task,
    four_gumballs_task,
    # three_arm_task,
]

# languages = [
#     "chance_language_no_impossible",
#     "minimal_language_no_impossible",
#     "hybrid_language_no_impossible",
#     "modal_language_no_impossible",
#     "chance_language",
#     "minimal_language",
#     "hybrid_language",
#     "modal_language",
# ]

tasks = [
    plinko_one_deterministic_task,
    plinko_two_deterministic_task,
    plinko_one_direction_chancy_task,
    plinko_one_distance_chancy_task,
]

languages = [
    "chance_language_no_impossible",
    "hybrid_minimal_chance_language",
    "minimal_language",
    "modal_language",
]