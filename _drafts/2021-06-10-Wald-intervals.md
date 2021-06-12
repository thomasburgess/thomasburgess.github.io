---
title: Wald intervals
tags:
  - blog
  - statistics
  - binomial_ci
  - wald
---

## Introduction

Here, I want to dive into [Confidence Intervals](https://en.wikipedia.org/wiki/Confidence_interval)
(CI) on [Binomial Proportions](https://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval).
In particular, I will explore issues with the much-used [Normal Approximation](https://en.wikipedia.org/wiki/Binomial_distribution#Normal_approximation). These CIs often occur when assessing the 
quality of [Binary Classifiers](https://en.wikipedia.org/wiki/Binary_classification).

If $n$ is the total number of trials, and $n_s$ is the number successes, then an 
agreement proportion is $\hat{p}=n_s/s$. A CI $[p_l, p_h]$ defines a range
within which the true agreement $p$ likely lies. The confidence level $1-\alpha$ 
is the probability that the CI covers $p$. 

The discrete nature of the binomial distribution makes calculating the exact CI 
hard. This has lead to widespread use of a number of approximations[^newcombe1998]. 
Under the assumptions $n$ is large and $p$ is not close to 0 or 1, the normal 
approximation for the binomial is

\begin{equation}
  \text{Binomial}(p, n) \approx \mathcal{N}\left(\mu=n\hat{p}, 
  \sigma=\sqrt{\hat{p}(1-\hat{p})/n}\right)\,,
\end{equation}

where $\mathcal{N}$ is the normal distribution with mean $\mu$ and standard 
deviation $\sigma$. With this in the standard normal CI on the mean and hoping that
$p\approx\hat{p}$, the _Wald_ CI is written[^brown2001]

\begin{equation}
p \in \hat{p}\pm|z_{\alpha/2}|\sqrt{\frac{\hat{p}(1-\hat{p})}{n}}\,.
\end{equation}


## Validity of normal distribution

First, we need some test values for $n$ and $p$. For $n$, the [Hyperinflation sequence](https://oeis.org/A051109) 
gives increasing gaps, and for $p$ a cosine transformation gives finer sampling 
near the edges.

{% details Python script to make the images... %}
```python
n_ns = 10
ns = [((n % 3) ** 2 + 1) * 10**int(n/3) for n in range(n_ns)] 
n_ps = 10
ps = [(np.cos(np.pi*((i+1)/(n_ps+1)-1))+1)/2 for i in range(0, n_ps)]
```
{% enddetails %}


## Continuity correction

...

[^newcombe1998]: Newcombe, R.G. (1998), Two-sided confidence intervals for the single proportion: comparison of seven methods. Statist. Med., 17: 857-872. [doi](https://doi.org/10.1002%2F%28sici%291097-0258%2819980430%2917%3A8%3C857%3A%3Aaid-sim777%3E3.0.co%3B2-e)
[^brown2001]: Brown, L. D., Cai, T. T., & DasGupta, A. (2001). Interval estimation for a binomial proportion. Statistical science, 101-117. [url](https://projecteuclid.org/journals/statistical-science/volume-16/issue-2/Interval-Estimation-for-a-Binomial-Proportion/10.1214/ss/1009213286.full), [doi](https://doi.org/10.1214/ss/1009213286)
