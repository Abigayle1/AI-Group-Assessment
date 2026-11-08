:- module(conditions, [condition_penalty/2, effective_time/3, road_allowed/2, eligible_traversal/6]).
:- use_module(library(error)).

% One five-minute increase per road, even when both damage types occur.
condition_penalty(Conditions, Penalty) :-
    must_be(list, Conditions),
    ( (memberchk(broken_cistern, Conditions); memberchk(deep_pothole, Conditions))
    -> Penalty = 5 ; Penalty = 0 ).

effective_time(BaseTime, Conditions, Time) :-
    must_be(number, BaseTime),
    BaseTime >= 0,
    condition_penalty(Conditions, Penalty),
    Time is BaseTime + Penalty.

% Options: avoid_unpaved, avoid_broken_cisterns, avoid_deep_potholes.
% Closures are always excluded. Unknown options fail with an explicit error.
road_allowed(road(_, _, _, _, _, Type, Conditions, Status, _), Options) :-
    must_be(list, Options),
    maplist(valid_option, Options),
    Status == open,
    \+ (memberchk(avoid_unpaved, Options), Type == unpaved),
    \+ (memberchk(avoid_broken_cisterns, Options), memberchk(broken_cistern, Conditions)),
    \+ (memberchk(avoid_deep_potholes, Options), memberchk(deep_pothole, Conditions)).

valid_option(Option) :-
    ( memberchk(Option, [avoid_unpaved, avoid_broken_cisterns, avoid_deep_potholes])
    -> true ; domain_error(route_option, Option) ).

% Member 1 supplies user:road/9. Member 2 can use this traversal directly.
% eligible_traversal(Source, Destination, Options, RoadId, Distance, AdjustedTime).
eligible_traversal(Source, Destination, Options, Id, Distance, Time) :-
    user:road(Id, A, B, Distance, Base, Type, Conditions, Status, Direction),
    road_allowed(road(Id, A, B, Distance, Base, Type, Conditions, Status, Direction), Options),
    ( Source = A, Destination = B
    ; Direction == two_way, A \== B, Source = B, Destination = A ),
    effective_time(Base, Conditions, Time).
