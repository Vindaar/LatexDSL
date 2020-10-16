import ggplotnim, latexdsl, strformat

# let's assume we have a complicated proc, which performs our
# data analysis and returns the result as a ggplotnim `DataFrame`

proc complexCalculation(): DataFrame =
  # here be code your CPU hates ;)
  result = seqsToDf({ "Num" : @[17, 43, 8, 22],
                      "Group" : @["Group 1", "Group 2", "Group 3", "Group 4"] })

# let's perform our complex calc
let df = complexCalculation()
# and create a fancy plot for it
let path = "examples/dummy_plot.png"
ggplot(df, aes(Group, Num)) + 
  geom_bar(stat = "identity") + 
  xlab("Number of participants") +
  ylab("Age group") +
  ggsave(path)

# now we could construct a TeX figure and table for the data manually,
# but for these use cases two helper procs exist. `figure` and `toTexTable`.

# We want to include the information about the group with the most participants
# into the caption of the table. So create the correct caption computationally
# without having to worry about causing code / paper to get out of sync
echo df
let maxGroup = df.filter(f{int -> bool: `Num` == max(df["Num"])})
echo maxGroup
# create two nice labels:
let figLab = "fig:sec:ana:participants"
let tabLab = "tab:sec:ana:participants"
# for simplicity we will use the same caption for figure and table, with different
# references
let cap = "Number of participants in the experiment by age group. Group " &
  &"{maxGroup[\"Group\", 0]} had the most participants with {maxGroup[\"Num\", 0]}" &
  " subjects."
# and add a reference to the table we will create 
let figCap = cap & "The data used for the figure is found in tab. \ref{" & $tabLab & "."
let fig = figure(path, caption = cap, label = figLab, width = textwidth(0.8),
                 checkFile = true)
# NOTE: The `checkFile` argument performs a runtime check on the given path to make
# sure the file that is supposed to be put into a TeX document actually exists!
# and finally for the table:
let tabCap = cap & "The data is plotted in fig. \ref{" & $figLab & "."
let tab = toTexTable(df, caption = tabCap, label = tabLab)

# and from here we could insert the generated TeX code directly into a TeX document.
# We'll just print it here.
echo fig
echo tab
