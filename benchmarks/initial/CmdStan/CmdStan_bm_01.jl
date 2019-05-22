using MCMCBenchmarks

Random.seed!(38445)

ProjDir = @__DIR__
cd(ProjDir)

 normstanmodel = "
 data {
   int<lower=0> N;
   vector[N] y;
 }
 parameters {
   real mu;
   real<lower=0> sigma;
 }
 model {
   mu ~ normal(0,1);
   sigma ~ cauchy(0,1);
   y ~ normal(mu, sigma);
 }
 "

 BenchmarkTools.DEFAULT_PARAMETERS.samples = 25
 
 Nsamples = 2000
 Nadapt = 1000
 Nchains = 1

stanmodel = Stanmodel(
   name = "normstanmodel", model = normstanmodel, nchains = Nchains,
   Sample(num_samples = Nsamples, num_warmup = Nadapt,
     adapt = CmdStan.Adapt(delta=0.8),
     save_warmup = false));

function cmdstan_bm(stanmodel, data, ProjDir = ProjDir)    
  stan(stanmodel, data, summary=false, ProjDir)
end

Ns = [100, 500, 1000]

chns = Vector{MCMCChains.Chains}(undef, length(Ns))
t = Vector{BenchmarkTools.Trial}(undef, length(Ns))

for (i, N) in enumerate(Ns)
  data = Dict("y" => rand(Normal(0, 1), N), "N" => N)
  t[i] = @benchmark cmdstan_bm($stanmodel, $data)
  rc, chns[i], cnames = stan(stanmodel, data, summary=false, ProjDir)
end

t[1] |> display
println()
t[end] |> display

describe(chns[end])
