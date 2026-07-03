(define (problem Q1) (:domain Orbital_domain)
(:objects
    loc1 loc2 loc3 - location
    valve1 valve2 - valve
    tank1 tank2 tank3 - tank
)

(:init
    (robot-at loc1)
    (valve_at valve1 loc3)
    (valve_at valve2 loc2)
    (tank_at tank1 loc2) (tank_at tank2 loc3) (tank_at tank3 loc1)

    (is_connected loc1 loc2) (is_connected loc2 loc1)
    (is_connected loc2 loc3) (is_connected loc3 loc2)

    (valve_connect valve1 tank1 tank2)
    (valve_connect valve2 tank2 tank3)
    (is_open valve1)
    (is_open valve2)

    (changing_pressure tank2)
    
)

(:goal (and
    (everything_ok)
))

)
