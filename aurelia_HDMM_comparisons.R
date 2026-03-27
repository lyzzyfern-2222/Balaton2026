###########
###########
#### packages ----
###########
###########
setwd("~/Documents/Balaton")
library(readr)
library(tidyverse)
library(dplyr)
library(EMC2)
EMC2:::log_likelihood_ddm

###########
###########
#### Final data
###########
###########

final_data <- read.csv("~/Documents/Balaton/final_data.csv")
final_data <- final_data[, !(names(final_data) %in% "X")]

# means by condition are there
final_data %>%
  group_by(CI) %>%
  summarise(mean_rt_seconds = mean(RT_Seconds, na.rm = TRUE))

t.test(RT_Seconds ~ CI, data = final_data)
# significant difference between the groups

final_data <- final_data %>%
  rename(
    rt = RT_Seconds,
    subjects = ID
  )

############################
############################

final_data_subset <- final_data %>%
  select(subjects, CI, S, R, rt) %>%
  filter(subjects %in% c(783, 788)) %>%
  mutate(
    subjects = as.factor(subjects),
    CI       = as.factor(CI),
    S        = as.factor(S),
    R        = as.factor(R)
  ) %>%
  mutate(
    CI = ifelse(CI == "non-congruent", "noncongruent", CI))

final_data_subset$CI <- as.factor(final_data_subset$CI)
is.factor(final_data_subset$CI)

unique(final_data$subjects)
Smat <- cbind(d = c(-1, 1))
final_design_hDDM <- design(
  data = final_data_subset,
  model = DDM,
  formula = list(v ~ S * CI, a ~ CI, Z ~ 1, t0 ~ 1, sv ~ 1),
  contrasts = list(S = Smat)
)
#mean drift rate is a bias, means you are responding in top or bottom boundary
# v_sd is sd in drift rate -1 means that for right it is 1 and for left it is -1
# assumption here: under accuracy condition, speed effect from left to right and
# right to left = 0, might not hold, people might have bias to switch right or left
# therefore, best to do model comparison

mapped_pars(final_design_hDDM)

final_mu_mean <- c(
  v = 0,
  v_Sd = 2,
  "v_Sd:CInoncongruent" = .2,
  a = log(1),
  a_CInoncongruent = log(1.5),
  Z = 0,
  t0 = log(.2),
  sv = log(.3)
)
final_mu_sd <- c(
  v = 1,
  v_Sd = 0.5,
  "v_Sd:CInoncongruent" = 0.5,
  a = 1,
  a_CInoncongruent = .5,
  Z = 0.3,
  t0 = .5,
  sv = .3
)

final_prior_hDDM <- prior(final_design_hDDM, type = 'standard',mu_mean=final_mu_mean,
                    mu_sd=final_mu_sd)



final_hDDM <- make_emc(final_data_subset,final_design_hDDM, prior=final_prior_hDDM)
hDDM <- fit(final_hDDM, cores_per_chain = 4, fileName="tmp.RData")
hDDM2 <- fit(final_hDDM, cores_per_chain = 4, fileName="tmp.RData")
save(hDDM,file="~/Documents/Balaton/hDDM.RData")

check(hDDM)
check(hDDM2)

str(hDDM,  max.level = 1)
str(hDDM2, max.level = 1)

plot(hDDM)

###########
### posterior predictions to see how well models fit
###########

#model comparison
EMC2::compare(hDDM, hDDM2)

compare(list(DDM = hDDM, DDM2 = hDDM2))

pp_hDDM <- predict(hDDM, n_cores = 10)
pp_hDDM2 <- predict(hDDM2, n_cores = 10)

acc_fun <- function(data) factor(data$S == data$R)
plot_cdf(final_data_subset, post_predict = list(DDM = pp_hDDM, DDM2 = pp_hDDM2),
         functions = list(correct = acc_fun),
         factors = "CI",
         #currently average over subjects, for average across subject factors =c("E,"subjects")
         defective_factor = "correct",
         layout = c(1,3))

# Compare arbitrary descriptives on the real data to the predictives of both models.
# For example differences in response time and error rates between the emphasis conditions:

drt <- function(data){
  all <- tapply(data$rt,data$CI,mean)
  out <- all["congruent"] - all["noncongruent"]
  names(out) <- "CON-NONCON"
  return(out)
}

derr <- function(data){
  data$correct <- data$S == data$R
  all <- tapply(data$correct,data$CI,mean)*100
  out <- all["congruent"] - all["noncongruent"]
  names(out) <- "CON-NONCON"
  return(out)

}

par(mfrow = c(1,2))
plot_stat(hDDM, list(hDDM = pp_hDDM), stat_fun = drt,
          xlab = "RT (s) difference", layout = NULL,legendpos = c("topleft","topright"))
plot_stat(hDDM, list(DDM = pp_hDDM), stat_fun = derr,
          xlab = "Accuracy (%) difference", layout = NULL,legendpos = c("topleft","topright"))


################
######## psychological inference on final model
######## I did all of this for hDDM2 now
################
sampled_pars(hDDM2)
# see what variables are affected by a manipulation

# Hypothesis uses a trick to compare
# the model to a null model for which the parameter is set to a constant value (H0).
# But this only works for strictly nested models. So here we compare the group-level
# mean of the  model, to alternative models for which there is no group-level difference from
# e.g. 0.
# In compare, we check if this model is preferred across subjects, not on average.
# It's like checking if there's a difference in alpha, or in mu.

hypothesis(hDDM2, parameter = "v_CInoncongruent", H0=0)
hypothesis(hDDM2, parameter = "v_Sd:CInoncongruent",H0=0)
hypothesis(hDDM2, parameter = "a_CInoncongruent",H0=0) #not sure if a_CInoncongruent is correct here
#fixed effects, group-level average effects

# To check the posteriors of inferential targets, we can use credint
credint(hDDM2, map = T)
credint(hDDM2, map = list(v = "CI", B = "CI"))
# for average drift rates
# with this we can get the direction

# Between-subject analysis ---
plot_cdf(final_data_subset, factors = "S")

Smat <- cbind(d = c(-1, 1))
final_winning_model <- design(list(v ~ S*CI, #different drift rates depend on stimuli and logfreq
                       a ~ 1, t0 ~ 1, Z ~ 1, sv ~ 1, s ~ S),
                  # s~S drift variability much higher for words than non-words
                  data = final_data_subset, model = DDM,
                  contrasts = list(v = list(S = Smat)),
                  constants = c(s = log(1)))

group_comparison <- group_design(formula = list(`v_Sd` ~ Race_partic), #v_sd is not average drift rate
                              subject_design = final_winning_model,
                              data = final_data_subset)

summary(group_comparison)

# Create a very simple prior, leaving all the 'effects' to 0.
pri_group_comp <- prior(group_comparison, group_design = group_comparison,
                 mu_mean = c(`v_Sd` = 2,
                             a = log(1),
                             t0 = log(.25),
                             sv = log(.3)))

pri_group_comp

ELP_DDM <- make_emc(final_data, design = final_winning_model, group_design = group_comparison,
                    prior_list = pri_group_comp)

ELP_DDM <- fit(ELP_DDM, file = "samples/ELP_DDM.RData", cores_per_chain = 3)
save(ELP_DDM, file = "samples/ELP_DDM.RData")

check(ELP_DDM)


# posterior predictives
pp_ELP <- predict(ELP_DDM, n_cores = 10)
# First we plot the posterior predictives for the different stimulus types
plot_cdf(final_data_subset, pp_ELP, factors = "S")

#################
####### inference
#################
# Let's  check the effect of xxx on both drift rate and drift variability
hypothesis(ELP_DDM, parameter = "CI")


# To test whether race has an effect on drift rate, we need a new type of parameter:
# "beta", here the difference between "mu" and "beta" is that mu is the implied mean, and beta is
# the actual group-level regressors.
hypothesis(ELP_DDM, parameter = "v_Sd_Race_partic", selection = "beta")

# To check out  posterior distribution:
credint(ELP_DDM, selection = "beta")
#direction of effects, gives intercepts and regresseives
#v_Sd is giving point of reference



