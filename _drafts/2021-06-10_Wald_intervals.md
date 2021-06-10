Here, I want to dive into [Confidence Intervals](https://en.wikipedia.org/wiki/Confidence_interval) (CI) on [Binomial Proportions](https://en.wikipedia.org/wiki/Binomial_proportion_confidence_interva). In particular, I want to explore issues with the much-used [Normal Approximation](https://en.wikipedia.org/wiki/Binomial_distribution#Normal_approximation). These CIs occur when assessing the quality of [Binary Classifiers](https://en.wikipedia.org/wiki/Binary_classification).

If $n$ is the total number of trials, and $n_s$ is the number successes, then an agreement proportion is $\hat{p}=n_s/s$. A CI $[p_l, p_h]$ defines a range within which the true agreement $p$ likely lies. The confidence level $1-\alpha$ is the probability that the CI covers $p$. 

The discrete nature of the binomial distribution makes calculation exact CI hard. However, for large enough $n$ and $n_s$, a normal approximation can be used
\\[
\mathrm{Binom}(n, p) \approx \mathcal{N}(\mu=np, \sigma^2=np(1-p))\,
\\]
where $\mathcal{N}$ is the [Normal Distribution](https://en.wikipedia.org/wiki/Normal_distribution). This approximation worsens with lower $n$ and $p$ further from 0.5.
