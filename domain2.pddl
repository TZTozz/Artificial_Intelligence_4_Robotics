(
    define (domain Orbital_domain_plus)

    (:requirements :strips :typing :negative-preconditions :quantified-preconditions :equality :disjunctive-preconditions :conditional-effects :fluents :time
    )

    (:types
        location size - object
        item - object
        component - item
        valve tank sensor - component
        tool - item
        fault symptom diagnostic_test recovery_action - object
    )

    (:constants
        pressure_changing pressure_stable erratic_reading - symptom
    )

    (:predicates
        ;; ---------------- spatial / structural ----------------
        (robot-at ?l - location)
        (component_at ?c - component ?l - location)
        (tank_at ?t - tank ?l - location)
        (is_connected ?l1 - location ?l2 - location)
        (valve_connect ?v - valve ?t1 - tank ?t2 - tank)
        (monitor ?s - sensor ?t - tank)
        (is_open ?v - valve)
        (has_size ?obj - object ?sz - size)
        (needs_isolation ?t - tank)
        (warehouse_location ?l - location)

        ;; ---------------- manipulation ----------------
        (hand_empty)
        (has_item ?i - item)
        (item_at ?i - item ?l - location)
        (in_toolbox ?i - item)
        (is_adjustable ?tool - tool)
        (can_torque ?tool - tool)
        (is_spare ?c - component)

        ;; ---------------- diagnostic knowledge base ----------------
        (applicable_test ?t - diagnostic_test ?c - component)
        (test_requires_symptom ?t - diagnostic_test ?sy - symptom)
        (test_requires_open ?t - diagnostic_test)
        (test_requires_closed ?t - diagnostic_test)
        (test_requires_neighbor ?t - diagnostic_test)
        (unreliable_symptom ?sy - symptom)
        (test_indicates ?t - diagnostic_test ?f - fault)
        (fault_prevents_movement ?f - fault)
        (fixed_by ?r - recovery_action ?f - fault)
        (recovery_requires_closed ?r - recovery_action)
        (recovery_requires_torque ?r - recovery_action)
        (recovery_requires_spare ?r - recovery_action)
        (recovery_clears_symptom ?r - recovery_action ?sy - symptom)
        (recovery_sets_symptom ?r - recovery_action ?sy - symptom)
        (checked ?s - sensor)

        ;; ---------------- dynamic diagnostic state ----------------
        (shows ?c - component ?sy - symptom)
        (test_done ?t - diagnostic_test ?c - component)
        (possible_fault ?c - component ?f - fault)
        (confirmed_fault ?c - component ?f - fault)
        (recovery_done ?r - recovery_action ?c - component)
        (component_ok ?c - component)

        ;---------------- collecting data ----------------

        (has_baseline ?s - sensor)

        ;; ---------------- real world state ----------------
        (is_broken ?s - sensor)
        (is_truly_open ?v - valve)


        (phase_1)
        (phase_2)
        (phase_3)
        (everything_ok)
    )


    (:functions
        (recorded_pressure ?s - sensor)
        (pressure ?t - tank)
        (time_recorded ?s - sensor)
        (time)
        (pressure_threshold)
        (flow_coefficient)
        (R_ammonia)
        (valve_opening ?v - valve)
        (volume ?t - tank)
        (mass ?t - tank)
        (temperature ?t - tank)
    )

    ;---------------------------- Collecting data -------------------------
    (:action take_baseline_reading
        :parameters (?s - sensor ?t - tank)
        :precondition (and 
            (or (phase_1) (phase_3))
            (monitor ?s ?t)
            (not (has_baseline ?s))
        )
        :effect (and 
            (has_baseline ?s)
            (assign (time_recorded ?s) (time))
            (when (not (is_broken ?s))
                (assign (recorded_pressure ?s) (pressure ?t))
            )
            (when (is_broken ?s)
                (assign (recorded_pressure ?s) 0.0)
            )
        )
    )



    (:action evaluate_pressure_changing
        :parameters (?s - sensor ?t - tank)
        :precondition (and 
            (or (phase_1) (phase_3))
            (monitor ?s ?t)
            (has_baseline ?s)
            (>= (- (time) (time_recorded ?s)) 3.0)
        )
        :effect (and 
            ; Sensor working and changing
            (when (and (not (is_broken ?s))
                       (or (> (- (pressure ?t) (recorded_pressure ?s)) (pressure_threshold))
                           (< (- (pressure ?t) (recorded_pressure ?s)) (- 0 (pressure_threshold)))))
                (and (shows ?s pressure_changing)
                     (not (shows ?s pressure_stable))
                )

            )
            ; Sensor working and stable
            (when (and (not (is_broken ?s))
                       (<= (- (pressure ?t) (recorded_pressure ?s)) (pressure_threshold))
                       (>= (- (pressure ?t) (recorded_pressure ?s)) (- 0 (pressure_threshold))))
                (and (shows ?s pressure_stable)
                     (not (shows ?s pressure_changing))
                )
            )
            ; Sensor broken
            (when (is_broken ?s) (shows ?s pressure_stable))

            (checked ?s)
            (not (has_baseline ?s)) 
        )

    )
    


    (:process tank_to_tank_flow
        :parameters (?t_src - tank ?t_dest - tank ?v - valve)
        :precondition (and 
            (or (valve_connect ?v ?t_src ?t_dest)
                (valve_connect ?v ?t_dest ?t_src))
            
            (> (valve_opening ?v) 0)             
            (> (pressure ?t_src) (pressure ?t_dest))
            
            (> (volume ?t_src) 0)
            (> (mass ?t_src) 0)
        )
        :effect (and 
            
            ;--------- Mass changes ----------------
            ; Flow rate = k * (P_src - P_dest) * opening
            
            (decrease (mass ?t_src)
                (* #t 
                (* (flow_coefficient) 
                    (* (- (pressure ?t_src) (pressure ?t_dest)) 
                        (valve_opening ?v)))
                )
            )
            
            (increase (mass ?t_dest)
                (* #t 
                (* (flow_coefficient) 
                    (* (- (pressure ?t_src) (pressure ?t_dest)) 
                        (valve_opening ?v)))
                )
            )

            ;--------- Pressure changes ----------------
            ; Rate of pressure change = (R * T / V) * flow_rate
            
            (decrease (pressure ?t_src)
                (* #t 
                (* (/ (* (R_ammonia) (temperature ?t_src)) (volume ?t_src))
                    (* (flow_coefficient) 
                        (* (- (pressure ?t_src) (pressure ?t_dest)) 
                            (valve_opening ?v))))
                )
            )
            
            (increase (pressure ?t_dest)
                (* #t 
                (* (/ (* (R_ammonia) (temperature ?t_dest)) (volume ?t_dest))
                    (* (flow_coefficient) 
                        (* (- (pressure ?t_src) (pressure ?t_dest)) 
                            (valve_opening ?v))))
                )
            )
        )
    )


    (:process advance_time
        :parameters ()
        :precondition (and (>= (time) 0.0)
                           (exists (?s - sensor) (has_baseline ?s)))
        :effect (increase (time) (* #t 1.0))
    )

    


    ; --------------------------- Diagnostic reasoning -------------------------
    ;-----------start-----------
    (:action run_diagnostic_valve_stuck
        :parameters (?v - valve ?t1 ?t2 - tank ?s1 ?s2 - sensor ?test - diagnostic_test ?f - fault ?sy - symptom)
        :precondition (and 
            (applicable_test ?test ?v)
            (not (test_done ?test ?v))
            (test_indicates ?test ?f) 
            (test_requires_symptom ?test ?sy) 
            
            (valve_connect ?v ?t1 ?t2)
            (monitor ?s1 ?t1)
            (monitor ?s2 ?t2)
            (or (not (test_requires_open ?test)) (is_open ?v))
            (or (not (test_requires_closed ?test)) (not (is_open ?v)))

            (shows ?s1 ?sy)
            (shows ?s2 ?sy)
        )
        :effect (and 
            (possible_fault ?v ?f)
            (test_done ?test ?v)
        )
    )

    (:action run_diagnostic_valve_single_sensor
        :parameters (?v - valve ?t1 ?t2 - tank ?s ?s_other - sensor ?test - diagnostic_test ?f - fault ?sy ?sy_other - symptom)
        :precondition (and
            (applicable_test ?test ?v)
            (not (test_done ?test ?v))
            (test_indicates ?test ?f)
            (test_requires_symptom ?test ?sy)

            (valve_connect ?v ?t1 ?t2)
            (monitor ?s ?t1)
            (monitor ?s_other ?t2)
            (or (not (test_requires_open ?test)) (is_open ?v))
            (or (not (test_requires_closed ?test)) (not (is_open ?v)))

            (shows ?s ?sy)
            (shows ?s_other ?sy_other)
            (unreliable_symptom ?sy_other)
        )
        :effect (and
            (possible_fault ?v ?f)
            (test_done ?test ?v)
        )
    )

    (:action run_diagnostic_sensor_discrepancy
        :parameters (?s_faulty ?s_ok - sensor ?v - valve ?t1 ?t2 - tank ?test - diagnostic_test ?f - fault ?sy_faulty ?sy_ok - symptom)
        :precondition (and 
            (phase_1)
            (applicable_test ?test ?s_faulty)
            (not (test_done ?test ?s_faulty))
            (test_indicates ?test ?f)
            (test_requires_symptom ?test ?sy_faulty)
            (test_requires_neighbor ?test)

            (is_open ?v) 
            (valve_connect ?v ?t1 ?t2)
            (monitor ?s_faulty ?t1)
            (monitor ?s_ok ?t2)

            (shows ?s_faulty ?sy_faulty)
            (shows ?s_ok ?sy_ok)
            (not (= ?sy_faulty ?sy_ok))
        )
        :effect (and 
            (possible_fault ?s_faulty ?f)
            (test_done ?test ?s_faulty)
        )
    )


    (:action run_diagnostic_sensor_self
        :parameters (?s - sensor ?test - diagnostic_test ?f - fault ?sy - symptom)
        :precondition (and
            (applicable_test ?test ?s)
            (not (test_done ?test ?s))
            (test_indicates ?test ?f)
            (test_requires_symptom ?test ?sy)
            (not (test_requires_neighbor ?test))

            (shows ?s ?sy)
        )
        :effect (and
            (possible_fault ?s ?f)
            (test_done ?test ?s)
        )
    )


    ;--------------clear-------------
    (:action run_diagnostic_valve_clear
        :parameters (?v - valve ?t1 ?t2 - tank ?s1 ?s2 - sensor ?test - diagnostic_test ?sy_fault - symptom)
        :precondition (and 
            (applicable_test ?test ?v)
            (not (test_done ?test ?v))
            (test_requires_symptom ?test ?sy_fault)
            
            (valve_connect ?v ?t1 ?t2)
            (monitor ?s1 ?t1)
            (monitor ?s2 ?t2)

            (or (not (test_requires_open ?test)) (is_open ?v))
            (or (not (test_requires_closed ?test)) (not (is_open ?v)))

            (not (shows ?s1 ?sy_fault))
            (not (shows ?s2 ?sy_fault))
        )
        :effect (and 
            (test_done ?test ?v)
        )
    )

    (:action run_diagnostic_sensor_clear
        :parameters (?s_target ?s_other - sensor ?v - valve ?t1 ?t2 - tank ?test - diagnostic_test ?sy_fault - symptom)
        :precondition (and 
            (applicable_test ?test ?s_target)
            (not (test_done ?test ?s_target))
            (test_requires_symptom ?test ?sy_fault)
            (test_requires_neighbor ?test)
            
            ;(is_open ?v)
            (valve_connect ?v ?t1 ?t2)
            (monitor ?s_target ?t1)
            (monitor ?s_other ?t2)

            (checked ?s_target)
            (checked ?s_other)

            (or (not (shows ?s_target ?sy_fault)) (shows ?s_other ?sy_fault))
        )
        :effect (and 
            (test_done ?test ?s_target)
        )
    )

    (:action run_diagnostic_sensor_self_clear
        :parameters (?s - sensor ?v - valve ?t1 ?t2 - tank ?test - diagnostic_test ?sy - symptom)
        :precondition (and
            (applicable_test ?test ?s)
            (checked ?s)
            (not (test_done ?test ?s))
            (valve_connect ?v ?t1 ?t2)
            (monitor ?s ?t1)
            (test_requires_symptom ?test ?sy)
            (not (test_requires_neighbor ?test))

            (not (shows ?s ?sy))
        )
        :effect (and
            (test_done ?test ?s)
        )
    )


    ;------------------confirm or rule out faults----------------
    (:action confirm_fault
        :parameters (?c - component ?f - fault)
        :precondition (and
            (phase_1)
            (possible_fault ?c ?f)
            (not (confirmed_fault ?c ?f))
            (forall (?t - diagnostic_test)
                (or (not (applicable_test ?t ?c)) (test_done ?t ?c)))
        )
        :effect (and
            (confirmed_fault ?c ?f)
            (not (phase_1))
            (phase_2)
        )
    )


    (:action rule_out_fault
        :parameters (?c - component)
        :precondition (and
            (not (component_ok ?c))
            (forall (?s - sensor) (or (not (= ?c ?s)) (not (is_broken ?s))))
            (not (exists (?f - fault) (or (possible_fault ?c ?f) (confirmed_fault ?c ?f))))
            (forall (?t - diagnostic_test)
                (or (not (applicable_test ?t ?c)) (test_done ?t ?c)))
        )
        :effect (and
            (component_ok ?c)
        )
    )



    ; ------------------ Recovery actions ------------------

    (:action apply_mechanical_recovery
        :parameters (?r - recovery_action ?f - fault ?v - valve ?l - location ?tool - tool ?size_needed - size ?s1 ?s2 - sensor ?t1 ?t2 - tank ?sy_old ?sy_new - symptom)
        :precondition (and
            (confirmed_fault ?v ?f)
            (fixed_by ?r ?f)
            (recovery_requires_torque ?r)
            (component_at ?v ?l)
            (robot-at ?l)
            (has_item ?tool)
            (can_torque ?tool)
            (has_size ?tool ?size_needed)
            (has_size ?v ?size_needed)
            (or (not (recovery_requires_closed ?r)) (not (is_open ?v)))
            (valve_connect ?v ?t1 ?t2)
            (monitor ?s1 ?t1)
            (monitor ?s2 ?t2)
            (recovery_clears_symptom ?r ?sy_old)
            (recovery_sets_symptom ?r ?sy_new)
        )
        :effect (and
            (not (confirmed_fault ?v ?f))
            (not (possible_fault ?v ?f))
            (recovery_done ?r ?v)
            (not (shows ?s1 ?sy_old))
            (shows ?s1 ?sy_new)
            (not (shows ?s2 ?sy_old))
            (shows ?s2 ?sy_new)
            (forall (?t - diagnostic_test) (and (not (test_done ?t ?v))))
        )
    )

    (:action apply_replacement_recovery
        :parameters (?r - recovery_action ?f - fault ?s_old ?s_new - sensor ?t - tank ?l - location ?sy_old ?sy_new - symptom)
        :precondition (and
            (phase_2)
            (confirmed_fault ?s_old ?f)
            (fixed_by ?r ?f)
            (recovery_requires_spare ?r)
            (robot-at ?l)
            (tank_at ?t ?l)
            (monitor ?s_old ?t)
            (has_item ?s_new)
            (is_spare ?s_new)
            (forall (?v - valve ?t_other - tank)
                (or (not (valve_connect ?v ?t ?t_other))
                    (not (is_open ?v))))
            (shows ?s_old ?sy_old)
            (recovery_clears_symptom ?r ?sy_old)
            (recovery_sets_symptom ?r ?sy_new)
        )
        :effect (and
            (not (confirmed_fault ?s_old ?f))
            (not (possible_fault ?s_old ?f))
            (not (monitor ?s_old ?t))
            (monitor ?s_new ?t)
            (not (has_item ?s_new))
            (has_item ?s_old)
            (not (needs_isolation ?t))
            (recovery_done ?r ?s_new)
            (forall (?t2 - diagnostic_test)
                (and (not (test_done ?t2 ?s_old))))
            (not (shows ?s_old ?sy_old))
            (shows ?s_new ?sy_new)
            (not (phase_2))
            (phase_3)
        )
    )


    
    (:action verify_repair
        :parameters (?c - component ?r - recovery_action ?f - fault)
        :precondition (and
            (phase_3)
            (recovery_done ?r ?c)
            (fixed_by ?r ?f)
            (not (exists (?f2 - fault) (or (possible_fault ?c ?f2) (confirmed_fault ?c ?f2))))
            (forall (?t - diagnostic_test)
                (or (not (applicable_test ?t ?c)) (test_done ?t ?c)))
        )
        :effect (and
            (component_ok ?c)
            (not (recovery_done ?r ?c))
        )
    )



    ; ------------------ Robot actions ------------------
    (:action move
        :parameters (?l1 ?l2 - location)
        :precondition (and
            (robot-at ?l1)
            (is_connected ?l1 ?l2)
        )
        :effect (and
            (not (robot-at ?l1))
            (robot-at ?l2)
        )
    )

    (:action close_valve
        :parameters (?v - valve ?l - location ?t1 ?t2 - tank)
        :precondition (and
            (or (phase_2) (phase_3))
            (robot-at ?l)
            (component_at ?v ?l)
            (is_open ?v)
            (hand_empty)
            (not (exists (?f - fault) (and (confirmed_fault ?v ?f) (fault_prevents_movement ?f))))
            (valve_connect ?v ?t1 ?t2)
            
        )
        :effect (and
            (not (is_open ?v))
            (assign (valve_opening ?v) 0.0)
        )
    )


    (:action open_valve
        :parameters (?v - valve ?l - location ?t1 ?t2 - tank)
        :precondition (and
            (phase_3)
            (robot-at ?l)
            (component_at ?v ?l)
            (valve_connect ?v ?t1 ?t2)
            (not (is_open ?v))
            (hand_empty)
            (not (exists (?f - fault) 
                (and 
                     (or (confirmed_fault ?v ?f) (possible_fault ?v ?f)) 
                     (fault_prevents_movement ?f)
                )
            ))
            (forall (?test - diagnostic_test)
                (or 
                     (not (applicable_test ?test ?v))
                     (not (test_requires_closed ?test))
                     (test_done ?test ?v)
                )
            )
        )
        :effect (and
            (is_open ?v)
            (assign (valve_opening ?v) 1.0)
        )
    )



    ;; -------- Manipulate object actions --------
    (:action pick_up_item
        :parameters (?item - item ?l - location)
        :precondition (and
            (phase_2)
            (robot-at ?l)
            (item_at ?item ?l)
            (hand_empty)
        )
        :effect (and
            (not (hand_empty))
            (has_item ?item)
            (not (item_at ?item ?l))
        )
    )


    (:action release_item
        :parameters (?item - item ?l - location)
        :precondition (and
            (or (phase_2) (phase_3))
            (has_item ?item)
            (robot-at ?l)
            (warehouse_location ?l)
        )
        :effect (and
            (not (has_item ?item))
            (item_at ?item ?l)
            (hand_empty)
        )
    )



    (:action adjust_tool
        :parameters (?tool - tool ?comp - object ?tool_size - size ?comp_size - size)
        :precondition (and
            (is_adjustable ?tool)
            (has_item ?tool)
            (has_size ?tool ?tool_size)
            (has_size ?comp ?comp_size)
            (not (= ?tool_size ?comp_size))
        )
        :effect (and
            (not (has_size ?tool ?tool_size))
            (has_size ?tool ?comp_size)
        )
    )

    (:action equip_from_toolbox
        :parameters (?i - item)
        :precondition (and
            (in_toolbox ?i)
            (hand_empty)
        )
        :effect (and
            (not (in_toolbox ?i))
            (has_item ?i)
            (not (hand_empty))
        )
    )

    (:action stow_in_toolbox
        :parameters (?i - item)
        :precondition (and
            (has_item ?i)
        )
        :effect (and
            (not (has_item ?i))
            (in_toolbox ?i)
            (hand_empty)
        )
    )


    ;--------- Everything is ok ----------
    (:action checking_everything
        :parameters ()
        :precondition (and
            (forall (?v - valve) (component_ok ?v))
            (forall (?s - sensor)
                (or (not (exists (?t - tank) (monitor ?s ?t))) (component_ok ?s)))
        )
        :effect (and
            (everything_ok))
    )

)
