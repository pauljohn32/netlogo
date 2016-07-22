globals
[
  survivalP
  scoutP
  scoutPDie
  burnin
  scoutDistance
  groupSizeList
]


turtles-own
[
  age
  sex
  alpha?
  subordinate?
  IwillScout?
  xstart
  ystart
]


patches-own
[
  hasalpha?
  alpha
]


to setup
  ;random-seed 234234
  ca
  reset-ticks
  set groupSizeList[]
  set survivalP 0.99 ; 99% survival rate
  set scoutDistance 5
  set scoutP 0.5 ;  tendency to scout
  set scoutPDie 0.20 ; prob die while scouting

  create-turtles 100
  [
    set age  1 + random 24
    set shape "square"
    set size 0.35
    set alpha? false

    ifelse (random-float 1 < 0.5)
      [
        set heading 90
      ]
      [
        set heading 270
      ]

    ;; put male on one row, female on other.  simplifies calculations
    setxy (who mod 25) (who mod 2)
    set xstart pxcor ; just for record keeping
    set ystart pycor ; just for record keeping
    ; females in row 0, males in row 1
    ifelse (who mod 2 = 0)
      [
        set sex "female"
        set color red
        set ycor 0
      ]
      [
        set sex "male"
        set color blue
        set ycor 1
      ]
    ; treat all like subordinate, relabel others
    set subordinate? true
    if age <= 12
      [
        set ycor -0.35
        set shape "circle"
        set size 0.2
        set color color + 2 ; younger brighter
        if sex = "male" [set ycor  ycor + 1]
        set subordinate? false
      ]
  ]

  ask patches [
    set hasAlpha? false
    fillAlpha
  ]

  file-close-all
  if file-exists? "WH-out.txt"
  [file-delete "WH-out.txt"]
  file-open "WH-out.txt"

end

; concentrate code that sets agent characteristics here
to becomeAlpha ; turtle method
  set alpha? true
  set subordinate? false
  set shape "default"
  ifelse sex = "female"
  [
    set ycor  0.35
    set color red
  ]
  [
    set ycor  0.35 + 1
    set color blue
  ]
  set size 0.4
  ; tell the patch so as well, but will also do elsewhere to be sure
  set hasAlpha? true
  set alpha self
end

; put subordinates on center row with squares and lighter colors for younger
to becomeSubordinate; turtle method
  set subordinate? true
  set alpha? false
  set shape "square"
  ifelse sex = "female"
  [
    set ycor  0.0
    set xcor pxcor - 0.2 + random-float .4
    ; younger ones lighter until 17
    if age > 16
    [
      set color red
    ]
  ]
  [
    set ycor  0.0 + 1
    if age > 16
      [
        set color blue
      ]
  ]
  set size 0.25
end

; ask patches to conduct check for alphas and promote somebody
; patch method determines leadership
to fillAlpha
  ifelse count turtles-here > 0
    [
      if hasAlpha? [stop]; TODO check if alpha is correct agent

      let oldest max-one-of turtles-here [turtleage]

      ifelse [age] of oldest > 12
       [
         ; patch sets its variable
         set hasalpha? true
         set alpha oldest
         set pcolor 48
         ask oldest
         [
           becomeAlpha
         ]
       ]
       [
         set hasalpha? false
       ]
    ]
  ; else it is a vacant cell
    [
      set hasalpha? false
      set pcolor 93
    ]
end


; turtle method for females
; a female who is an alpha in month divisible by 12 reproduces
; if there is an alpha male; HOW TO ASK if patch
to reproduce
  if (sex = "female") and (alpha?) and (ticks mod 12 = 0)
  [
    ; look up, find a male
    let manpatch patch-at 0 1
    let iHaveAMale hasAnAlpha manpatch
    if iHaveAMale
    [
      hatch 2
      [
        set age 0
        set alpha? false
        set color red + 2
        set size 0.2
        set shape "circle"
        ; am at center when born?
        set xcor pxcor + random-float 0.3
        set ycor -0.4
        set xstart pxcor
        set ystart pycor
        ; oops, it is a boy
        if random-float 1 < 0.5
        [
          set sex "male"
          set color blue + 2
          set ycor ycor + 1
        ]
      ]
    ]
   ]
end



to scout

  if alpha? or age <= 12
  [
    set IwillScout? false
    stop
  ]

  if IwillScout? = false [stop]

  if random-float 1.0 < scoutPDie
  [
    die
    stop
  ]

  let original-x xcor
  let original-y ycor

  let stepsize 1
  if random-float 1 < 0.5 [set stepsize -1]
  let step stepsize

  ; if stepsize + 1, heading is right
  ifelse stepsize > 0
  [
    set heading 90
  ]
  [
    set heading 270
  ]

  ; TODO check if heading updates automatically

  repeat scoutdistance
  [
    let newpatch patch-at step 0
    let new-x original-x + step
    let itHasAlpha hasAnAlpha newpatch
    if itHasAlpha = false
    [
      pd
      setxy new-x original-y
      ask newpatch [fillAlpha]
      pu
      stop
    ]

    set step step + stepsize
  ]

end

; turtle method, find age hierarchy
to ageHierarchy
  if count turtles-here > 0
  [
    ;;show turtles-here
    ;;let competition  (other turtles-here) with [subordinate? or alpha?]
    let competition  (other turtles-here) with [subordinate?]
    sayHi
    show (word "My competition!" "There are " count competition " of these things")
    ask competition [sayHi]
    let ageList sort [age] of competition
    let repeatList []
    repeat count competition
    [
      set repeatList lput age repeatList
    ]
    show (map - repeatList ageList)
    ;show ageList2
  ]
end

; ask agent report about self to output
to sayHi
  show (word "hi my name is " who " my age is " age)
  show (word "agent " who " X:" xcor " Y:" ycor)
end

to-report turtleage
  report age
end

; ask patch if it has an alpha
to-report hasAnAlpha [aPatch]
  report [hasalpha?] of aPatch
end


to-report pop
  report count turtles
end


to-report popAdults
  report count turtles with [age > 12]
end


to updatePlots
  set-current-plot "population"
  plot pop

  if (ticks mod 12 = 0)
  [
    let oneTimeList[]
    repeat 25
    [
      set oneTimeList lput 0 oneTimeList
    ]

    let j 0
    repeat 25
    [
      let zzz sum [count turtles-here with [age > 12]] of patches with [pxcor = j]
      set oneTimeList replace-item j oneTimeList zzz
      set j j + 1
    ]
    ; sentence like unlist in R, it collects up values
    ; following created a list of lists, not a list of elements
    ; set groupSizeList lput oneTimeList groupSizeList
    set groupSizeList (sentence oneTimeList groupSizeList)

    set-current-plot "histogram"
    histogram groupSizeList
  ]
end


to-report nPerCell [aPatch] ; patch report
  report count [turtles] of aPatch
end


to ageTurtle
  set age age + 1
  if age > 12
  [
    ask patch-here [fillAlpha]
  ]
  if age > 12
  [
    ifelse alpha?
    [
      becomeAlpha
      ;; TODO make sure not other alphas
    ]
    [
      becomeSubordinate
    ]
  ]
end



to go
  tick

  ask turtles with [subordinate?]
  [
    ageHierarchy
  ]

  ask turtles
  [
    ageTurtle
  ]

  ask patches [
     fillAlpha
  ]

  ask turtles
  [
    ifelse random-float 1 < scoutP
    [set IwillScout? true]
    [set IwillScout? false]
  ;;set IwillScout angieMagic1
    scout
  ]


   ;; how to select turtles in row 0?
  ask turtles [
    reproduce
  ]

  ask turtles
  [
    if random-float 1 > survivalP
    [
      ; must die, but clean up patch of self first
      if alpha?
      [
        set hasAlpha? false
      ]
      set alpha nobody
      die
    ]
  ]

  updatePlots

  set burnin burnin + 1
  if burnin = 24 [
    reset-ticks
    ] ; throw away burnin
  if ticks = 240 [ stop ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1045
107
-1
-1
33.0
1
10
1
1
1
0
1
0
1
0
24
0
1
0
0
1
ticks
30.0

BUTTON
19
14
92
47
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
21
57
85
90
step
go
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
22
94
85
127
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
1

PLOT
28
163
228
313
population
Ticks (months)
Population
0.0
240.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
272
171
472
321
histogram
NIL
NIL
0.0
6.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

@#$#@#$#@
## WHAT IS IT?

Chapter 19 (Railsback & Grimm) exercise about Woodhoopoe birds

## HOW IT WORKS

Agents are birds that age.  Gender is important. Birds over age 12 months are
eligible to become alpha birds within their gender/patch.  Oldest bird is alpha, if ages are equal, then alpha is designated randomly (and permanently).

As described in Ch 19, there is one row of birds. This version has 2 rows, one for males, one for females.  This simplifies some book-keeping,  but makes summary data collection more interesting/troublesome.

Visualization of the state of each patch and agent movement is a point of
emphasis here.

This visualization has small dots for infant birds, and squares for subordinates, who
1. may become alpha if there is no current alpha
2. may move sideways to another patch if there is no alpha

Risk of death is randomly imposed on all birds, and subordinates who go on scouting
foray endure a much higher risk of death.

## HOW TO USE IT

The interface does not introduce sliders, all parameters are set in the code at the moment.

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

Setup, then step one at a time to see open patches and fill by birth or movement.

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

Because the 2 rows separate males and females, it is somewhat tedious to produce
a total population count for the histogram.

sayHi method is a Swarm-style thing

A traditionalist might object to the use of minus signs in variable names, which
NetLogo allows, but most other languages do not.  In this code, the minus names
are avoided, using instead camel case.

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 5.3.1
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
0
@#$#@#$#@
