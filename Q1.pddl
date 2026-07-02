(define (problem Q1) (:domain Orbital_domain)
(:objects
    loc1 loc2 loc3 - location
    valve1 - valve
    tank1 tank2 - tank
)

(:init
    (robot-at loc1)
    (valve_at valve1 loc3)
    (is_connected loc1 loc2) (is_connected loc2 loc3)
    (valve_connect valve1 tank1 tank2)
    (is_open valve1)
    (changing_pressure tank2)
)

(:goal (and
    (valve_ok valve1)
))

;un-comment the following line if metric is needed
;(:metric minimize (???))
)
