/* ---------- Facts ---------- */
road(id(1), source(prospect),   destination(knollis),    distance(2),   time(5), type(paved),   conditions(deeppotholes),          status(open), direction(one-way)).
road(id(2), source(knollis),    destination(bogwalk),    distance(1),   time(2.5), type(unpaved), conditions(deeppotholes),  status(open), direction(two-way)).
road(id(3), source(knollis),    destination(linstead),   distance(10),   time(35), type(paved),   conditions(none),          status(open), direction(one-way)).
road(id(4), source(bogwalk),    destination(linstead),   distance(6.7),   time(18), type(unpaved), conditions(deeppotholes),  status(open), direction(one-way)).
road(id(5), source(bogwalk),    destination(angels),     distance(10),   time(26), type(unpaved), conditions(brokencisterns),status(open), direction(one-way)).
road(id(6), source(angels),     destination(spanishtown),distance(11),   time(28), type(paved),   conditions(deeppotholes),  status(open), direction(two-way)).
road(id(7), source(prospect),   destination(churchroad), distance(4.5),   time(10), type(unpaved), conditions(deeppotholes),  status(open), direction(two-way)).
road(id(8), source(churchroad), destination(linstead),   distance(3), time(7), type(paved),   conditions(brokencisterns),status(open), direction(one-way)).
road(id(9), source(linstead),   destination(ewarton),    distance(8), time(35), type(paved),   conditions(brokencisterns),status(open), direction(one-way)).
coord(prospect,    -76.9864,   18.1240).
coord(knollis,     -76.99427,   18.11585).
coord(bogwalk,     -77.00541,   18.10205).
coord(churchroad,  -76.99888, 18.11600).
coord(linstead,    -77.0449,   18.1403).
coord(angels,      -76.97391,  18.02435).
coord(spanishtown, -76.9574,  17.9911).
coord(ewarton,     -77.08536,   18.18333).

/* Roads usable in each direction; two-way roads work in reverse */
connected(A, B, D,T) :-
    road(id(_), source(A), destination(B), distance(D),
         time(T), type(_), conditions(_), status(open), direction(_)).
connected(A, B, D,T) :-
    road(id(_), source(B), destination(A), distance(D),
         time(T), type(_), conditions(_), status(open), direction(two-way)).

connected(A, B, D,T,C,S) :-
    road(id(_), source(A), destination(B), distance(D),
         time(_), type(T), conditions(C), status(S), direction(_)).

connected(A, B, D,T,C,S) :-
    road(id(_), source(B), destination(A), distance(D),
         time(_), type(T), conditions(C), status(S), direction(two-way)).




% Base case: destination reached. Visited is the (reversed) route, no more edges.
single_route(Destination, Destination, Visited, Visited, []).

% Recursive case: take a road, skip places already visited, keep going.
single_route(Origin, Destination, Visited, Route, [(Origin, Next, D)|RestEdges]) :-
   	connected(Origin,Next,D,_),
    \+ member(Next, Visited),
    single_route(Next, Destination, [Next|Visited], Route, RestEdges).

/* ---------- Wrapper: puts the route in travel order ---------- */
route_edges(Origin, Destination, Route, Edges) :-
    single_route(Origin, Destination, [Origin], RevRoute, Edges),
    reverse(RevRoute, Route).

/* ---------- Used to find the routes,edges per route,nodes and all edges ---------- */
routes(Origin, Destination, Routes, Nodes, EdgesPerRoute, Edges) :-
    findall(Route-RouteEdges,
            route_edges(Origin, Destination, Route, RouteEdges),
            Pairs),
    pairs_keys_values(Pairs, Routes, EdgesPerRoute),
    find_nodes(Routes, Nodes),
    find_edges(EdgesPerRoute, Edges).

find_nodes(Routes, Nodes) :-
    append(Routes, AllNodes),
    list_to_set(AllNodes, Nodes).

find_edges(EdgesPerRoute, Edges) :-
    append(EdgesPerRoute, AllEdges),
    list_to_set(AllEdges, Edges).


/* ---------- Shortest path ---------- */

/* dijkstra(+Start, +Goal, -Path, -Cost) */
dijkstra(Start, Goal, Path, Cost) :-
    dijkstra_([0-[Start]], Goal, [], RevPath, Cost),
    reverse(RevPath, Path).

% Cheapest candidate reaches the goal: finished.
dijkstra_([Cost-[Goal|Rest]|_], Goal, _, [Goal|Rest], Cost) :- !.

% Otherwise expand the cheapest candidate (or skip it if already settled).
dijkstra_([Cost-[Node|Rest]|Queue], Goal, Settled, Path, TotalCost) :-
    (   memberchk(Node, Settled)
    ->  dijkstra_(Queue, Goal, Settled, Path, TotalCost)
    ;   findall(NewCost-[Next,Node|Rest],
                ( connected(Node, Next, D, _),
                  \+ memberchk(Next, Settled),
                  NewCost is Cost + D ),
                NewEntries),
        append(Queue, NewEntries, Queue1),
        keysort(Queue1, SortedQueue),
        dijkstra_(SortedQueue, Goal, [Node|Settled], Path, TotalCost)
    ).

/* ---------- Fastest path ---------- */

/* quickestpath(+Start, +Goal, -Path, -Cost) */
quickestpath(Start, Goal, Path, Cost) :-
    quickestpath_([0-[Start]], Goal, [], RevPath, Cost),
    reverse(RevPath, Path).

% Cheapest candidate reaches the goal: finished.
quickestpath_([Cost-[Goal|Rest]|_], Goal, _, [Goal|Rest], Cost) :- !.

% Otherwise expand the cheapest candidate (or skip it if already settled).
quickestpath_([Cost-[Node|Rest]|Queue], Goal, Settled, Path, TotalCost) :-
    (   memberchk(Node, Settled)
    ->  quickestpath_(Queue, Goal, Settled, Path, TotalCost)
    ;   findall(NewCost-[Next,Node|Rest],
                ( connected(Node, Next, _, T),
                  \+ memberchk(Next, Settled),
                  NewCost is Cost + T ),
                NewEntries),
        append(Queue, NewEntries, Queue1),
        keysort(Queue1, SortedQueue),
        quickestpath_(SortedQueue, Goal, [Node|Settled], Path, TotalCost)
    ).


/* ----------------------------------------BFS,DFS & A*---------------------------------------- */

/* ---------- Avoid rules: rule_ok(Name, Type, Cond, Status) succeeds if road is acceptable ---------- */
rule_ok(not_unpaved,        Type, _,    _)      :- Type \== unpaved.
rule_ok(not_closed,         _,    _,    Status) :- Status \== closed.
rule_ok(no_brokencisterns, _,    Cond, _)      :- Cond \== brokencisterns.
rule_ok(no_deeppotholes,   _,    Cond, _)      :- Cond \== deeppotholes.

passes(Rules, Type, Cond, Status) :-
    forall(member(Rule, Rules), rule_ok(Rule, Type, Cond, Status)).

/* ---------- Terrain difficulty: cost multiplier for a road depending on condition,status and type---------- */
type_factor(paved,   1.0).
type_factor(unpaved, 1.5).

cond_factor(none,           0.0).
cond_factor(deeppotholes,   0.5).
cond_factor(brokencisterns, 0.3).

terrain_multiplier(Type, Cond, M) :-
    type_factor(Type, TF),
    cond_factor(Cond, CF),
    M is TF + CF.

/* ---------- Neighbour: check if roads connect,adhere to the rules and provides the distance and multiplier ---------- */
neighbour(Rules, A, B, D, M) :-
    connected(A, B, D, Type, Cond, Status),
    passes(Rules, Type, Cond, Status),
    terrain_multiplier(Type, Cond, M).

/* ====================== BFS (fewest roads) ====================== */
bfs(Rules, Start, Goal, Path) :-
    bfs_(Rules, [[Start]], Goal, [Start], RevPath),
    reverse(RevPath, Path).

bfs_(_, [[Goal|Rest]|_], Goal, _, [Goal|Rest]) :- !.
bfs_(Rules, [[Node|Rest]|Queue], Goal, Seen, Path) :-
    findall(Next,
            ( neighbour(Rules, Node, Next, _, _),
              \+ memberchk(Next, Seen) ),
            Found),
    list_to_set(Found, Nexts),
    append(Seen, Nexts, Seen1),
    findall([N, Node|Rest], member(N, Nexts), NewPaths),
    append(Queue, NewPaths, Queue1),          % new paths go to the BACK = BFS
    bfs_(Rules, Queue1, Goal, Seen1, Path).

/* ====================== DFS (any route, depth first) ====================== */
dfs(Rules, Start, Goal, Path) :-
    dfs_(Rules, Start, Goal, [Start], RevPath),
    reverse(RevPath, Path).

dfs_(_, Goal, Goal, Visited, Visited).
dfs_(Rules, Node, Goal, Visited, Path) :-
    neighbour(Rules, Node, Next, _, _),
    \+ memberchk(Next, Visited),
    dfs_(Rules, Next, Goal, [Next|Visited], Path).

/* ====================== A* (terrain-weighted cost + heuristic) ====================== */

h(Node, Goal, H) :-
    coord(Node, X1, Y1),
    coord(Goal, X2, Y2),
    H is sqrt((X1-X2)*(X1-X2) + (Y1-Y2)*(Y1-Y2)).

% astar(+Rules, +Start, +Goal, -Path, -Cost)
astar(Rules, Start, Goal, Path, Cost) :-
    h(Start, Goal, H0),
    astar_([H0-(0-[Start])], Rules, Goal, [], RevPath, Cost),
    reverse(RevPath, Path).

% Queue entries are F-(G-ReversedPath), where F = G + H.
astar_([_-(G-[Goal|Rest])|_], _, Goal, _, [Goal|Rest], G) :- !.
astar_([_-(G-[Node|Rest])|Queue], Rules, Goal, Closed, Path, Cost) :-
    (   memberchk(Node, Closed)
    ->  astar_(Queue, Rules, Goal, Closed, Path, Cost)
    ;   findall(F-(G1-[Next, Node|Rest]),
                ( neighbour(Rules, Node, Next, D, M),
                  \+ memberchk(Next, Closed),
                  G1 is G + D * M,            % terrain-weighted cost so far
                  h(Next, Goal, H),
                  F is G1 + H ),
                New),
        append(Queue, New, Queue1),
        keysort(Queue1, Sorted),
        astar_(Sorted, Rules, Goal, [Node|Closed], Path, Cost)
    ).

/* ====================== Main Function  ====================== */
main(Option, Origin, Destination, Rules,Path,Time,Distance) :-
     \+ dfs(Rules, Origin, Destination, _)
    ->  writeln('No routes found'), fail; 
    run(Option, Rules, Origin, Destination, Path),path_timedistance(Path,Distance,Time).
   
     

run(shortest, _,     O, D, Path) :- dijkstra(O, D, Path, _).
run(fastest,  _,     O, D, Path) :- quickestpath(O, D, Path, _).
run(astar,    Rules, O, D, Path) :- astar(Rules, O, D, Path, _).
run(bfs,      Rules, O, D, Path) :- bfs(Rules, O, D, Path).
run(dfs,      Rules, O, D, Path) :- dfs(Rules, O, D, Path).


path_timedistance([_], 0,0).
path_timedistance([A,B|Rest], Totald,Totalt) :-
    once(connected(A, B, D,T)),
    path_timedistance([B|Rest], SubTotalD,SubTotalT),
    Totald is D + SubTotalD,
    Totalt is T + SubTotalT.



