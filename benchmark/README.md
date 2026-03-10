# benchmark
Latest measurement on Ruby 3.3.4 (`arm64-darwin24`) with the bundled workload in `benchmark.rb`:

```sh
❯ bundle exec ruby benchmark.rb
Warming up --------------------------------------
                 ams    61.000 i/100ms
     base_serializer   854.000 i/100ms
Calculating -------------------------------------
                 ams    613.455 (± 1.3%) i/s    (1.63 ms/i) -      6.100k in  10.017535s
     base_serializer      8.361k (± 1.0%) i/s  (119.60 μs/i) -     83.692k in  10.041011s
                   with 95.0% confidence

Comparison:
     base_serializer:     8361.4 i/s
                 ams:      613.5 i/s - 13.63x (± 0.22) slower
                   with 95.0% confidence

Calculating -------------------------------------
                 ams   256.848k memsize (     0.000 retained)
                         2.970k objects (     0.000 retained)
                         7.000 strings  (     0.000 retained)
     base_serializer    27.800k memsize (     0.000 retained)
                       240.000 objects  (     0.000 retained)
                         4.000 strings  (     0.000 retained)

Comparison:
     base_serializer:      27800 allocated
                 ams:     256848 allocated - 9.24x more
```

Experiment notes live in `EXPERIMENTS.md`.
