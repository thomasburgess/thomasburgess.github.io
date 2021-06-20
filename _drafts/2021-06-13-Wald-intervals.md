---
title: Wald intervals
tags:
  - blog
  - statistics
  - binomial_ci
  - wald
categories: blog
---

## Introduction

Here, I'll dive into 
[Confidence Intervals](https://en.wikipedia.org/wiki/Confidence_interval)
(CI) on 
[Binomial Proportions](https://en.wikipedia.org/wiki/Binomial_proportion_confidence_interval).
In particular, I will explore issues with the much-used 
[Normal Approximation](https://en.wikipedia.org/wiki/Binomial_distribution#Normal_approximation). 
These CIs often occur when assessing the quality of 
[Binary Classifiers](https://en.wikipedia.org/wiki/Binary_classification).

I wrote this post while making the python snippets that are scattered throught
this code. To run the code, you may need to install [python>=3.8](https://docs.python.org/3.8/), 
and the libraries and versions listed below:

```python
from typing import Tuple
import numpy as np  # 1.20.3
import scipy.stats as st # 1.6.3
import matplotlib as mpl # 3.4.2
import matplotlib.pyplot as plt 
from mpl_toolkits.axes_grid1 import make_axes_locatable
```

## Defining the Wald CI

The binomial distribution applies to repeated experiments with binary outcomes. 
Probably the most common example would be a series of coin flips. The Binomial 
probability of $k$ successes out $n$ trials with success probability $p$ is 
given by the 
[Probability Mass Function](https://en.wikipedia.org/wiki/Probability_mass_function)

\begin{equation}
B_\text{pmf}(k, n, p) = {n\choose p} p^k (1-p)^{n-k}\,.
\end{equation}

The mean of the distribution is $\mu=np$ and its standard deviation is 
$\sigma=\sqrt{np(1-p)}$. To estimate $p$, make $n$ experiments, and the estimate
is the successes proportion $\hat{p}=k/s$. The tricky part is finding a 
confidence interval $[E^-, E^+]$ around $\hat{p}$ within which the true $p$ 
likely lies. The confidence level $1-\alpha$ is the probability that the CI
covers $p$. 

The discrete nature of the binomial distribution makes calculating the exact 
CI hard. Because of this, there is widespread usage of many 
approximations[^newcombe1998]. The most common one uses the normal approximation 
to the binomial:

\begin{equation}
  B_\text{pmf}(k, n, p) \approx \mathcal{N} _ \text{pdf}\left(x=k, \mu=np, 
  \sigma=\sqrt{np(1-p)}\right)
\end{equation}

where $\mathcal{N} _ \text{pdf}$ is the 
[Normal Distribution](https://en.wikipedia.org/wiki/Normal_distribution).
The (approximate) CI for an estimate of the mean of a normal distribution
\begin{equation}
    \mu \in \hat{\mu} \pm |z| \frac{1}{\sqrt{n}}s\,,
\end{equation}
where $s$ is the standard deviation, and $z$ is the $1-\alpha/2$ quantile of 
$\mathcal{N}(0,1)$. With this, the _Wald_ CI using $\hat{\mu}=k/n$, 
$s=\sqrt{p(1-p)}$[^brown2001], and $p\approx\hat{p}$ so that
\begin{equation}
p \in \hat{p} \pm |z| \sqrt{\frac{\hat{p}(1-\hat{p})}{n}}\,.
\end{equation}

For a better, more in-depth view, try this paper and blog post by Wallis[^wallis2013].

```python
def make_norm_appox(n: int, p: float) -> st.rv_continuous:
    """Get normal approximation to binomial distribution

    Args:
       n (int) - counts
       p (float) - probability of success

    return:
        st.rv_continuous: scipy distribution 
    """
    return st.norm(loc=p * n, scale=np.sqrt(p * (1 - p) * n))


def calc_ci_wald(n: int, p: float, alpha: float) -> Tuple[float, float]:
    """Wald binomial confidence interval
    
    This uses a normal approximation, and is calculated as follows[#wallis_2013]:

        CI = p +- z(alpha/2) sqrt(p(1-p)/n)

    Args:
       n (int) - counts
       p (float) - probability of success
       alpha (float) - significance level  

    Return:
        Tuple[float, float]: lower and upper CI
    """
    sz = np.sqrt(p*(1-p)/n) * st.norm.isf(alpha / 2.)
    return p - sz, p + sz
```

I'll spend the upcoming sections trying to show the implications of the assumptions 
made in the Wald CI.

## Binomial vs Normal

The examples need some test values for $n$ and $p$. With the [Hyperinflation sequence](https://oeis.org/A051109), gaps between counts increase in a nice way

\begin{equation}
  a(n) = \left((n\,\text{mod}\,3)^2+1 \right) 10 ^{\lfloor n/3 \rfloor}\,,
\end{equation}
while for $p$ more samples are taken near 0 and 1 are using a cosine transformation 
\begin{equation}
  x(k) = \frac{1}{2} \left(\cos\left(\pi\frac{k+1}{n+1}-1\right)+1\right)\,.
\end{equation}

```python
def hyperinflation(n: int, n0: int = 1) -> np.ndarray:
    """Generate hyperinflation sequence

    2, 5, 10, 20, 50, 100, ...

    References
    ----------
    Hyperinflation sequence (https://oeis.org/A051109)

    Parameters
    ----------
    n : int
        Number of entries
    n0 : int, optional
        First entry

    Returns
    -------
    np.ndarray
        Growing counts sequence
    """
    s = np.arange(n) + n0
    return ((s % 3) ** 2 + 1) * 10 ** (s // 3)


def cosine_samples(n: int) -> np.ndarray:
    """Generate cosine distributed sequence

    This sequence is symmetric around 0.5 in the interval 0, 1
    it has more samples near 0 and 1

    Parameters
    ----------
    n : int
        Number of entries

    Returns
    -------
    np.ndarray
        Sequence in range 0, 1
    """
    s = np.arange(n)
    return (np.cos(np.pi * ((s + 1) / (n + 1) - 1)) + 1) / 2
```

With these, I loop over three counts and seven proportions to generate [Figure 1.](#figure-1) For ratios near 0.5 and at sufficiently large n, the approximation seems to hold. But, closer to the edges at 0 and 1, the asymmetry of the binomial causes problems. In addition, the normal distribution extends beyond 0 and 1. Hence, its CI limits may go outside of the range for $p$. Truncating the CI would lead to too narrow ranges (under [coverage](https://en.wikipedia.org/wiki/Coverage_probability )). Together, these issues cause many problems for confidence intervals.

{% figure [caption:"Figure 1: Binomial (triangles) and normal distribution 
(curves) approximation for varying $n$ and $p$. The vertical lines mark the actual proportions. Agreement worsens further away from $p=0.5$ and at lower $n$. The lower amplitude at higher $n$ comes from the normalization of the integral to 1."] %}
![](/assets/images/2021-06-13/binomnorm.png){: #figure-1 width="100%"}
{% endfigure %}


```python
def plot_binomnorm(
    n: int, p: float, nn: int = 100, ax: plt.Axes = None, label: str = None
):
    """Plot binomial and normal approximation

    Parameters
    ----------
    n : int
        Number of trials
    p : float
        Binomial proportion
    nn : int, optional
        Number of values to use for normal plot
    ax : plt.Axes, optional
        Axis to plot on
    label : str, optional
        legend label
    """
    ax = ax or plt.gca()
    # Plot normal as line
    nk = np.linspace(0, n, nn)  # normal x-axis
    c = ax.plot(nk / n, make_norm_appox(n, p).pdf(nk), "-", alpha=0.5, label=label)
    col = c[0].get_color()  # capture color from plot
    # Plot binomial as discrete triangles
    binom = st.binom(n, p)  # binomial distribution
    bk = np.arange(n + 1)  # binomial x-axis
    ax.scatter(bk / n, binom.pmf(bk), c=col, marker="v", alpha=0.5)
    # Indicate p
    ax.axvline(p, color=col, alpha=0.5, linestyle=":")

fig, axs = plt.subplots(1, 3, figsize=(15, 4), sharey=True)
axs = axs.flatten()
for i, n in enumerate(hyperinflation(3, 3)):
    for p in cosine_samples(7):
        plot_binomnorm(n=n, p=p, nn=100, ax=axs[i], label=f"{p=:.2f}")
        axs[i].set(xlabel=r"$\hat{p}$", title=f"{n=:.0f}")
axs[i].legend(bbox_to_anchor=(1, 1), loc="upper left")
axs[0].set(ylabel="probability mass | density")
fig.tight_layout()
fig.savefig("binomnorm.png", transparent=True, bbox_inches="tight")
```

 [Figure 2.](#figure-2) shows another view into the validity of the normal approximation. Here, $n$ is held fixed, and the ratio normal/binomial for each $k$ and $p$ is plotted. The ratio should be $\approx1$ when the normal approximation is valid. When $p\approx\hat{p}$ the ratio is close to 1, but other regions can be far off. In practice, the true value of $p$ is unknown. Thus, rules of thumbs on the number of trials and successes needed in the approximation cannot ensure that the bad regions are avoided.

{% figure [caption:"Figure 2: The ratio of the normal approximation $\mathcal{W}(n,p)$ probability density and the true $\text{Binom(n,p)}$ probability mass for $n=50$. Along the diagonal $p=\hat{p}$, the ratio is close to 1. These are the most probable values, and here the approximation is quite good. At low $p$ and $\hat{p}$, the normal is higher than the binomial. When $p$ increases this situation switches around. This effect is symmetric in the diagonal."] %}
![](/assets/images/2021-06-13/binomnorm_ratio.png){: #figure-2 width="50%"}
{% endfigure %}

```python
def plot_binomnorm_ratio(n: int, ax: plt.Axes = None) -> mpl.image.AxesImage:
    """Plot ratio of normal and binomial by k and p

    Makes n x n grid with x-axis as p^ and y-axis as p

    Parameters
    ----------
    n : int
        Number of trials
    ax : plt.Axes, optional
        Axis to plot on

    Returns
    -------
    mpl.image.AxesImage
        Plotted image
    """
    ax = ax or plt.gca()
    k = np.arange(0, n + 1)
    plot = []
    for p in np.linspace(0.04, 0.96, n):
        binom = st.binom(n, p).pmf(k)
        norm = make_norm_appox(n, p).pdf(k)
        plot.append((norm / binom))
    mat = ax.matshow(
        np.array(plot).T,
        extent=[0, 1, 1, 0],
        aspect="auto",
        cmap="Spectral",
        vmin=0,
        vmax=2,
        origin="lower",
    )
    ax.set(xlabel=r"$\hat{p}$", title=f"{n=}")
    ax.set_aspect("equal", "box")
    return mat


fig, axs = plt.subplots(1, 1, figsize=(7, 7), sharey=True)
mat = plot_binomnorm_ratio(50, axs)
axs.set(ylabel="$p=k/n$")
fig.colorbar(
    mat,
    label="Normal / Binomial",
    cax=make_axes_locatable(axs).append_axes("right", size="5%", pad=0.1),
)
fig.tight_layout()
fig.savefig("binomnorm_ratio.png", transparent=True, bbox_inches="tight")
``` 

## Simulating confindence regions

...

## References

[^newcombe1998]: Newcombe, R.G. (1998), _Two-sided confidence intervals for the single proportion: comparison of seven methods._ Statist. Med., 17: 857-872. [doi](https://doi.org/10.1002%2F%28sici%291097-0258%2819980430%2917%3A8%3C857%3A%3Aaid-sim777%3E3.0.co%3B2-e)

[^brown2001]: Brown, L. D., Cai, T. T., & DasGupta, A. (2001). _Interval estimation for a binomial proportion._ Statistical science, 101-117. [url](https://projecteuclid.org/journals/statistical-science/volume-16/issue-2/Interval-Estimation-for-a-Binomial-Proportion/10.1214/ss/1009213286.full), [doi](https://doi.org/10.1214/ss/1009213286)

[^agresti1998]: Agresti, A., & Coull, B. A. (1998). _Approximate is better than “exact” for interval estimation of binomial proportions._ The American Statistician, 52(2), 119-126. [doi](https://doi.org/10.2307/2685469 )

[^wallis2013]: Wallis, S.A. (2013). _Binomial confidence intervals and contingency tests: mathematical fundamentals and the evaluation of alternative methods._ Journal of Quantitative Linguistics 20:3, 178-208. [url](https://corplingstats.wordpress.com/2012/03/31/binomial-distributions/), [doi](https://doi.org/10.1080/09296174.2013.799918)
