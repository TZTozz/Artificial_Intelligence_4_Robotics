(
    define (domain Orbital_domain)
    
    (:requirements :strips :typing :negative-preconditions :quantified-preconditions)

    (:types
        location
        valve
        tank
        sensor
    )

    (:predicates
        (robot-at ?l - location)
        (is_connected ?l1 - location ?l2 - location)
        (valve_at ?v - valve ?l - location)
        (tank_at ?t - tank ?l - location)
        (valve_connect ?v - valve ?t1 - tank ?t2 - tank)
        (is_open ?v - valve)

        (changing_pressure ?s - sensor)
        (monitor ?s - sensor ?t - tank)

        (needs_sensor_replacement ?s - sensor)
        (needs_unstuck_valve ?v - valve)

        (valve_ok ?v - valve)                       ; Problem solved
        (sensor_ok ?s - sensor)


        (everything_ok)

    )


    ; ------------- Diagnostic action --------------

    ; ---- Valve diagnostic ------
    ; If the valve is open and the pressure in the first one is not changing triggers the checking of the second tank
    (:action start_pressure_sensor_diagnostic
        :parameters (?v - valve ?t1 ?t2 - tank ?s1 ?s2 - sensor)
        :precondition (and 
            (is_open ?v) 
            (valve_connect ?v ?t1 ?t2)
            (monitor ?s1 ?t1)
            (monitor ?s2 ?t2)
            (not (valve_ok ?v))

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
        :parameters (?v - valve ?l - location ?t1 ?t2 - tank ?s1 ?s2 - sensor)
        :precondition (and 
            (needs_unstuck_valve ?v)
            (valve_at ?v ?l)
            (valve_connect ?v ?t1 ?t2)
            (monitor ?s1 ?t1)
            (monitor ?s2 ?t2)
            (robot-at ?l))
        :effect (and
            (not (needs_unstuck_valve ?v))
            (changing_pressure ?s1)
            (changing_pressure ?s2))
    )

    (:action replace_pressure_sensor
        :parameters (?t - tank ?l - location ?s - sensor)
        :precondition (and 
            (robot-at ?l)
            (tank_at ?t ?l)
            (monitor ?s ?t)
            (needs_sensor_replacement ?s))
        :effect (and 
            (not (needs_sensor_replacement ?s))
            (changing_pressure ?s))
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
        :parameters ()
        :precondition (and 
            (forall (?v - valve) (valve_ok ?v))
            (forall (?s - sensor) (sensor_ok ?s)))
        :effect (and 
            (everything_ok))
    )
    


    
)