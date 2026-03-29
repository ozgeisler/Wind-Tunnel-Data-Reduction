# Wind Tunnel Data Reduction

## Overview

This MATLAB script performs a complete aerodynamic data reduction pipeline for a wind tunnel test conducted at the University of Washington Aeronautical Laboratory (UWAL).

Starting from raw balance measurements, it applies a series of corrections to produce final aerodynamic coefficients in the **stability axis**.

---

## Raw Input Data

The balance measures six quantities at a single test condition:

* Angle of attack: **α = 13°**
* Sideslip angle: **ψ = −5°**
* Indicated dynamic pressure: **qᵢ = 25.5 N/m²**

**Raw forces and moments:**

* Lift: L = 9 N
* Drag: D = 0.1 N
* Side force: Y = 1.1 N
* Pitching moment: P = −1388 N·m
* Yawing moment: N = 5 N·m
* Rolling moment: R = 65 N·m

---

## Data Reduction Pipeline

### A — Indicated to Actual Dynamic Pressure

The tunnel’s indicated dynamic pressure is corrected using a calibration factor:

```
qₐ = 1.0125 × qᵢ
```

---

### B — Balance Interactions

Raw balance readings include cross-coupling between channels. A linear interaction matrix is used:

```
xB = A1·xR + A2·(xR)^2
```

(*A2 is zero in this case*)

---

### C — Tares

Structural tares (sting/strut effects) are removed.
Assumed **zero** in this case.

---

### D — Weight Tares

The model’s weight acting at a CG offset from the Balance Moment Center creates spurious moments.

Steps:

* Rotate weight vector into body frame using α and ψ
* Compute induced moments
* Subtract from measurements

---

### E — Moment Transfer (BMC → MMC)

Moments are transferred using the wind tunnel (left-handed) convention:

```
R_MMC = R_BMC + u·L − t·Y
P_MMC = P_BMC + s·L + t·D
N_MMC = N_BMC − s·Y − u·D
```

---

### F — Blockage Corrections (Maskall Method)

The model accelerates the flow due to blockage effects.

```
ε = solid blockage factor
q_c = qₐ · (1 + ε)^2
```

Wake blockage is assumed negligible.

---

### G — Initial Aerodynamic Coefficients

```
CL = L / (q_c · S)
CD = D / (q_c · S)
CY = Y / (q_c · S)

Cm = P / (q_c · S · c̄)
Cn = N / (q_c · S · b)
Cl = R / (q_c · S · b)
```

---

### H — Flow Angularity Correction

A small tunnel upflow angle biases measurements:

* α_upflow = −0.012°

Corrections applied to:

* angle of attack
* drag coefficient

---

### I — Wall Corrections

Tunnel walls induce artificial aerodynamic effects:

* Δα_wall → induced upwash
* ΔCD_wall → induced drag
* ΔCm_wall → streamline curvature

---

### J — Final Coefficients

All corrections are combined to produce final **wind-axis coefficients**:

```
CL, CD, CY, Cm, Cn, Cl
```

---

### K — Axis Transfer (Wind → Stability)

Final coefficients are rotated into the **stability axis** using ψ:

* CL unchanged
* CD, CY rotated
* Moments adjusted accordingly

---

## Plots Produced

The script generates the following visualizations:

| Plot                      | Description                                   |
| ------------------------- | --------------------------------------------- |
| Drag coefficient stages   | CD evolution: Initial → Upflow → Wall → Final |
| Pitching moment stages    | Cm evolution through corrections              |
| Moment corrections        | Pitch, Yaw, Roll across pipeline              |
| Weight tare contributions | Gravity-induced moment effects                |
| Final coefficients        | CL, CD, CY, Cm, Cn, Cl                        |
| Correction magnitudes     | Size of applied corrections                   |

---

## Key Assumptions

* Strut interference is negligible
* Wake blockage is negligible
* Lift from non-wing surfaces is negligible
* Nonlinear interaction matrix A2 = 0

---

## Reference Frame Notes

* Measurements are in **wind tunnel body axis (left-handed)**

* Moment transfer uses aeronautical sign convention:

  * +s → upstream
  * +t → upward
  * +u → right

* Final outputs are in **stability axis**

* Stability axis is obtained by rotating wind axis by ψ about the z-axis

---


## Notes

This project is part of a self-driven effort to connect:

* Experimental aerodynamics
* Flight mechanics
* Computational modeling

with future work in **CFD, MDO, and aerospace system design**.
