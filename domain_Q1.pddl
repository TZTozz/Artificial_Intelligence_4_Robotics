(
    define (domain Orbital_domain_Q1)

    (:requirements :strips :typing :negative-preconditions :quantified-preconditions :equality :disjunctive-preconditions :conditional-effects)

    (:types
        location size - object
        item - object
        component - item
        valve tank sensor - component
        tool - item
        fault symptom diagnostic_test recovery_action - object
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
        (warehause_location ?l - location)

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

        ;; ---------------- dynamic diagnostic state ----------------
        (shows ?c - component ?sy - symptom)
        (test_done ?t - diagnostic_test ?c - component)
        (possible_fault ?c - component ?f - fault)
        (confirmed_fault ?c - component ?f - fault)
        (recovery_done ?r - recovery_action ?c - component)
        (component_ok ?c - component)

        (everything_ok)
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
            (possible_fault ?c ?f)
            (not (confirmed_fault ?c ?f))
            (forall (?t - diagnostic_test)
                (or (not (applicable_test ?t ?c)) (test_done ?t ?c)))
        )
        :effect (and
            (confirmed_fault ?c ?f)
        )
    )

    (:action rule_out_fault
        :parameters (?c - component)
        :precondition (and
            (not (component_ok ?c))
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
        )
    )

    
    (:action verify_repair
        :parameters (?c - component ?r - recovery_action ?f - fault)
        :precondition (and
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
            (robot-at ?l)
            (component_at ?v ?l)
            (is_open ?v)
            (hand_empty)
            (not (exists (?f - fault) (and (confirmed_fault ?v ?f) (fault_prevents_movement ?f))))
            (valve_connect ?v ?t1 ?t2)
            
        )
        :effect (and
            (not (is_open ?v))
        )
    )

    (:action open_valve
        :parameters (?v - valve ?l - location ?t1 ?t2 - tank)
        :precondition (and
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
        )
    )


    ;; -------- Manipulate object actions --------
    (:action pick_up_item
        :parameters (?item - item ?l - location)
        :precondition (and
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
            (has_item ?item)
            (robot-at ?l)
            (warehause_location ?l)
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
