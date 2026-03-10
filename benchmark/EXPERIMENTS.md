# Benchmark Experiments

Date: 2026-03-10
Environment: Ruby 3.3.4, `arm64-darwin24`
Workload: `benchmark/benchmark.rb` with 10 posts and 10 comments per post

## Baseline

Before optimization:

- `base_serializer`: `4941.7 i/s`
- Memory: `107600` bytes, `1399` objects
- Comparison vs AMS: `7.95x` faster, `2.39x` less memory

## Iteration 1

Hypothesis: field selection and wildcard expansion are pure setup work and should not run once per serialized object.

Changes:

- Precompute selected fields in `initialize`
- Cache default field-name expansion at the class level
- Add a direct `Array` fast path
- Cache predicate method names on `Field`

Result:

- `base_serializer`: `7851.1 i/s`
- Memory: `36960` bytes, `322` objects

Outcome: large win. Most of the original allocation pressure was selector-related.

## Iteration 2

Hypothesis: nested serializer construction is repeated unnecessarily across collection items.

Changes:

- Build nested serializer instances once per serializer instance
- Precompute whether a selected field is backed by a serializer instance method

Result:

- `base_serializer`: `8164.6 i/s`
- Memory: `27800` bytes, `240` objects

Outcome: moderate throughput win, plus another allocation drop.

## Iteration 3

Hypothesis: the remaining hot loop still pays some Ruby block overhead.

Changes:

- Replace the per-field `each` loop in `serialize_one` with an index loop
- Reuse cached array length in the top-level array path

Result:

- `base_serializer`: `8367.3 i/s`
- Memory: `27800` bytes, `240` objects

Outcome: small but repeatable win. Kept.

## Final delta

Compared with the starting point:

- Throughput improved from `4941.7 i/s` to `8367.3 i/s` (`+69.3%`)
- Allocated memory dropped from `107600` bytes to `27800` bytes (`-74.2%`)
- Allocated objects dropped from `1399` to `240` (`-82.8%`)
