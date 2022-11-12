
# benchmark
```sh
❯ bundle exec ruby benchmark.rb
Warming up --------------------------------------
                 ams    32.000  i/100ms
     base_serializer   290.000  i/100ms
Calculating -------------------------------------
                 ams    332.382  (± 0.5%) i/s -      3.328k in  10.020864s
     base_serializer      2.983k (± 0.6%) i/s -     29.870k in  10.026233s
                   with 95.0% confidence

Comparison:
     base_serializer:     2982.6 i/s
                 ams:      332.4 i/s - 8.97x  (± 0.07) slower
                   with 95.0% confidence

Calculating -------------------------------------
                 ams   238.360k memsize (     0.000  retained)
                         3.212k objects (     0.000  retained)
                        12.000  strings (     0.000  retained)
     base_serializer    92.160k memsize (     0.000  retained)
                         1.398k objects (     0.000  retained)
                         6.000  strings (     0.000  retained)

Comparison:
     base_serializer:      92160 allocated
                 ams:     238360 allocated - 2.59x more
```
