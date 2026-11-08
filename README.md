# Member 4 implementation

This component connects Python to Prolog and applies road conditions and restrictions. The sample demonstration is independent of the other members' code. It does not yet find a complete route or provide the GUI and saved road database.

## Run

Python and SWI-Prolog must be installed. No pip packages are needed.

```powershell
python demo_member4.py
python -m unittest discover -s tests -v
```

`integration.py` exposes `PrologClient.condition_time(base_time, conditions)` and `PrologClient.eligible_edges(roads, options)`. Errors are `ValueError` for invalid inputs and `IntegrationError` for runtime problems; the GUI should display these messages. Calls are synchronous, so Member 3 should run them in a worker thread and update Tkinter widgets on its main thread.

## Proposed interface for team agreement

Roads use `road(Id, Source, Destination, Distance, Time, Type, Conditions, Status, Direction)` in Prolog. Python uses dictionaries with `id`, `source`, `destination`, `distance`, `time`, `type`, `conditions`, `status`, `direction`. Distance and base time are nonnegative numbers, measured in kilometres and minutes respectively. IDs must be unique.

- Type: `paved` or `unpaved`.
- Conditions: a list containing `broken_cistern` and/or `deep_pothole`, or an empty list.
- Status: `open` or `closed`; closed roads are always excluded.
- Direction: `one_way` (source to destination) or `two_way`.
- Options: `avoid_unpaved`, `avoid_broken_cisterns`, `avoid_deep_potholes`.

The damage penalty is five minutes once per road, including when both conditions occur. Stored time remains the base time; calculating repeatedly never adds the penalty again. Confirm this interpretation with the team/lecturer before final integration.

Exported Prolog predicates in `prolog/conditions.pl`:

```prolog
condition_penalty(Conditions, Penalty).
effective_time(BaseTime, Conditions, AdjustedTime).
road_allowed(RoadTerm, Options).
eligible_traversal(Source, Destination, Options, RoadId, Distance, AdjustedTime).
```

Member 1 must supply `user:road/9` for direct use of `eligible_traversal/6`; if their database uses a module, adapt the explicit `user:road/9` call together. Member 2 can use this traversal to search only eligible edges and optimize either distance or adjusted time. Their `find_route/6` argument order and result format still need agreement. Member 3 can import `PrologClient` from the GUI. All strings cross the bridge as JSON data rather than executable Prolog queries.

## Remaining integration work

1. Connect Member 1's load/add/update/save operations; verify changes survive restarting the application. The current bridge holds sample roads only for one request and does not persist them.
2. Connect Member 2's route predicate and expose a Python `find_route` method after agreeing the signature, route totals, unknown-location errors, and no-route response.
3. Connect Member 3's Find Route and administrator actions, then test GUI validation and error display.
4. Verify shortest versus fastest routes, every avoidance option, one-way roads, closures, damage changes, and no-route scenarios through the full application.
5. Compile the demonstration, user manual, contribution report, lessons learned, and authorship declaration using the final application.

The automated tests currently exercise the real Python–Prolog connection, condition penalties, directional traversal, exclusions, changed in-memory road data, invalid inputs, empty results, and process failure reporting. They do not establish complete route correctness, GUI behavior, or persistence.
