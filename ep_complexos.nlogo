globals
[
  nb-infected-previous ;; Number of infected people at the previous tick
  city                 ;; The patches representing the grey city
  forest               ;; The patches representing the grey city
  angle                ;; Heading for individuals
  beta-n               ;; The average number of new secondary infections per infected this tick
  gamma                ;; The average number of new recoveries per infected this tick
  r0                   ;; The number of secondary infections that arise due to a single infective introduced in a wholly susceptible population
  max-infection-length
  immunity-length
]

turtles-own
[
  infected?                 ;; If true, the person is infected.
  infected-forever?
  immunity?
  immunity-remaining
  turtle-type               ;; Which type a turtle is, people or animal.
  human-infect-probability
  animal-infect-probability
  infection-length
]

;;TO-DO - CITY EXPANDING
patches-own
[
  changed
]

;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  setup-globals
  setup-people
  reset-ticks
end

to setup-globals

  ;;;set max-infection-length 24 * 7
  set max-infection-length 24 * max-infection-length-days
  ;;;set immunity-length 24 * 14
  set immunity-length 24 * immunity-length-days

  set city patches with [member? patch pxcor pycor get-initial-city initial-city-radius]
  ask city [ set pcolor gray ]

  set forest patches with [not member? patch pxcor pycor get-initial-city initial-city-radius]
  ask forest [ set pcolor green ]

  ask patches [ set changed false ]
end

to-report get-initial-city [radius]
  let patchesList []
  ask patch max-pxcor max-pycor
  [
    ask patches in-radius radius
    [
      set patchesList lput patch pxcor pycor patchesList
    ]
  ]

  report patchesList
end

;; TODO fazer a movimentação

;; Create initial-people number of people.
;; Those that live on the left are squares; those on the right, circles.
to setup-people
  create-turtles initial-people
    [ let random-patch one-of city
      setxy [pxcor] of random-patch [pycor] of random-patch
      set turtle-type "person"
      set infected? false
      set infected-forever? false
      set immunity? false
      set shape "person"

      set human-infect-probability human-probability-to-infect-human
      set animal-infect-probability human-probability-to-infect-animal
      set infection-length 0

      assign-color
      ]

  create-turtles initial-animals
    [ let random-patch one-of forest
      setxy [pxcor] of random-patch [pycor] of random-patch
      set turtle-type "animal"
      set infected? false
      set infected-forever? false
      set immunity? false
      set shape "cow"

      set human-infect-probability animal-probability-to-infect-human
      set animal-infect-probability animal-probability-to-infect-animal
      set infection-length 0

      if (random-float 1 < initial-animals-infected)
      [
        set infected? true
        set infected-forever? true
      ]

      assign-color
      ]
end

;; red is an infected person
;; white is not infected
to assign-color ;; turtle procedure
  ifelse turtle-type = "person"
  [set color white]
  [set color black]
  if infected?
  [set color red]
end


;;;
;;; GO PROCEDURES
;;;

to go

  ;;if all? turtles [ not infected? ]
  ;;[ stop ]

  ask turtles [ move ]

  ask turtles [
    ifelse immunity-remaining > 0
    [set immunity-remaining (immunity-remaining - 1)]
    [set immunity? false]
  ]
  ask turtles [ if infected? [ recover ]]

  ask turtles [if infected? [ set infection-length (infection-length + 1) ]]
  ask turtles [ if infected? [ infect ] ]

  ask turtles[ assign-color]

  tick
end



to draw-city
  let currPatch patch (round mouse-xcor) (round mouse-ycor)
  if mouse-down? [
    ask currPatch [
      if not changed [

        if member? self forest [
          set pcolor gray
        ]

        ask neighbors4 [
            set changed false
          ]

        set city patches with[pcolor = gray]
        set forest patches with[pcolor = green]

        set changed true
      ]
    ]
  ]

end

to draw-forest
  let currPatch patch (round mouse-xcor) (round mouse-ycor)
  if mouse-down? [
    ask currPatch [
      if not changed [

        if member? self city [
          set pcolor green
        ]

        ask neighbors4 [
          set changed false
        ]
        set city patches with[pcolor = gray]
        set forest patches with[pcolor = green]

        set changed true
      ]
    ]
  ]

end

to move  ;; turtle procedure
  if turtle-type = "person"
  [
    if member? patch-here city ;; and on city patch
    [
      set angle random-float 360
      let new-patch patch-at-heading-and-distance angle 1
      if new-patch != nobody and member? new-patch city
      [
        move-to new-patch
      ]
    ]
    if member? patch-here forest ;; and on city patch
    [
      set angle random-float 360
      let new-patch patch-at-heading-and-distance angle 1
      if new-patch != nobody and member? new-patch city
      [
        move-to new-patch
      ]
    ]
  ]

  if turtle-type = "animal"
  [ ;; in forest
    ifelse member? patch-here city  ;; and on city patch
    [
      set angle random-float 360
      let new-patch patch-at-heading-and-distance angle 1
      if new-patch != nobody and not member? new-patch city
      [
        move-to new-patch
      ]
    ]
    [
      set angle random-float 360
      let new-patch patch-at-heading-and-distance angle 1
      if new-patch != nobody and not member? new-patch city
      [
        move-to new-patch
      ]
    ]
  ]
end

;; Infected individuals who are not isolated or hospitalized have a chance of transmitting their disease to their susceptible neighbors.
;; If the neighbor is linked, then the chance of disease transmission doubles.
to infect  ;; turtle procedure

    let caller self

    let nearby-uninfected (turtles-on neighbors)
    with [ not infected? ]
    if nearby-uninfected != nobody
    [
       ask nearby-uninfected
       [
           if not immunity?
           [
             ifelse turtle-type = "person"
             [
               if (random-float 1 < [human-infect-probability] of caller) ;; twice as likely to infect a linked person
               [
                 set infected? true
                 set infection-length 0
               ]
             ]
             [
               if (random-float 1 < [animal-infect-probability] of caller)
               [
                 set infected? true
                 set infection-length 0
               ]
             ]
          ]
       ]
    ]

end

to recover
  if infection-length = max-infection-length and not infected-forever?
  [
    set infected? false
    set immunity? true
    set immunity-remaining immunity-length
  ]
end

; Copyright 2011 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
640
25
1128
514
-1
-1
19.2
1
10
1
1
1
0
0
0
1
-12
12
-12
12
0
0
1
hours
30.0

BUTTON
365
315
448
348
setup
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
480
315
563
348
go
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
15
65
290
98
initial-people
initial-people
1
100
60.0
1
1
NIL
HORIZONTAL

PLOT
15
520
1130
663
Populations
hours
% people
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Infected" 1.0 0 -2674135 true "" "plot ((count turtles with [ (infected? and turtle-type = \"person\")]) / (initial-people)) * 100 "
"Not Infected" 1.0 0 -10899396 true "" "plot ((count turtles with [ not infected? and turtle-type = \"person\"]) / (initial-people)) * 100 "

SLIDER
310
65
585
98
initial-animals
initial-animals
1
100
9.0
1
1
NIL
HORIZONTAL

SLIDER
15
310
290
343
initial-city-radius
initial-city-radius
0
30
17.0
0.5
1
NIL
HORIZONTAL

SLIDER
15
100
290
133
human-probability-to-infect-human
human-probability-to-infect-human
0
1
0.12
0.01
1
NIL
HORIZONTAL

SLIDER
310
100
585
133
animal-probability-to-infect-human
animal-probability-to-infect-human
0
1
0.08
0.01
1
NIL
HORIZONTAL

SLIDER
310
135
585
168
animal-probability-to-infect-animal
animal-probability-to-infect-animal
0
1
0.09
0.01
1
NIL
HORIZONTAL

SLIDER
15
135
290
168
human-probability-to-infect-animal
human-probability-to-infect-animal
0
1
0.13
0.01
1
NIL
HORIZONTAL

SLIDER
15
220
290
253
max-infection-length-days
max-infection-length-days
1
120
7.0
1
1
NIL
HORIZONTAL

SLIDER
310
220
585
253
immunity-length-days
immunity-length-days
1
120
21.0
1
1
NIL
HORIZONTAL

TEXTBOX
20
25
170
51
Human
24
0.0
1

TEXTBOX
315
30
465
56
Animal
24
0.0
1

TEXTBOX
20
185
170
211
Infection
24
0.0
1

TEXTBOX
15
275
165
301
City
24
0.0
1

TEXTBOX
15
480
165
506
Graphs
24
0.0
1

PLOT
15
675
1130
825
Animals
hours
% animals
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"Infected" 1.0 0 -8053223 true "" "plot (count turtles with [ (infected? and turtle-type = \"animal\")]  / (initial-animals)) * 100 "
"Not Infected" 1.0 0 -15040220 true "" "plot (count turtles with [ (not infected? and turtle-type = \"animal\")] / (initial-animals)) * 100 "

SLIDER
310
175
585
208
initial-animals-infected
initial-animals-infected
0
1
0.4
0.01
1
NIL
HORIZONTAL

BUTTON
480
370
565
403
draw city
draw-city
T
1
T
PATCH
NIL
NIL
NIL
NIL
1

BUTTON
365
370
450
403
draw forest
draw-forest
T
1
T
PATCH
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model is an extension of the basic model of epiDEM (a curricular unit which stands for Epidemiology: Understanding Disease Dynamics and Emergence through Modeling). It simulates the spread of an infectious disease in a semi-closed population, but with additional features such as travel, isolation, quarantine, inoculation, and links between individuals. However, we still assume that the virus does not mutate, and that upon recovery, an individual will have perfect immunity.

Overall, this model helps users:
1) understand the emergent disease spread dynamics in relation to the changes in control measures, travel, and mobility
2) understand how the reproduction number, R_0, represents the threshold for an epidemic
3) understand the relationship between derivatives and integrals, represented simply as rates and cumulative number of cases, and
4) provide opportunities to extend or change the model to include some properties of a disease that interest users the most.

## HOW IT WORKS

Individuals wander around the world in random motion. There are two groups of individuals, represented as either squares or circles, and are geographically divided by the yellow border. Upon coming into contact with an infected person, he or she has a chance of contracting the illness. Depending on their tendencies, which are set by the user, sick individuals will either isolate themselves at "home," go to a hospital, be force-quarantined into a hospital by health officials, or just move about. An infected individual has a chance of recovery after the given recovery time has elapsed.

The presence of the virus in the population is represented by the colors of individuals. Four colors are used: white individuals are uninfected, red individuals are infected, green individuals are recovered, and blue individuals are inoculated. Once recovered, the individual is permanently immune to the virus. The yellow person symbolizes the health official or ambulance, who patrols the world in search of ill people. Once coming in contact with an infected individual, the ambulance immediately delivers the infected to the hospital within the region of residence.

The graph INFECTION AND RECOVERY RATES shows the rate of change of the cumulative infected and recovered in the population. It tracks the average number of secondary infections and recoveries per tick. The reproduction number is calculated under different assumptions than those of the KM model, as we allow for more than one infected individual in the population, and introduce aforementioned variables.

At the end of the simulation, the R_0 reflects the estimate of the reproduction number, the final size relation that indicates whether there will be (or there was, in the model sense) an epidemic. This again closely follows the mathematical derivation that R_0 = beta*S(0)/ gamma = N*ln(S(0) / S(t)) / (N - S(t)), where N is the total population, S(0) is the initial number of susceptibles, and S(t) is the total number of susceptibles at time t. In this model, the R_0 estimate is the number of secondary infections that arise for an average infected individual over the course of the person's infected period.

## HOW TO USE IT

The SETUP button creates individuals according to the parameter values chosen by the user. Each individual has a 5% chance of being initialized as infected. Once the simulation has been setup, push the GO button to run the model. GO starts the simulation and runs it continuously until GO is pushed again.

Each time-step can be considered to be in hours, although any suitable time unit will do.

What follows is a summary of the sliders in the model.

INITIAL-PEOPLE (initialized to vary between 50 - 400): The total number of individuals the simulation begins with.
INFECTION-CHANCE (10 - 50): Probability of disease transmission from one individual to another.
RECOVERY-CHANCE (10 - 100): Probability of an individual's recovery once the infection has lasted longer than the person's recovery time.
AVERAGE-RECOVERY-TIME (50 - 300): Time it takes for an individual to recover, on average. The actual individual's recovery time is pulled from a normal distribution centered around the AVERAGE-RECOVERY-TIME at its mean, with a standard deviation of a quarter of the AVERAGE-RECOVERY-TIME. Each time-step can be considered to be in hours, although any suitable time unit will do.
AVERAGE-ISOLATION-TENDENCY (0 - 50): Average tendency of individuals to isolate themselves and will not spread the disease. Once an infected person is identified as an "isolator," the individual will isolate himself in the current location (as indicated by the grey patch) and will stay there until full recovery.
AVERAGE-HOSPITAL-GOING-TENDENCY (0 - 50): Average tendency of individuals to go to a hospital when sick. If an infected person is identified as a "hospital goer," then he or she will go to the hospital, and will recover in half the time of an average recovery period, due to better medication and rest.
INITIAL-AMBULANCE (0 - 4): Number of health officials or ambulances that move about at random, and force-quarantine sick individuals upon contact. The health officials are immune to the disease, and they themselves do not physically accompany the patient to the hospital. They move at a speed 5 times as fast as other individuals in the world and are not bounded by geographic region.
INOCULATION-CHANCE (0 - 50): Probability of an individual getting vaccinated, and hence immune from the virus.
INTRA-MOBILITY (0 - 1): This indicates how "mobile" an individual is. Usually, an individual at each time step moves by a distance 1. In this model, the person will move at a distance indicated by the INTRA-MOBILITY at each time-step. Thus, the lower the intra-mobility level, the less the movement in the individuals. Individuals move randomly by this assigned value; ambulances always move 5 times faster than this assigned value.

In addition, there are two switches, and a related slider:

LINKS? : When ON, there will be links randomly assigned between people, and the disease will spread twice as fast to those that the infected person is linked with as to the others. When OFF, the disease spreads with an equal chance to those around the infected person.
TRAVEL? : When ON, people from the two regions (separated by the yellow border in the middle) are allowed to migrate and mix. When OFF, the people stay in the region in which they live.
TRAVEL-TENDENCY (0 - 1): When TRAVEL? is ON, this slider indicates the probability of an individual to be traveling at each tick. The 1 indicates a 1 percent chance of travel per tick.

A number of graphs are also plotted in this model.

CUMULATIVE INFECTED AND RECOVERED: This plots the total percentage of individuals who have ever been infected or recovered.
POPULATIONS: This plots the number of people with or without the disease.
INFECTION AND RECOVERY RATES: This plots the estimated rates at which the disease is spreading. BetaN is the rate at which the cumulative infected changes, and Gamma rate at which the cumulative recovered changes.
R_0: This is an estimate of the reproduction number.

## THINGS TO NOTICE

As with many epidemiological models, the number of people becoming infected over time, in the event of an epidemic, traces out an "S-curve." It is called an S-curve because it is shaped like a sideways S. By changing the values of the parameters using the slider, try to see what kinds of changes make the S curve stretch or shrink.

Whenever there's a spread of the disease that reaches most of the population, we say that there was an epidemic. The reproduction number serves as an indicator for the likeliness of an epidemic to occur, if it is greater than 1. If it is smaller than 1, then it is likely that the disease spread will stop short, and we call this an endemic.

Notice how the introduction of various human behaviors, such as travel, inoculation, isolation and quarantine, help constrain the spread of the disease, and what changes that brings to the population level in terms of rate and time taken of disease spread, as well as the population affected.

## THINGS TO TRY

Compare this model with the epiDEM basic model. Do the added complexities significantly change the disease spread? What kinds of changes bring about interesting outcomes?

Notice the difference in dynamics when the travel chooser is on versus off. What happens to the population and the disease spread in both cases?

Does the disease spread change when the link chooser is on? What about when you increase the number of ambulances? What happens to the number of people infected?

Based on this model, what are some strategies or preventive measures that you think are important to undertake on the onset of a disease outbreak? Are there some that are more effective than others? Why might that be? What combinations work well? Are there some measures that seem redundant?

## EXTENDING THE MODEL

Are there other ways to change the behavior of the people once they are infected? Try to think about how you would introduce such a variable.

In this model, we introduce an option for travel, so that there is mixing between two otherwise closed populations. What happens when you introduce births and deaths to each region or just one?

What would happen when the virus mutates? How will that change the population dynamic and disease spread?

What would happen if the population had a mix of healthy and less healthy people, so as to have differing levels of susceptibility?

## NETLOGO FEATURES

Notice that each agent pulls from a truncated normal distribution, centered around the AVERAGE-RECOVERY-TIME set by the user, to determine its recovery-time. This is to account for the variation in genetic differences and the immune system functions of individuals. Similarly, an individual's isolation-tendency and hospital-going-tendency are pulled from truncated normal distributions centered around AVERAGE-ISOLATION-TENDENCY and AVERAGE-HOSPITAL-GOING-TENDENCY respectively.

Notice that R_0 calculated in this model is a numerical estimate to the analytic R_0. In the special case of one infective introduced to a wholly susceptible population (i.e., the Kermack-McKendrick assumptions), the numerical estimations of R_0 are very close to the analytic values. With added complexity in the models, such as the introduction of travel and control measures, the analytic R_0 becomes harder to derive. The numerical estimation is therefore a crude measure of what the actual R_0 might be.

In addition to travel and control measures, notice that this model introduces links amongst individuals and the individual's mobility, which also affect the dynamics of the disease transmission.

## RELATED MODELS

epiDEM basic, HIV, Virus and Virus on a Network are related models.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Yang, C. and Wilensky, U. (2011).  NetLogo epiDEM Travel and Control model.  http://ccl.northwestern.edu/netlogo/models/epiDEMTravelandControl.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2011 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

<!-- 2011 Cite: Yang, C. -->
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

person lefty
false
0
Circle -7500403 true true 170 5 80
Polygon -7500403 true true 165 90 180 195 150 285 165 300 195 300 210 225 225 300 255 300 270 285 240 195 255 90
Rectangle -7500403 true true 187 79 232 94
Polygon -7500403 true true 255 90 300 150 285 180 225 105
Polygon -7500403 true true 165 90 120 150 135 180 195 105

person righty
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105

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
NetLogo 6.1.1
@#$#@#$#@
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
1
@#$#@#$#@
