library(readr)
library(tidyverse)
data <-read_delim("IATfacefinalv2.csv", delim = "\t",
                  locale = locale(encoding = "UTF-16LE"))
 unique(data$Handedness)
 unique(data$Leftlabel)
 
 mutated_data <- data|>
   mutate(
     RT_Seconds = StimulusDisplay.RT/1000
   )
 final_data <- mutated_data %>%
   filter(Block %in% c(3,4,6,7)) |>
   mutate(CI = case_when(
     version == 1 & Block %in% c(3, 4) ~ "non-congruent",
     version == 1 & Block %in% c(6, 7) ~ "congruent",
     version == 2 & Block %in% c(3, 4) ~ "congruent",
     version == 2 & Block %in% c(6, 7) ~ "non-congruent",
     TRUE ~ NA_character_
   )) |>
   
   # Remove outliers (Standard for DDM: < 200ms and > 3000ms)
   filter(RT_Seconds >= 0.2 & RT_Seconds <= 3.0) |>
   
   # Ensure Accuracy is a factor or numeric 0/1 for the model
   mutate(Accuracy = StimulusDisplay.ACC) |>
   mutate(
     R = case_match(StimulusDisplay.RESP,
                               "e" ~ "left",
                               "i" ~ "right",
                               .default = NA_character_
     )
   ) |> mutate(
     S = case_match(Correct,
                    "e" ~ "left",
                    "i" ~ "right",
                    .default = NA_character_
     )
   ) |>
   mutate(
     Stimulus_type = case_when(
       grepl("^b", Stimulus, ignore.case = TRUE) ~ "black_face",
       grepl("^w", Stimulus, ignore.case = TRUE) ~ "white_face",
       grepl("crash|abuse|rotten|pollute|vomit|grief", Stimulus, ignore.case = TRUE) ~ "bad_word",
       grepl("happy|friend|laughter|honest|health|peace", Stimulus, ignore.case = TRUE) ~ "good_word",
       TRUE ~ NA_character_
     )
   )|> 
 mutate(ID= Subject) |>
   mutate(Race_partic = case_when(
     Race == 1 ~ "black",
     Race == 2 ~ "white",
     Race == 3 ~ "other",
     TRUE ~ NA_character_
   )) |> 
   # Keep only the columns needed for modeling
   select(ID, RT_Seconds, CI, Accuracy, R, S, Stimulus_type, Age,Race_partic,Handedness)
 
 write.csv(final_data, "final_data.csv")
 
 unique(final_data$Stimulus_type)
 unique(final_data$Race_partic)
 unique(final_data$S)
 unique(final_data$R)
 unique(final_data$CI)
