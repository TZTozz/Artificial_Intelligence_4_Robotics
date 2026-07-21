"""
Simulation of the PDDL+ process `tank_to_tank_flow`.

The process moves mass (ammonia) from tank1 (high pressure) to tank2
(low pressure) through valve1, as long as:
    - the valve is open (opening > 0)
    - pressure(t_src) > pressure(t_dest)
    - volume(t_src) > 0 and mass(t_src) > 0

Continuous effects (per the PDDL+ #t semantics):
    d(mass_src)/dt   = -k * (P_src - P_dest) * opening
    d(mass_dest)/dt  = +k * (P_src - P_dest) * opening
    d(P_src)/dt      = -(R*T_src/V_src) * k * (P_src - P_dest) * opening
    d(P_dest)/dt     = +(R*T_dest/V_dest) * k * (P_src - P_dest) * opening

We integrate this system numerically (simple explicit Euler, small dt)
until the process's precondition (P_src > P_dest) stops holding, i.e.
the two pressures reach equilibrium, and plot P(tank1) and P(tank2)
over time.
"""

import numpy as np
import matplotlib.pyplot as plt

# ---------------------------------------------------------------------
# Initial state / constants (from the problem file)
# ---------------------------------------------------------------------
valve_opening = 0.8
flow_coefficient = 0.005
R_ammonia = 8.314

P1_0 = 100.0     # pressure tank1
V1 = 50.0        # volume tank1
M1_0 = 20.0      # mass tank1
T1 = 293.0       # temperature tank1 (assumed constant)

P2_0 = 50.0      # pressure tank2
V2 = 50.0        # volume tank2
M2_0 = 20.0      # mass tank2
T2 = 293.0       # temperature tank2 (assumed constant)

# ---------------------------------------------------------------------
# Simulation settings
# ---------------------------------------------------------------------
dt = 0.01        # integration time step
t_max = 150.0   # safety cap on simulated time

# ---------------------------------------------------------------------
# Euler integration of the process's continuous effects
# ---------------------------------------------------------------------
t = 0.0
P1, P2 = P1_0, P2_0
M1, M2 = M1_0, M2_0

times = [t]
pressures1 = [P1]
pressures2 = [P2]
masses1 = [M1]
masses2 = [M2]

threshold = 1.0          # pressure-difference threshold to mark
t_threshold = None        # time at which |P1 - P2| first drops below threshold

while t < t_max:
    # process precondition: valve open, P_src > P_dest, volume/mass > 0
    if not (valve_opening > 0 and P1 > P2 and V1 > 0 and M1 > 0):
        break

    flow = flow_coefficient * (P1 - P2) * valve_opening  # mass flow rate

    dM1 = -flow
    dM2 = +flow
    dP1 = -(R_ammonia * T1 / V1) * flow
    dP2 = +(R_ammonia * T2 / V2) * flow

    M1 += dM1 * dt
    M2 += dM2 * dt
    P1 += dP1 * dt
    P2 += dP2 * dt
    t += dt

    times.append(t)
    pressures1.append(P1)
    pressures2.append(P2)
    masses1.append(M1)
    masses2.append(M2)

    if t_threshold is None and abs(P1 - P2) < threshold:
        t_threshold = t

print(f"Equilibrium reached at t = {t:.2f} s")
print(f"Final pressures: tank1 = {P1:.3f}, tank2 = {P2:.3f}")
print(f"Final masses:    tank1 = {M1:.3f}, tank2 = {M2:.3f}")

# ---------------------------------------------------------------------
# Plot
# ---------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(9, 5.5))

ax.plot(times, pressures1, label="Pressure tank1", color="#d62728", linewidth=2)
ax.plot(times, pressures2, label="Pressure tank2", color="#1f77b4", linewidth=2)

if t_threshold is not None:
    ax.axvline(
        t_threshold,
        color="gray",
        linestyle="--",
        linewidth=1.5,
        label=f"|ΔP| < {threshold} at t = {t_threshold:.2f}s",
    )
    print(f"|P1 - P2| dropped below {threshold} at t = {t_threshold:.2f} s")
else:
    print(f"|P1 - P2| never dropped below {threshold} within the simulated time")

ax.set_xlabel("Time (s)")
ax.set_ylabel("Pressure")
ax.set_title("Tank-to-tank flow through valve1 0.8: pressure over time")
ax.grid(True, alpha=0.3)
ax.legend()

fig.tight_layout()

import os
output_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tank_pressure_over_time.png")
fig.savefig(output_path, dpi=150)
print(f"Plot saved to {output_path}")

plt.show()