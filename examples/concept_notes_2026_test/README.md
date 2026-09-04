# Concept-note stress test (K = 8)

A Voice-only run on the 55 side-event concept notes, kept as the worked
evidence for two claims in the protocol:

- **Documents per topic matters.** At K = 8 this 55-document corpus gives
  roughly 7 documents per topic and produces readable themes. Forcing K = 20
  on the same corpus collapses them into frame-word repetition — "govern,
  global, session, will" — with no differentiator. See protocol Step 2.4.
- **Step 2.3 is skipped when no reliable split exists.** This corpus has no
  dependable two-group variable, so the difference-of-proportions step was not
  run, and that is reported as a finding rather than forced with a proxy.

`topic_reading/` holds the representative documents per topic; `ldavis_k8/`
is the interactive browser. This is a diagnostic run, not the pilot — for the
full three-phase analysis see `examples/geneva_2026/`.
