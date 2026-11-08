import copy
import unittest

from demo_member4 import SAMPLE_ROADS
from integration import IntegrationError, PrologClient


class IntegrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = PrologClient()

    def test_penalty_once_and_not_accumulated(self):
        for conditions, expected in [([], 10), (["broken_cistern"], 15),
                                     (["deep_pothole"], 15), (["broken_cistern", "deep_pothole"], 15)]:
            with self.subTest(conditions=conditions):
                self.assertEqual(self.client.condition_time(10, conditions), expected)
                self.assertEqual(self.client.condition_time(10, conditions), expected)

    def test_direction_closure_and_totals(self):
        edges = self.client.eligible_edges(SAMPLE_ROADS)
        self.assertEqual(len(edges), 3)
        self.assertEqual({(e["source"], e["destination"]) for e in edges},
                         {("village_a", "village_b"), ("village_b", "village_a"), ("village_b", "village_c")})
        self.assertEqual([(e["distance"], e["time"]) for e in edges if e["road_id"] == "r001"], [(5, 15), (5, 15)])

    def test_each_restriction_and_empty_result(self):
        self.assertEqual(len(self.client.eligible_edges(SAMPLE_ROADS, ["avoid_unpaved"])), 2)
        self.assertEqual(len(self.client.eligible_edges(SAMPLE_ROADS, ["avoid_deep_potholes"])), 1)
        road = copy.deepcopy(SAMPLE_ROADS[0])
        road["conditions"] = ["broken_cistern"]
        self.assertEqual(self.client.eligible_edges([road], ["avoid_broken_cisterns"]), [])
        self.assertEqual(self.client.eligible_edges(SAMPLE_ROADS, ["avoid_unpaved", "avoid_deep_potholes"]), [])

    def test_updated_base_time_and_reopened_road(self):
        roads = copy.deepcopy(SAMPLE_ROADS)
        roads[0]["time"] = 20
        roads[2]["status"] = "open"
        edges = self.client.eligible_edges(roads)
        self.assertEqual(len(edges), 5)
        self.assertEqual(next(e["time"] for e in edges if e["road_id"] == "r001"), 25)

    def test_invalid_inputs(self):
        for value in (-1, float("nan"), True, "10"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.client.condition_time(value, [])
        with self.assertRaises(ValueError):
            self.client.eligible_edges(SAMPLE_ROADS, ["ignore_closures"])
        with self.assertRaises(ValueError):
            self.client.eligible_edges([SAMPLE_ROADS[0], SAMPLE_ROADS[0]])
        with self.assertRaises(ValueError):
            self.client.condition_time(10, ["unknown_damage"])

    def test_process_errors_are_reported(self):
        with self.assertRaises(IntegrationError):
            PrologClient(executable="missing-prolog-executable").condition_time(10, [])

    def test_no_roads(self):
        self.assertEqual(self.client.eligible_edges([]), [])


if __name__ == "__main__":
    unittest.main()
