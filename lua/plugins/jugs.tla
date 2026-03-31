---- MODULE jugs ----
EXTENDS Integers

VARIABLES big, small

TypeOK == big \in 0..5 /\ small \in 0..3

Init == big = 0 /\ small = 0

FillBig    == big' = 5      /\ small' = small
FillSmall  == big' = big    /\ small' = 3
EmptyBig   == big' = 0      /\ small' = small
EmptySmall == big' = big    /\ small' = 0

SmallToBig ==
  IF big + small <= 5
    THEN /\ big' = big + small /\ small' = 0
    ELSE /\ big' = 5           /\ small' = big + small - 5

BigToSmall ==
  IF big + small <= 3
    THEN /\ big' = 0               /\ small' = big + small
    ELSE /\ big' = big + small - 3 /\ small' = 3

Next == FillBig \/ FillSmall \/ EmptyBig \/ EmptySmall \/ SmallToBig \/ BigToSmall

Spec == Init /\ [][Next]_<<big, small>>

NotFour == big /= 4

====
