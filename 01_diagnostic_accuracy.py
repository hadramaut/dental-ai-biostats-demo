"""
Case 1: AI vs. physician diagnostic accuracy on paired CBCT reads.

Simulates 200 teeth with an expert-consensus reference label and compares:
  - an AI model (probability output + binary decision at 0.5)
  - a physician reading without AI assistance

Metrics: sensitivity/specificity with 95% Wilson CIs, Cohen's kappa,
ROC-AUC, and McNemar's exact test on paired correctness.

Run:  python 01_diagnostic_accuracy.py
"""

import numpy as np
import pandas as pd
from sklearn.metrics import confusion_matrix, roc_auc_score, cohen_kappa_score, roc_curve
from statsmodels.stats.proportion import proportion_confint
from statsmodels.stats.contingency_tables import mcnemar
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# ---------------------------------------------------------------- dataset
rng = np.random.default_rng(42)
n = 200
y_true = rng.binomial(1, 0.35, size=n)  # 1 = periapical lesion, 0 = normal

ai_prob = np.where(y_true == 1, rng.beta(8, 1.5, n), rng.beta(1.5, 8, n))
ai_pred = (ai_prob >= 0.5).astype(int)
doc_pred = np.where(
    y_true == 1,
    rng.binomial(1, 0.80, n),  # physician sensitivity ~80%
    rng.binomial(1, 0.08, n),  # physician false-positive rate ~8%
)

# ---------------------------------------------------------------- metrics
def calc_metrics(y_t, y_p, label):
    tn, fp, fn, tp = confusion_matrix(y_t, y_p).ravel()
    sens = tp / (tp + fn)
    spec = tn / (tn + fp)
    sens_ci = proportion_confint(tp, tp + fn, method="wilson")
    spec_ci = proportion_confint(tn, tn + fp, method="wilson")
    kappa = cohen_kappa_score(y_t, y_p)
    return {
        "Method": label,
        "Sensitivity (95% CI)": f"{sens:.3f} ({sens_ci[0]:.3f}-{sens_ci[1]:.3f})",
        "Specificity (95% CI)": f"{spec:.3f} ({spec_ci[0]:.3f}-{spec_ci[1]:.3f})",
        "Cohen's Kappa": round(kappa, 3),
    }

summary = pd.DataFrame([
    calc_metrics(y_true, ai_pred, "AI model"),
    calc_metrics(y_true, doc_pred, "Physician (no AI)"),
])
print(summary.to_string(index=False))
print(f"\nROC-AUC of AI model: {roc_auc_score(y_true, ai_prob):.3f}")

# ------------------------------------------------------- McNemar test
ai_ok = (ai_pred == y_true).astype(int)
doc_ok = (doc_pred == y_true).astype(int)
table = pd.crosstab(ai_ok, doc_ok)
res = mcnemar(table, exact=True)
print(f"McNemar exact p-value: {res.pvalue:.4f}")
print("\nPaired correctness table (rows = AI, cols = physician):")
print(table.to_string())

# ------------------------------------------------------------- ROC curve
fpr, tpr, _ = roc_curve(y_true, ai_prob)
plt.figure(figsize=(5, 4))
plt.plot(fpr, tpr, label=f"AI model (AUC = {roc_auc_score(y_true, ai_prob):.3f})")
plt.plot([0, 1], [0, 1], "k--", lw=0.8)
plt.xlabel("False positive rate")
plt.ylabel("True positive rate")
plt.title("ROC curve — periapical lesion detection (CBCT)")
plt.legend(loc="lower right")
plt.tight_layout()
plt.savefig("roc_curve.png", dpi=150)
print("\nSaved roc_curve.png")
