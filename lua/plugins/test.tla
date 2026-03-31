  ---- MODULE test ----
  EXTENDS Integers
  VARIABLES big, small

  TypeOK == big \in 0..5 /\ small \in 0..3

  Init == big = 0 /\ small = 3

  Next ==
    IF big + small <= 5
      THEN /\ big' = big + small
           /\ small' = 0
      ELSE /\ big' = big
           /\ small' = small - 1

  Spec == Init /\ [][Next]_<<big, small>>
  ====
