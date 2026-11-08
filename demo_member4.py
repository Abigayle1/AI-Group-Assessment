"""Run with: python demo_member4.py"""
from integration import PrologClient

SAMPLE_ROADS = [
    dict(id="r001", source="village_a", destination="village_b", distance=5,
         time=10, type="paved", conditions=["deep_pothole"], status="open", direction="two_way"),
    dict(id="r002", source="village_b", destination="village_c", distance=3,
         time=6, type="unpaved", conditions=[], status="open", direction="one_way"),
    dict(id="r003", source="village_a", destination="village_c", distance=2,
         time=4, type="paved", conditions=[], status="closed", direction="two_way"),
]

if __name__ == "__main__":
    client = PrologClient()
    print("Allowed connections (closed roads excluded; damaged road takes 15 minutes):")
    for edge in client.eligible_edges(SAMPLE_ROADS):
        print(edge)
    print("Avoid unpaved roads:", client.eligible_edges(SAMPLE_ROADS, ["avoid_unpaved"]))
