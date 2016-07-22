
GitHub: http://github.com/pauljohn32/netlogo

What's different here?

1. "Two row" version of the model

Females in row 0
Males in row 1

See Graphic
  babies: little circles at bottom
  subordinates: squares in middle
  alpha: arrows at top
  
NetLogo coordinate surprise: Vertical coordinates of
row 0 are [-0.5, 0.5]. This was important in positioning
babies and alphas.

If not just for beauty, why?
- conceivably faster, simpler to program


2. Problem when we need to put together all of the birds at a location.
Use NetLogo lists to add two rows together. This was harder (look
for updatePlots procedure, "oneTimeList" pasted onto groupSizeList
with sentence primative (like unlist in R)

Histogram has to accumulate output over many years.

3. Subordinates ask cells if there is opportunity, they
don't "go there" and check.

4. Old Swarm trick:

; ask agent report about self to output
to sayHi
  show (word "hi my name is " who " my age is " age)
  show (word "agent " who " X:" xcor " Y:" ycor)
end

This can be used to see profuse output about agents

5. Agent move decision can incorporate age hierarchy
of others within cell.


What's not done still

