(
    define (domain Orbital_domain)
    
    (:requirements :strips :typing :negative-preconditions)

    (:types
        location
        valve
        tank

    )

    (:predicates
        (robot-at ?l - location)
        (is_connected ?l1 - location ?l2 - location)
        (valve_at ?v ?l)
        (valve_connect ?v - valve ?t_from - tank ?t_to - tank)
        (is_open ?v - valve)
        (changing_pressure ?t - tank)

        (needs_checking ?t - tank ?v - valve)
        (needs_sensor_replacement ?t - tank)
        (needs_unstuck_valve ?v - valve)
        (diagnosis_valve_complete ?v - valve)       ; Discovered the problem
        (valve_ok ?v - valve)                       ; Problem solved

        (everything_ok)

    )


    ; ------------- Diagnostic action --------------

    ; ---- Valve diagnostic ------
    ; If the valve is open and the pressure in the first one is not changing triggers the checking of the second tank
    (:action trigger_second_tank
        :parameters (?v - valve ?t_from - tank ?t_to - tank)
        :precondition (and 
            (is_open ?v) 
            (valve_connect ?v ?t_from ?t_to)
            (not (changing_pressure ?t_from))
            (not (needs_checking ?t_to ?v))
            (not (valve_ok ?v)))
        :effect (and 
            (needs_checking ?t_to ?v))
    )

    (:action diagnose_pressure_sensor
        :parameters (?v - valve ?t_from - tank ?t_to - tank)
        :precondition (and 
            (valve_connect ?v ?t_from ?t_to)
            (needs_checking ?t_to ?v)
            (changing_pressure ?t_to))
        :effect (and 
            (not (needs_checking ?t_to ?v))
            (needs_sensor_replacement ?t_from)
            (diagnosis_valve_complete ?v))
    )

    (:action diagnose_valve_stuck
        :parameters (?v - valve ?t_from - tank ?t_to - tank)
        :precondition (and 
            (valve_connect ?v ?t_from ?t_to)
            (needs_checking ?t_to ?v)
            (not (changing_pressure ?t_to)))
        :effect (and 
            (not (needs_checking ?t_to ?v))
            (needs_unstuck_valve ?v)
            (diagnosis_valve_complete ?v))
    )
    
    ; ------------- Physical action --------------  
    (:action unstuck_valve
        :parameters (?v - valve ?l - location)
        :precondition (and 
            (needs_unstuck_valve ?v)
            (valve_at ?v ?l)
            (robot-at ?l))
        :effect (and 
            (valve_ok ?v)
            (not (needs_unstuck_valve ?v)))
    )

    (:action replace_pressure_sensor
        :parameters (?t - tank ?l - location)
        :precondition (and 
            (robot-at ?l)
            (tank_at ?t ?l)
            (needs_sensor_replacement ?t))
        :effect (and 
            (not (needs_sensor_replacement ?t))
            (valve_ok))             ;; Qui mettere il fatto che deve rifare il check e vedere sìcome rendere più generale il ripiazzamento
    )
    

    (:action move
        :parameters (?l1 ?l2 - location)
        :precondition (and 
            (robot-at ?l1)
            (is_connected ?l1 ?l2))
        :effect (and
            (not (robot-at ?l1))
            (robot-at ?l2))
    )
    

    ;----- Evrithing is ok -----
    (:action checking_everything
        :parameters (?v - valve)
        :precondition (and 
            (valve_ok ?v))
        :effect (and 
            (everything_ok))
    )
    


    
)