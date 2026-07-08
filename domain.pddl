(
    define (domain Orbital_domain)
    
    (:requirements :strips :typing :negative-preconditions :quantified-preconditions :equality :disjunctive-preconditions )

    (:types
        location valve tank size - object
        item - object
        tool sensor - item
    )

    (:predicates
        (robot-at ?l - location)

        (valve_at ?v - valve ?l - location)
        (is_connected ?l1 - location ?l2 - location)
        (tank_at ?t - tank ?l - location)
        (valve_connect ?v - valve ?t1 - tank ?t2 - tank)
        (is_open ?v - valve)

        (changing_pressure ?s - sensor)
        (monitor ?s - sensor ?t - tank)

        (needs_sensor_replacement ?s - sensor)
        (needs_unstuck_valve ?v - valve)

        (valve_ok ?v - valve)                       ; Problem solved
        (sensor_ok ?s - sensor)

        (hand_empty)
        (has_item ?item - item)
        (item_at ?i - item ?l - location)
        (in_toolbox ?i - item)
        (is_adjustable ?tool - tool)
        (can_torque ?tool - tool)

        (has_size ?obj - object ?s - size)

        (is_spare ?s - sensor)

        (everything_ok)

    )


    ; ------------- Diagnostic action --------------

    ; ---- Valve diagnostic ------
    (:action start_pressure_sensor_diagnostic
        :parameters (?v - valve ?t1 ?t2 - tank ?s1 ?s2 - sensor)
        :precondition (and 
            (is_open ?v) 
            (valve_connect ?v ?t1 ?t2)
            (monitor ?s1 ?t1)
            (monitor ?s2 ?t2)
            (not (valve_ok ?v))
            (not (needs_sensor_replacement ?s1))

            (not (changing_pressure ?s1))
            (changing_pressure ?s2))
        :effect (and 
            (needs_sensor_replacement ?s1))
    )

    (:action start_valve_diagnostic
        :parameters (?v - valve ?t1 ?t2 - tank ?s1 ?s2 - sensor)
        :precondition (and 
            (is_open ?v) 
            (valve_connect ?v ?t1 ?t2)
            (monitor ?s1 ?t1)
            (monitor ?s2 ?t2)
            (not (valve_ok ?v))
            (not (needs_unstuck_valve ?v))

            (not (changing_pressure ?s1))
            (not (changing_pressure ?s2)))
        :effect (and 
            (needs_unstuck_valve ?v))
    )


    (:action valve_diagnostic_ok
        :parameters (?v - valve ?t1 ?t2 - tank ?s1 ?s2 - sensor)
        :precondition (and 
            (is_open ?v) 
            (valve_connect ?v ?t1 ?t2)
            (monitor ?s1 ?t1)
            (monitor ?s2 ?t2)
            (not (valve_ok ?v))

            (changing_pressure ?s1)
            (changing_pressure ?s2))
        :effect (and 
            (valve_ok ?v)
            (sensor_ok ?s1)
            (sensor_ok ?s2))
    )
    

    
    ; ------------- Physical action --------------  
    (:action unstuck_valve
        :parameters (?v - valve ?l - location ?t1 ?t2 - tank ?s1 ?s2 - sensor ?tool - tool ?size_needed - size)
        :precondition (and 
            (needs_unstuck_valve ?v)
            (valve_at ?v ?l)
            (valve_connect ?v ?t1 ?t2)
            (monitor ?s1 ?t1)
            (monitor ?s2 ?t2)
            (robot-at ?l)
            (has_item ?tool)
            (can_torque ?tool)
            (has_size ?tool ?size_needed)
            (has_size ?v ?size_needed)
            )
        :effect (and
            (not (needs_unstuck_valve ?v))
            (changing_pressure ?s1)
            (changing_pressure ?s2)
            )
    )

    (:action replace_pressure_sensor
        :parameters (?t - tank ?l - location ?old_s ?new_s - sensor)
        :precondition (and 
            (robot-at ?l)
            (tank_at ?t ?l)
            (monitor ?old_s ?t)
            (needs_sensor_replacement ?old_s)
            (has_item ?new_s)
            (is_spare ?new_s)
            )
        :effect (and 
            (not (needs_sensor_replacement ?old_s))
            (not (monitor ?old_s ?t))
            (monitor ?new_s ?t)
            (not (has_item ?new_s))
            (hand_empty)
            (changing_pressure ?new_s))
    )
    

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
        :parameters (?v - valve ?l - location)
        :precondition (and 
            (robot-at ?l)
            (valve_at ?v ?l)
            (is_open ?v)
            (hand_empty)
            (not (needs_unstuck_valve ?v))
        )
        :effect (and 
            (not (is_open ?v))
        )
    )

    (:action open_valve
        :parameters (?v - valve ?l - location)
        :precondition (and 
            (robot-at ?l)
            (valve_at ?v ?l)
            (not (is_open ?v))
            (hand_empty)
            (not (needs_unstuck_valve ?v))
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
    
    

    ;----- Evrithing is ok -----
    (:action checking_everything
        :parameters ()
        :precondition (and 
            (forall (?v - valve) (valve_ok ?v))
            ;(forall (?s - sensor ?t - tank) (imply (monitor ?s ?t) (sensor_ok ?s)))
            )
        :effect (and 
            (everything_ok))
    )
    


    
)