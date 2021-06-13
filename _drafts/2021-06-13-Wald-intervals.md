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


## Generating examples

To make examples, some values for $n$ and $p$ are needed. 
For $n$, the [Hyperinflation sequence](https://oeis.org/A051109) 
gives increasing gaps. For $p$, I made a cosine transformation that 
gives results for each $k \in [1, n]$ with finer sampling near $p=0$ 
and $p=1$

\begin{equation}
x(k) = \frac{1}{2} \left(\cos(\pi\frac{k+1}{n+1}-1)+1\right)
\end{equation}


{% details Python script to make the images... %}
```python

def hyperinflation(n: int, n0: int=1) -> np.ndarray:
    """Generate hyperinflation sequence

    2, 5, 10, 20, 50, 100, ...

    Args:
        n (int):  Number of entries
        n0 (int): First entry

    References
    ----------
    Hyperinflation sequence (https://oeis.org/A051109)
    """
    s = np.arange(n)+n0
    return ((s % 3) ** 2 + 1) * 10 ** (s//3)

def cosine_samples(n: int):
    """Generate cosine distributed sequence
    
    This sequence is symmetric around 0.5 in the interval 0, 1
    it has more samples near 0 and 1
    
    Args:
        n (int):  Number of entries    
    """
    s = np.arange(n)
    return (np.cos(np.pi*((s+1)/(n+1)-1))+1)/2
```
{% enddetails %}


## Continuity correction

...

[^newcombe1998]: Newcombe, R.G. (1998), Two-sided confidence intervals for the single proportion: comparison of seven methods. Statist. Med., 17: 857-872. [doi](https://doi.org/10.1002%2F%28sici%291097-0258%2819980430%2917%3A8%3C857%3A%3Aaid-sim777%3E3.0.co%3B2-e)
[^brown2001]: Brown, L. D., Cai, T. T., & DasGupta, A. (2001). Interval estimation for a binomial proportion. Statistical science, 101-117. [url](https://projecteuclid.org/journals/statistical-science/volume-16/issue-2/Interval-Estimation-for-a-Binomial-Proportion/10.1214/ss/1009213286.full), [doi](https://doi.org/10.1214/ss/1009213286)
