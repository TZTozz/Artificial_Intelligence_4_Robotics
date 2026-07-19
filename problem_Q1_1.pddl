(define (problem Problem_Q1_1) (:domain Orbital_domain_Q1)

(:objects
    loc1 loc2 loc3 - location
    valve1 valve2 - valve
    tank1 tank2 tank3 tank4 - tank
    sensor1 sensor2 sensor3 sensor4 spare_sensor1 spare_sensor2 - sensor
    adjustable_wrench - tool
    small medium large - size

    ;; --- diagnostic knowledge base objects ---
    valve_stuck_fault valve_leak_fault sensor_crazy_fault sensor_dead_fault - fault
    pressure_changing pressure_stable erratic_reading - symptom
    open_valve_test closed_valve_test sensor_self_test sensor_comparison_test - diagnostic_test
    unstuck_fix tighten_fix replace_fix - recovery_action
)

(:init
    (robot-at loc1)
    (component_at valve1 loc2)
    (component_at valve2 loc2)
    (tank_at tank1 loc2) (tank_at tank2 loc3)
    (tank_at tank3 loc1) (tank_at tank4 loc3)
    (warehause_location loc3)
    (item_at spare_sensor1 loc3)
    (is_spare spare_sensor1)
    (item_at spare_sensor2 loc3)
    (is_spare spare_sensor2)
    (has_size valve1 small) (has_size valve2 large)

    (is_connected loc1 loc2) (is_connected loc2 loc1)
    (is_connected loc2 loc3) (is_connected loc3 loc2)

    (valve_connect valve1 tank1 tank2) (valve_connect valve1 tank2 tank1)
    (valve_connect valve2 tank3 tank4) (valve_connect valve2 tank4 tank3)

    (monitor sensor1 tank1) (monitor sensor2 tank2)
    (monitor sensor3 tank3) (monitor sensor4 tank4)

    (is_open valve1)
    ;(is_open valve2)
    

    (can_torque adjustable_wrench)
    (has_size adjustable_wrench medium)
    (is_adjustable adjustable_wrench)
    (in_toolbox adjustable_wrench)
    (hand_empty)

    ;; ---------------- diagnostic knowledge base ----------------
    (applicable_test open_valve_test valve1)
    (applicable_test closed_valve_test valve2)
    (applicable_test sensor_self_test sensor1)
    (applicable_test sensor_self_test sensor2)
    (applicable_test sensor_self_test sensor3)
    (applicable_test sensor_self_test sensor4)
    (applicable_test sensor_self_test spare_sensor1)
    (applicable_test sensor_self_test spare_sensor2)
    (applicable_test sensor_comparison_test sensor1)
    (applicable_test sensor_comparison_test sensor2)
    (applicable_test sensor_comparison_test sensor3)
    (applicable_test sensor_comparison_test sensor4)
    (applicable_test sensor_comparison_test spare_sensor1)
    (applicable_test sensor_comparison_test spare_sensor2)

    
    (test_requires_symptom open_valve_test pressure_stable)
    (test_requires_symptom closed_valve_test pressure_changing)
    (test_requires_symptom sensor_self_test erratic_reading)
    (test_requires_symptom sensor_comparison_test pressure_stable)
    
    (test_requires_open open_valve_test)
    (test_requires_closed closed_valve_test)
    (test_requires_neighbor sensor_comparison_test)
    (unreliable_symptom erratic_reading)

    (test_indicates open_valve_test valve_stuck_fault)
    (test_indicates closed_valve_test valve_leak_fault)
    (test_indicates sensor_self_test sensor_crazy_fault)
    (test_indicates sensor_comparison_test sensor_dead_fault)

    (fault_prevents_movement valve_stuck_fault)
    (fault_prevents_movement valve_leak_fault)

    (fixed_by unstuck_fix valve_stuck_fault)
    (fixed_by tighten_fix valve_leak_fault)
    (fixed_by replace_fix sensor_crazy_fault)
    (fixed_by replace_fix sensor_dead_fault)

    (recovery_requires_torque unstuck_fix)
    (recovery_requires_torque tighten_fix)
    (recovery_requires_closed tighten_fix)
    (recovery_requires_spare replace_fix)

    (recovery_clears_symptom unstuck_fix pressure_stable)
    (recovery_sets_symptom unstuck_fix pressure_changing)
    (recovery_clears_symptom tighten_fix pressure_changing)
    (recovery_sets_symptom tighten_fix pressure_stable)
    (recovery_clears_symptom replace_fix erratic_reading)
    (recovery_clears_symptom replace_fix pressure_stable)
    (recovery_sets_symptom replace_fix pressure_changing)

    ;; ---------------- observed symptoms ----------------
    (shows sensor1 pressure_stable)
    (shows sensor2 pressure_changing)
    (shows sensor3 erratic_reading)
    (shows sensor4 pressure_changing)

)

(:goal (and
    (everything_ok)
    (hand_empty)
    (forall (?i - item) (or (not (in_toolbox ?i))
                            (= ?i adjustable_wrench)
    ))
))

)
