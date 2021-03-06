;; Circle that represents center of gravity of flockmates
breed [gravitations gravitation]
;; Wharehouses that stock objects
breed [warehouses warehouse]
;; robots which transport objects
breed [robots robot]
;;Fuel stations
breed [stations station]
;;Obstacles
breed [obstacles obstacle]

globals [pickup_on]  ;; bool to know if robots have to transport objects to wharehouses

robots-own [
  flockmates         ;; nearby robots
  colorFlockmates    ;; nearby robots with same color
  patchmates         ;; nearby patch that contains objects
  pickups            ;; nearby wharehouses
  align_var          ;; align vector
  cohere_var         ;; cohere vector
  separate_var       ;; separate vector
  color_obj          ;; color of object that robot is holding, else 0
  choose_one         ;; bool to show center of gravity of flockmate
  gas_tank           ;; quantity of fuel
  gasStations        ;; nearby gas station
  ticks_death        ;; ticks before death
]

;; Patches contains objects
patches-own [
  obj                ;; bool to know if there is an object
]

;;
warehouses-own [
  nb_stored          ;; int for the number of objects stock
]


to setup
  clear-all
  ;; set global variable for wharehousses
  set pickup_on false

  if (gasBool) [
    create-stations gas_station_number [
      set size 3
      setxy random-xcor random-ycor
      set shape "box"
      set color pink
    ]
  ]
  spawn-obstacle

  ;; Create all robots and initiate
  spawn-robots
  ;; initiate patches with no object
  ask patches [
    set obj false
  ]

  ;; create center of gravity for the choosen turtle
  if center_of_gravity [
    ask one-of robots
    [
      set size 3
      set shape "turtle"
      set choose_one true
    ]
    create-gravitations 1
    [
      set color yellow
      set shape "circle"
      setxy  0 0
    ]
  ]

  reset-ticks
end

;; create robots
to spawn-robots
  repeat population [
    let x_robot random-xcor
    let y_robot random-ycor
    let good_place false
    while [not good_place][
      set good_place true
      ask obstacles [
        if ((distancexy x_robot y_robot) < size) [
          set good_place false
          set x_robot random-xcor
          set y_robot random-ycor
        ]

      ]
    ]
    create-robots 1
    [ set color white
      set size 2  ;; easier to see
      setxy x_robot y_robot
      set flockmates no-turtles
      set colorFlockmates no-turtles
      set color_obj black
      set choose_one false
      set gas_tank ((random 2000) + 600)
      set ticks_death 5
    ]
  ]
end

to spawn-obstacle
  repeat obstacle_number [
    let x_obs random-xcor
    let y_obs random-ycor
    let size_obs ((random 5) + 4)
    let good_place false
    while [not good_place][
      set good_place true
      ask turtles[
        if ((distancexy x_obs y_obs) < size_obs)[
          set good_place false
          set x_obs random-xcor
          set y_obs random-ycor
        ]
      ]
    ]
    create-obstacles 1 [
      set size size_obs
      set shape "circle"
      set color grey
      setxy x_obs y_obs
    ]
  ]
end


;; create object of color on patches
to spawn_obj
  let color_list [blue red green magenta orange]
  let i 5
  while [i != differents_objects] [
    set color_list remove-item (i - 1) color_list
    set i (i - 1)
  ]
  ifelse group_objects
  [
    spawn-collection_obj
  ]
  [
    repeat nb_obj [
      ask one-of patches [
        set pcolor one-of color_list
        set obj true
      ]
    ]
  ]
end

;;Create collection of objects
to spawn-collection_obj
  let color_list [blue red green magenta orange]
  let i 5
  while [i != differents_objects] [
    set color_list remove-item (i - 1) color_list
    set i (i - 1)
  ]
  let pos_coll [[[0 0] [-2 -2] [2 2] [-2 2] [2 -2]]
    [[20 20] [18 18] [22 22] [18 22] [22 18]]
    [[-20 -20] [-18 -18] [-22 -22] [-18 -22] [-22 -18]]
    [[-20 20] [-18 18] [-22 22] [-18 22] [-22 18]]
    [[20 -20] [18 -18] [22 -22] [18 -22] [22 -18]]]

  foreach pos_coll [ x ->
    let color_coll one-of color_list
    foreach x [ y ->
      ask patch first(y) last(y) [
        set pcolor color_coll
        set obj true
      ]
    ]
  ]

end


;; create warehouses taht collect objects
to spawn-warehouses
  let color_list [blue red green magenta orange]
  let i 5
  while [i != differents_objects] [
    set color_list remove-item (i - 1) color_list
    set i (i - 1)
  ]
  foreach color_list [ x ->
    let x_ware random-xcor
    let y_ware random-ycor
    let good_place false
    while [not good_place][
      set good_place true
      ask obstacles [
        if ((distancexy x_ware y_ware) < size) [
          set good_place false
          set x_ware random-xcor
          set y_ware random-ycor
        ]

      ]
    ]
    create-warehouses 1 [
        set size 3
        setxy x_ware y_ware
        set shape "house"
        set nb_stored 0
        set color x
      ]
  ]
end

;; Delete all object on the map
to clear_obj
  ask patches [
     set pcolor black
      set obj false
  ]
end

;; main function that make move robots
to go
  ifelse enable_warehouses
  [
    ;;Check if wharehouses are already created
    ifelse pickup_on [
      show pickup_on
    ]
    ;; if not, we create them
    [
      show "spawn warehouses"
      spawn-warehouses
      set pickup_on true
    ]
    ask robots [
      flock_objets
      get_obj_pickups
      get_pickups
      if (gasBool) [
        set gas_tank (gas_tank - 1)
        if (gas_tank < 0) [
          set shape "fire"
          set size 3
          set ticks_death (ticks_death - 1)
          if (ticks_death = 0)[die]
        ]
        if (gas_tank < 600) [
          get_gas
        ]
      ]
    ]
  ][
    ;; we kill wharehouses in case they exist
    set pickup_on false
    ask warehouses [ die ]
    ask robots [
      flock_objets
      get_obj
      if (gasBool) [
        set gas_tank (gas_tank - 1)
        if (gas_tank < 0) [
          set shape "fire"
          set size 3
          set ticks_death (ticks_death - 1)
          if (ticks_death = 0)[die]
        ]
        if (gas_tank < 600) [
          get_gas
        ]
      ]
    ]
  ]
  ask robots [
    let velocity 0.2
    let head (heading + 180)
    let turn false
    ask obstacles [
      if ((distance myself) < ((size / 2) + 1)) [
        set turn true
      ]
    ]
    if turn [set heading head]
    fd velocity
  ]
  tick
end


;; flocking which depends on near objects
to flock_objets  ;; turtle procedure
  find-flockmates
  find-colorFlockmates
  find-patchmates
  find-pickups
  if (gasBool) [
    find-stations
  ]
  if any? flockmates
    [ vector_move_objets ]
end

;; regroup 3 force align, cohere, sperate to create flocking force and give direction to robots
to vector_move_objets
  let found false
  let new_dir (list (0) (0))
  ifelse (color_obj = 0) [
    ask patchmates [
      set new_dir (vector-normalize(list (pxcor - [xcor] of myself) (pycor - [ycor] of myself)))
      set found true
      stop
    ]
  ] [
    ask pickups [
      set new_dir (vector-normalize(list (pxcor - [xcor] of myself) (pycor - [ycor] of myself)))
      set found true
      stop
    ]
  ]

  if (gasBool) and (gas_tank < 600) [
    ask gasStations [
      set new_dir (vector-normalize(list (pxcor - [xcor] of myself) (pycor - [ycor] of myself)))
      set found true
      stop
    ]
  ]

  ifelse found [set align_var new_dir] [
    ifelse any? colorFlockmates [align] [set align_var (list (0) (0))]
  ]
  ifelse any? colorFlockmates [cohere] [set cohere_var (list (0) (0))]
  separate
  let x item 0 align_var * alignmentWeight + item 0 cohere_var * cohesionWeight + item 0 separate_var * separationWeight
  let y item 1 align_var * alignmentWeight + item 1 cohere_var * cohesionWeight + item 1 separate_var * separationWeight
  if x != 0 and y != 0 [
    turn-towards (atan x y) max-align-turn
    ;;set heading (atan 1 1)
  ]
end

;; find near robots
to find-flockmates  ;; turtle procedure
  set flockmates other robots in-radius vision
end

;;find near patch with objects
to find-patchmates  ;; turtle procedure
  set patchmates patches in-radius vision_obj with [(obj = true)]
end

;;find near wharehouse with the color of our object
to find-pickups
  set pickups warehouses in-radius vision_obj with [color = [color_obj] of myself]
end

;; find near robots with same color
to find-colorFlockmates  ;; turtle procedure
  set colorFlockmates other robots in-radius vision with [color = [color] of myself]
end

to find-stations
  set gasStations stations in-radius vision_obj
end

;;; SEPARATE
to separate  ;; turtle procedure
  set separate_var (list (0) (0))
  let vect_curr list (xcor) (ycor)
  let vect_sep (list (0) (0))
  ask flockmates with [ distance myself < minimum-separation and distance myself > 0 ] [
    let d distance myself
    let vect_mate list (xcor) (ycor)
    set vect_sep vector-add (vect_sep) (vector-div (vector-normalize (vector-sub vect_curr vect_mate)) (d))
    if (color != [color] of myself) [
      set vect_sep (vector-mult vect_sep 2)
    ]
  ]
  set separate_var vect_sep
end

;;; ALIGN
to align  ;; turtle procedure
  let x-component mean [cos (90 - heading)] of colorFlockmates
  let y-component mean [sin (90 - heading)] of colorFlockmates
  let norme sqrt (x-component * x-component + y-component * y-component)
  ifelse norme != 0 [
    set align_var (list (x-component / norme) (y-component / norme))
  ]
  [ set align_var [ 0 0 ] ]
  ;;turn-towards average-flockmate-heading max-align-turn
end

;;; COHERE
to cohere  ;; turtle procedure
  let x-component 0
  let y-component 0
  ask colorFlockmates [
    let diffx xcor - [xcor] of myself
    let diffy ycor - [ycor] of myself
    ifelse abs diffx > max-pxcor
    [ ifelse diffx < 0
      [ set x-component x-component + ([xcor] of myself + (2 * max-pxcor + diffx + 1)) ]
      [ set x-component x-component + ([xcor] of myself - (2 * max-pxcor - diffx + 1)) ]
    ]
    [ set x-component x-component + xcor ]
    ifelse abs diffy > max-pycor
    [ ifelse diffy < 0
      [ set y-component y-component + ([ycor] of myself + (2 * max-pycor + diffy + 1)) ]
      [ set y-component y-component + ([ycor] of myself - (2 * max-pycor - diffy + 1)) ]
    ]
    [ set y-component y-component + ycor ]
  ]
  set x-component (x-component / count colorFlockmates)
  set y-component (y-component / count colorFlockmates)
  let diffx1 x-component - xcor
  let diffy1 y-component - ycor
  if abs diffx1 > max-pxcor
    [ ifelse diffx1 < 0
      [ set x-component (xcor + (2 * max-pxcor + diffx1 + 1)) ]
      [ set x-component (xcor - (2 * max-pxcor - diffx1 + 1)) ]
    ]
  if abs diffy1 > max-pycor
    [ ifelse diffy1 < 0
      [ set y-component (ycor + (2 * max-pycor + diffy1 + 1)) ]
      [ set y-component (ycor - (2 * max-pycor - diffy1 + 1)) ]
    ]
  if (breed = robots and [choose_one] of self)
  [
    ask gravitations
    [
      setxy x-component y-component
    ]
  ]


  set x-component x-component - xcor
  set y-component y-component - ycor

  ;let x-component (mean [xcor] of flockmates) - xcor
  ;let y-component (mean [ycor] of flockmates) - ycor
  let norme sqrt (x-component * x-component + y-component * y-component)
   ifelse norme != 0 [
    set cohere_var (list (x-component / norme) (y-component / norme))
  ]
  [ set cohere_var [ 0 0 ] ]
  ;;turn-towards average-heading-towards-flockmates max-cohere-turn
end


;;; HELPER PROCEDURES
to turn-towards [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings new-heading heading) max-turn
end


;; turn right by "turn" degrees (or left if "turn" is negative),
;; but never turn more than "max-turn" degrees
to turn-at-most [turn max-turn]  ;; turtle procedure
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end

;; robot get object and it disapears on patch
to get_obj
  ask patchmates[
    if distance myself < 0.5 [
      set pcolor black
      set obj false
    ]
  ]
end

;; robot get object and it disapears on patch
to get_obj_pickups
  ask patchmates[
    if (distance myself < 0.5) and (0 = [color_obj] of myself) [
      ask myself [
        set color_obj [pcolor] of myself
        set color [pcolor] of myself
      ]
      set pcolor black
      set obj false
    ]
  ]
end

;;warehouses collect given objects if robots are near enough
to get_pickups
  ask pickups[
    if (distance myself < 3) and (color = [color_obj] of myself) [
      set nb_stored (nb_stored + 1)
      ask myself [
        set color_obj black
        set color white
      ]
    ]
  ]
end

to get_gas
  if (599 = gas_tank) [
     set size 1
  ]
  ask gasStations[
    if (distance myself < 3) [
      ask myself [
        set gas_tank (gas_tank + 2000)
        set size 2
      ]
    ]
  ]
end

;;return addition of 2 vectors v1 +v2
to-report vector-add [v1 v2]
  report (list (first v1 + first v2) (last v1 + last v2))
end

;;return substraction of 2 vector v1 -v2
to-report vector-sub [v1 v2]
  let size-x (max-pxcor - min-pxcor)
  let size-y (max-pycor - min-pycor)
  let x (first v1 - first v2)
  let y (last v1 - last v2)
  if abs x > (size-x / 2)
  [ ifelse x > 0
    [ set x (x - size-x) ]
    [ set x (x + size-x) ]
  ]
  if abs y > (size-y / 2)
  [ ifelse y > 0
    [ set y (y - size-y) ]
    [ set y (y + size-y) ]
  ]
  report (list x y)
end

;;return division of vector v by int d
to-report vector-div [v1 d]
  report (list (first v1 / d) (last v1 / d))
end

;;return multiplication of vector v by int d
to-report vector-mult [v1 d]
  report (list (first v1 * d) (last v1 * d))
end

;;retrun normalize vector v1
to-report vector-normalize [v1]
  let norme sqrt (first v1 * first v1 + last v1 * last v1)
  report (list (first v1 / norme) (last v1 / norme))
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
490
10
1053
574
-1
-1
6.852
1
10
1
1
1
0
1
1
1
-40
40
-40
40
1
1
1
ticks
30.0

BUTTON
10
112
123
145
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
128
112
233
145
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
10
10
233
43
population
population
1.0
300
128.0
1.0
1
NIL
HORIZONTAL

SLIDER
11
292
236
325
max-align-turn
max-align-turn
0.0
20.0
10.5
0.25
1
degrees
HORIZONTAL

SLIDER
11
190
236
223
vision
vision
0.0
40
6.0
0.5
1
patches
HORIZONTAL

SLIDER
11
258
236
291
minimum-separation
minimum-separation
0.0
10
5.75
0.25
1
patches
HORIZONTAL

SLIDER
12
354
237
387
alignmentWeight
alignmentWeight
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
12
388
236
421
cohesionWeight
cohesionWeight
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
12
422
237
455
separationWeight
separationWeight
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
11
224
236
257
vision_obj
vision_obj
1
20
12.5
0.5
1
patches
HORIZONTAL

PLOT
1095
10
1469
245
Indice de performance
Ticks
Performance
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "let coef-align 0\nlet coef-neighbour 0\nask robots [\nif count flockmates > 0 [\n  let mean-sin mean [sin heading] of flockmates\n  let mean-cos mean [cos heading] of flockmates\n  set coef-align coef-align + 1 / (1 + abs (heading - (atan mean-sin mean-cos)))\n]\nset coef-neighbour coef-neighbour + (count flockmates) * (count robots in-radius (2 * minimum-separation) - count flockmates)\n]\nset coef-align (coef-align / count robots)\nset coef-neighbour (coef-neighbour / count robots)\nplot coef-align * coef-neighbour"

SLIDER
12
518
237
551
nb_obj
nb_obj
0
200
122.0
1
1
NIL
HORIZONTAL

BUTTON
12
558
118
591
Spawn object
spawn_obj
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
118
558
238
591
Remove objects
clear_obj
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
243
481
468
514
group_objects
group_objects
1
1
-1000

SLIDER
236
10
459
43
gas_station_number
gas_station_number
0
10
0.0
1
1
NIL
HORIZONTAL

SWITCH
10
44
233
77
enable_warehouses
enable_warehouses
1
1
-1000

SWITCH
10
78
233
111
center_of_gravity
center_of_gravity
1
1
-1000

SLIDER
12
481
237
514
differents_objects
differents_objects
1
5
2.0
1
1
NIL
HORIZONTAL

SWITCH
236
44
459
77
gasBool
gasBool
0
1
-1000

BUTTON
10
146
123
179
NIL
clear-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
236
78
459
111
obstacle_number
obstacle_number
0
5
0.0
1
1
NIL
HORIZONTAL

PLOT
1095
251
1469
508
Number of objects remaining
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count (patches with [pcolor != black])"

MONITOR
1100
522
1157
567
Objects
count (patches with [pcolor != black])
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model is an attempt to mimic the flocking of birds.  (The resulting motion also resembles schools of fish.)  The flocks that appear in this model are not created or led in any way by special leader birds.  Rather, each bird is following exactly the same set of rules, from which flocks emerge.

## HOW IT WORKS

The birds follow three rules: "alignment", "separation", and "cohesion".

"Alignment" means that a bird tends to turn so that it is moving in the same direction that nearby birds are moving.

"Separation" means that a bird will turn to avoid another bird which gets too close.

"Cohesion" means that a bird will move towards other nearby birds (unless another bird is too close).

When two birds are too close, the "separation" rule overrides the other two, which are deactivated until the minimum separation is achieved.

The three rules affect only the bird's heading.  Each bird always moves forward at the same constant speed.

## HOW TO USE IT

First, determine the number of birds you want in the simulation and set the POPULATION slider to that value.  Press SETUP to create the birds, and press GO to have them start flying around.

The default settings for the sliders will produce reasonably good flocking behavior.  However, you can play with them to get variations:

Three TURN-ANGLE sliders control the maximum angle a bird can turn as a result of each rule.

VISION is the distance that each bird can see 360 degrees around it.

## THINGS TO NOTICE

Central to the model is the observation that flocks form without a leader.

There are no random numbers used in this model, except to position the birds initially.  The fluid, lifelike behavior of the birds is produced entirely by deterministic rules.

Also, notice that each flock is dynamic.  A flock, once together, is not guaranteed to keep all of its members.  Why do you think this is?

After running the model for a while, all of the birds have approximately the same heading.  Why?

Sometimes a bird breaks away from its flock.  How does this happen?  You may need to slow down the model or run it step by step in order to observe this phenomenon.

## THINGS TO TRY

Play with the sliders to see if you can get tighter flocks, looser flocks, fewer flocks, more flocks, more or less splitting and joining of flocks, more or less rearranging of birds within flocks, etc.

You can turn off a rule entirely by setting that rule's angle slider to zero.  Is one rule by itself enough to produce at least some flocking?  What about two rules?  What's missing from the resulting behavior when you leave out each rule?

Will running the model for a long time produce a static flock?  Or will the birds never settle down to an unchanging formation?  Remember, there are no random numbers used in this model.

## EXTENDING THE MODEL

Currently the birds can "see" all around them.  What happens if birds can only see in front of them?  The `in-cone` primitive can be used for this.

Is there some way to get V-shaped flocks, like migrating geese?

What happens if you put walls around the edges of the world that the birds can't fly into?

Can you get the birds to fly around obstacles in the middle of the world?

What would happen if you gave the birds different velocities?  For example, you could make birds that are not near other birds fly faster to catch up to the flock.  Or, you could simulate the diminished air resistance that birds experience when flying together by making them fly faster when in a group.

Are there other interesting ways you can make the birds different from each other?  There could be random variation in the population, or you could have distinct "species" of bird.

## NETLOGO FEATURES

Notice the need for the `subtract-headings` primitive and special procedure for averaging groups of headings.  Just subtracting the numbers, or averaging the numbers, doesn't give you the results you'd expect, because of the discontinuity where headings wrap back to 0 once they reach 360.

## RELATED MODELS

* Moths
* Flocking Vee Formation
* Flocking - Alternative Visualizations

## CREDITS AND REFERENCES

This model is inspired by the Boids simulation invented by Craig Reynolds.  The algorithm we use here is roughly similar to the original Boids algorithm, but it is not the same.  The exact details of the algorithm tend not to matter very much -- as long as you have alignment, separation, and cohesion, you will usually get flocking behavior resembling that produced by Reynolds' original model.  Information on Boids is available at http://www.red3d.com/cwr/boids/.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1998).  NetLogo Flocking model.  http://ccl.northwestern.edu/netlogo/models/Flocking.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2002.

<!-- 1998 2002 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
set population 200
setup
repeat 200 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
