library(readr)
library(tidyverse)
data <-read_delim("IATfacefinalv2.csv", delim = "\t",
                  locale = locale(encoding = "UTF-16LE"))
 unique(data$Handedness)
 unique(data$Leftlabel)
 
 mutated_data <- data|>
   mutate(
     Seconds = StimulusDisplay.RT/1000
   )
 final_data <- mutated_data |>
   # Filter out practice blocks
   filter(Block %in% c(3, 4, 6, 7)) |>
   
   # Label the IAT Condition
   mutate(Condition = case_when(
     Block %in% c(3, 4) ~ "Incongruent",
     Block %in% c(6, 7) ~ "Congruent"
   )) |>
   
   # Remove outliers (Standard for DDM: < 200ms and > 3000ms)
   filter(Seconds >= 0.2 & Seconds <= 3.0) |>
   
   # Ensure Accuracy is a factor or numeric 0/1 for the model
   mutate(Response = StimulusDisplay.ACC) |>
   
   # Keep only the columns needed for modeling to save memory
   select(Subject, Seconds, Condition, Response, TrialType)
 