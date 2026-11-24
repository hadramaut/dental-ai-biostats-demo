# Case 2: Study design and reading-time analysis for AI-assisted CBCT reads.
#
# Part A: sample-size calculation to confirm AI sensitivity in a clinical
#         protocol (one-sided test, alpha = 0.025, power = 80%).
# Part B: paired analysis of reading-time savings (n = 40 scans).
#
# Run:  Rscript 02_study_design.R

# --- Part A: Sample size for confirming sensitivity ---------------------
# H0: Se <= 0.85  vs  H1: Se = 0.92
p0    <- 0.85
p1    <- 0.92
alpha <- 0.025
power <- 0.80

z_alpha <- qnorm(1 - alpha)
z_beta  <- qnorm(power)

n_pos <- ceiling(((z_alpha * sqrt(p0 * (1 - p0)) + z_beta * sqrt(p1 * (1 - p1))) / (p1 - p0))^2)

# Convert to total teeth via pathology prevalence (30%)
prevalence <- 0.30
n_teeth_raw <- ceiling(n_pos / prevalence)

# Clustering correction: avg 3 teeth per patient, ICC = 0.10,
# plus 10% scan attrition
m          <- 3
icc        <- 0.10
design_effect  <- 1 + (m - 1) * icc
n_teeth_adj    <- ceiling(n_teeth_raw * design_effect)
n_patients     <- ceiling((n_teeth_adj / m) / 0.90)

cat(sprintf(
  "Positive cases needed: %d\nTeeth after clustering correction (DE=%.2f): %d\nTotal patients (with 10%% attrition): %d\n\n",
  n_pos, design_effect, n_teeth_adj, n_patients
))

# --- Part B: Paired reading-time analysis --------------------------------
set.seed(42)
time_no_ai   <- rnorm(40, mean = 210, sd = 35)                 # seconds, no AI
time_with_ai <- time_no_ai - rnorm(40, mean = 55, sd = 20)     # seconds, with AI
diff_sec <- time_no_ai - time_with_ai

shapiro_p <- shapiro.test(diff_sec)$p.value
t_res <- t.test(time_no_ai, time_with_ai, paired = TRUE)
w_res <- wilcox.test(time_no_ai, time_with_ai, paired = TRUE, conf.int = TRUE)
cohens_d <- mean(diff_sec) / sd(diff_sec)

cat(sprintf(
  "Shapiro-Wilk p = %.4f\nMean time saved: %.1f s (95%% CI: %.1f-%.1f), p = %.2e\nCohen's d = %.2f | Wilcoxon p = %.2e\n",
  shapiro_p, t_res$estimate, t_res$conf.int[1], t_res$conf.int[2],
  t_res$p.value, cohens_d, w_res$p.value
))
