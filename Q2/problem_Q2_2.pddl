(define (problem Q2_2) (:domain Orbital_domain_Q2)

(:objects
    loc1 loc2 loc3 - location
    valve1 - valve
    tank1 tank2 - tank
    sensor1 sensor2 spare_sensor1 - sensor
    adjustable_wrench lubricant - tool
    small medium large - size
    panel1 panel2 - panel

    ;; --- diagnostic knowledge base objects ---
    valve_stuck_fault valve_leak_fault sensor_crazy_fault sensor_dead_fault panel_jammed_fault - fault
    open_valve_test closed_valve_test sensor_self_test sensor_comparison_test panel_movement_test - diagnostic_test
    unstuck_fix tighten_fix replace_fix lub_fix - recovery_action
)

(:init
    (robot-at loc1)
    (= (speed) 2.0)
    (fixed_at valve1 loc2)
    (fixed_at tank1 loc2) (fixed_at tank2 loc3)
    (warehouse_location loc3)
    (item_at spare_sensor1 loc3)
    (is_spare spare_sensor1)
    (has_size valve1 small)

    (is_connected loc1 loc2) (is_connected loc2 loc1)
    (is_connected loc2 loc3) (is_connected loc3 loc2)
    (= (distance loc1 loc2) 20.0) (= (distance loc2 loc1) 20.0)
    (= (distance loc2 loc3) 20.0) (= (distance loc3 loc2) 20.0)

    (valve_connect valve1 tank1 tank2) (valve_connect valve1 tank2 tank1)
    (covers panel1 tank1) (covers panel2 tank2)
    (fixed_at panel1 loc2) (fixed_at panel2 loc3)

    (monitor sensor1 tank1) (monitor sensor2 tank2)

    ;(is_open_valve valve1)
    

    (can_torque adjustable_wrench)
    (has_size adjustable_wrench medium)
    (is_adjustable adjustable_wrench)
    (in_toolbox adjustable_wrench)
    
    (can_lub lubricant)
    (in_toolbox lubricant)
    (hand_empty)

    ;; ---------------- diagnostic knowledge base ----------------
    (applicable_test closed_valve_test valve1)
    (applicable_test sensor_self_test sensor1)
    (applicable_test sensor_self_test sensor2)
    (applicable_test sensor_self_test spare_sensor1)
    (applicable_test sensor_comparison_test sensor1)
    (applicable_test sensor_comparison_test sensor2)
    (applicable_test sensor_comparison_test spare_sensor1)
    (applicable_test panel_movement_test panel1)
    (applicable_test panel_movement_test panel2)

    
    (test_requires_symptom open_valve_test pressure_stable)
    (test_requires_symptom closed_valve_test pressure_changing)
    (test_requires_symptom sensor_self_test erratic_reading)
    (test_requires_symptom sensor_comparison_test pressure_stable)
    (test_requires_symptom panel_movement_test no_movement)
    
    (test_requires_open open_valve_test)
    (test_requires_closed closed_valve_test)
    (test_requires_neighbor sensor_comparison_test)
    (unreliable_symptom erratic_reading)

    (test_indicates open_valve_test valve_stuck_fault)
    (test_indicates closed_valve_test valve_leak_fault)
    (test_indicates sensor_self_test sensor_crazy_fault)
    (test_indicates sensor_comparison_test sensor_dead_fault)
    (test_indicates panel_movement_test panel_jammed_fault)

    (fault_prevents_movement valve_stuck_fault)
    (fault_prevents_movement valve_leak_fault)

    (fixed_by unstuck_fix valve_stuck_fault)
    (fixed_by tighten_fix valve_leak_fault)
    (fixed_by replace_fix sensor_crazy_fault)
    (fixed_by replace_fix sensor_dead_fault)
    (fixed_by lub_fix panel_jammed_fault)

    (recovery_requires_torque unstuck_fix)
    (recovery_requires_torque tighten_fix)
    (recovery_requires_closed tighten_fix)
    (recovery_requires_spare replace_fix)
    (recovery_requires_lub lub_fix)

    (recovery_clears_symptom unstuck_fix pressure_stable)
    (recovery_sets_symptom unstuck_fix pressure_changing)
    (recovery_clears_symptom tighten_fix pressure_changing)
    (recovery_sets_symptom tighten_fix pressure_stable)
    (recovery_clears_symptom replace_fix erratic_reading)
    (recovery_clears_symptom replace_fix pressure_stable)
    (recovery_sets_symptom replace_fix pressure_changing)

    ; ----------------- initial state valve ----------------
    (= (valve_opening valve1) 0.8)
    (= (flow_coefficient) 0.005)
    (= (R_ammonia) 8.314)
    
    (= (pressure tank1) 100.0)
    (= (volume tank1) 50.0)
    (= (mass tank1) 20.0)
    (= (temperature tank1) 293.0)

    (shows sensor1 pressure_changing)
    (shows sensor2 erratic_reading)

    (= (pressure tank2) 50.0)
    (= (volume tank2) 50.0)
    (= (mass tank2) 20.0)
    (= (temperature tank2) 293.0)

    ; ------------------ initial state panel ----------------
    (= (movement_speed) 5.0)
    (= (manipulator_current) 0.0)
    (= (manipulator_current_limit) 50.0)

    (= (panel_position panel1) 0.0)
    (= (panel_open_position panel1) 90.0)
    (= (jam_severity panel1) 0.0)
    (= (beta_free panel1) 0.0)
    (panel_free panel1)

    (= (panel_position panel2) 0.0)
    (= (panel_open_position panel2) 90.0)
    (= (jam_severity panel2) 10.0)
    (= (beta_free panel2) 0.0)
    (panel_jammed panel2)

)

(:goal (and
    (everything_ok)
    (hand_empty)
    (not (equalized))
    (forall (?i - item) (or (not (in_toolbox ?i))
                            (= ?i adjustable_wrench)
    ))
    (forall (?p - panel) (not (panel_open ?p)))
))

)
