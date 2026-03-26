# Balaton2026

# Bayesian Hierarchical Drift Diffusion Modeling for IAT 

## Overview
---

## 1. What is a Drift Diffusion Model (DDM)?

A DDM models decisions as **noisy evidence accumulation over time**.

Imagine:
> Evidence builds up until it hits a decision threshold.

### Core parameters

- **Drift rate (v)**  
  → speed/quality of information processing

- **Boundary separation (a)**  
  → response caution (speed vs accuracy tradeoff)

- **Starting point (z)**  
  → initial bias toward one response

- **Non-decision time (t0)**  
  → perception + motor time

---

## 2. What is Hierarchical Bayesian Modeling?

Instead of estimating each participant separately:

- Each participant has their own parameters
- These parameters are drawn from a **group-level distribution**

### Why this matters

- Stabilizes noisy estimates
- Especially useful with small samples
- Allows group-level inference

---

## 3. DDM vs Hierarchical Bayesian

They are **not alternatives**.

- **DDM** = cognitive model (how decisions work)
- **Hierarchical Bayesian** = estimation method

In practice:
> You fit a **hierarchical Bayesian DDM**

---

# Data Requirements

Each row = one trial

| Column      | Description |
|------------|------------|
| subj_idx   | participant ID |
| rt         | reaction time (seconds) |
| response   | 0/1 (error/correct OR choice A/B) |
| task       | weapons / flankers |
| group      | IMS/EMS group |
| trial_type | optional (e.g., congruent/incongruent) |

---

## Fitting model parameters:

The model:

1. Takes your RT + accuracy data
2. Tries many parameter combinations
3. Keeps those that best reproduce your data

In Bayesian terms:
- Computes **likelihood of data given parameters**
- Combines with priors
- Produces **posterior distributions**

---

# Basic HDDM Implementation

## Minimal model
