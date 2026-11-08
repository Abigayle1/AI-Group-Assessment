:- use_module(library(http/json)).
:- use_module(conditions).
:- dynamic road/9.
:- initialization(main, main).

main :-
    catch((json_read_dict(user_input, Request), dispatch(Request, Response)),
          Error, (message_to_string(Error, Message), Response = _{ok:false, error:Message})),
    json_write_dict(current_output, Response), nl.

dispatch(Request, Response) :-
    ( Request.action == "traversals" ->
        maplist(assert_road, Request.roads),
        maplist(atom_string, Options, Request.options),
        findall(_{source:S, destination:D, road_id:Id, distance:Dist, time:T},
                eligible_traversal(S, D, Options, Id, Dist, T), Edges),
        Response = _{ok:true, edges:Edges}
    ; Request.action == "condition_time" ->
        maplist(atom_string, Conditions, Request.conditions),
        effective_time(Request.base_time, Conditions, Time),
        Response = _{ok:true, time:Time}
    ; throw(error(domain_error(action, Request.action), _)) ).

assert_road(R) :-
    maplist(atom_string, [Id,S,D,Type,Status,Direction],
            [R.id,R.source,R.destination,R.type,R.status,R.direction]),
    maplist(atom_string, Conditions, R.conditions),
    assertz(road(Id,S,D,R.distance,R.time,Type,Conditions,Status,Direction)).
