---
title: Wald intervals
tags:
  - blog
  - statistics
  - binomial_ci
  - wald
categories: statistics
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

If $n$ is the total number of trials, and $k$ is the number successes, then an 
agreement proportion is $\hat{p}=k/s$. A CI $[p_l, p_h]$ defines a range
within which the true agreement $p$ likely lies. The confidence level $1-\alpha$ 
is the probability that the CI covers $p$. 

The discrete nature of the binomial distribution makes calculating the exact CI hard. This has led to the widespread use of many approximations[^newcombe1998]. 
The normal approximation to the binomial is

\begin{equation}
  \text{Binomial}(p, n) \approx \mathcal{N}\left(\mu=np, 
  \sigma=\sqrt{p(1-p)/n}\right) \equiv \mathcal{W}(p, n)\,,
\end{equation}

where $\mathcal{N}$ is the normal distribution with mean $\mu$ and standard 
deviation $\sigma$. Now the _Wald_ CI on the proportion is[^brown2001]

\begin{equation}
p \in \hat{p}\pm|z_{\alpha/2}|\sqrt{\frac{\hat{p}(1-\hat{p})}{n}}\,.
\end{equation}

This approximation makes several assumptions, the implications of which I'll 
try to understand in the following sections.

## Generating examples

The examples need some test values for $n$ and $p$.
To get increasing gaps in $n$, I chose the 
[Hyperinflation sequence](https://oeis.org/A051109) 

\begin{equation}
a(n) = \left((n\,\text{mod}\,3)^2+1 \right) 10 ^{\lfloor n/3 \rfloor}\,.
\end{equation}
For $p$ I wanted more samples near 0 and 1, so I made the cosine transformation 
\begin{equation}
x(k) = \frac{1}{2} \left(\cos\left(\pi\frac{k+1}{n+1}-1\right)+1\right)\,.
\end{equation}

With these, I loop over three counts and seven proportions to generate [Figure 1.](#figure-1) The approximation looks good for proportions close to 0.5 and high $n$. But, closer to the edges at 0 and 1, the assymmetry of the binomial causes problems. In addition, the normal distribution extends beyond 0 and 1. Hence, its CI limits may go outside of the range for $p$. Truncating the CI would lead to too narrow ranges (under [coverage](https://en.wikipedia.org/wiki/Coverage_probability )). Together, these issues causes many problems for confidence intervals.

{% figure [caption:"Figure 1. Binomial (triangles) and normal distribution 
(curves) approximation for varying $n$ and $p$. The vertical lines mark the true proportions. Agreement worsen further from $p=0.5$ and at lower $n$. The lower
amplitude at higher $n$ comes from the normalization of the integral to 1."] [class:"class1 class2"] %}
![](/assets/images/2021-06-13/binomnorm.png){: #figure-1}
{% endfigure %}


{% details Code to generate sequences and Figure 1... %}
```python
import numpy as np
import scipy.stats as st
import matplotlib.pyplot as plt


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
    norm = st.norm(loc=p * n, scale=np.sqrt(p * (1 - p) * n))
    c = ax.plot(nk / n, norm.pdf(nk), "-", alpha=0.5, label=label)
    # Plot binomial as discrete triangles
    binom = st.binom(n, p)  # binomial distribution
    bk = np.arange(n + 1)  # binomial x-axis
    ax.scatter(bk / n, binom.pmf(bk), c=c[0].get_color(), marker="v", alpha=0.5)
    # Indicate p
    ax.axvline(p, color=c[0].get_color(), alpha=0.5, linestyle=":")


fig, axs = plt.subplots(1, 3, figsize=(15, 4), sharey=True)
axs = axs.flatten()
for i, n in enumerate(hyperinflation(3, 3)):
    for p in cosine_samples(7):
        plot_binomnorm(n=n, p=p, nn=100, ax=axs[i], label=f"{p=:.2f}")
        axs[i].set(xlabel=r"$\hat{p}$", title=f"{n=:.0f}")
axs[i].legend(bbox_to_anchor=(1, 1), loc="upper left")
axs[0].set(ylabel="probability mass | density")
```
{% enddetails %}

In [Figure 2.](#figure-2) another view of this is obtained by fixing $n$, and plotting the ratio $\mathcal{W}(n,p)/\text{Binom(n,p)}$ for each $k$ and $p$. When the normal approximation is valid, the ratio should be around 1. This is the case when $p\approx\hat{p}$, but there also large regions where the ratio is far off.

{% figure [caption:"Figure 2. Ratio of the normal approximation $\mathcal{W}(n,p)$ probability density and the true $\text{Binom(n,p)}$ probability mass for $n=50$. On the diagonal $p=\hat{p}$, the ratio is close to 1."] %}
![](/assets/images/2021-06-13/binomnorm_ratio.png){: #figure-2 }
{% endfigure %}

{% details Code to generate sequences and Figure 2... %}
```python
import numpy as np
import scipy.stats as st
import matplotlib as mpl
import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import make_axes_locatable

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
        norm = st.norm(loc=p * n, scale=np.sqrt(p * (1 - p) * n)).pdf(k)
        plot.append((norm / binom))
    mat = ax.matshow(
        np.array(plot),
        extent=[0, 1, 1, 0],
        aspect="auto",
        cmap="Spectral",
        vmin=0,
        vmax=2,
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
{% enddetails %}

## Simulating confindence regions

## Continuity correction

...

[^newcombe1998]: Newcombe, R.G. (1998), Two-sided confidence intervals for the single proportion: comparison of seven methods. Statist. Med., 17: 857-872. [doi](https://doi.org/10.1002%2F%28sici%291097-0258%2819980430%2917%3A8%3C857%3A%3Aaid-sim777%3E3.0.co%3B2-e)
[^brown2001]: Brown, L. D., Cai, T. T., & DasGupta, A. (2001). Interval estimation for a binomial proportion. Statistical science, 101-117. [url](https://projecteuclid.org/journals/statistical-science/volume-16/issue-2/Interval-Estimation-for-a-Binomial-Proportion/10.1214/ss/1009213286.full), [doi](https://doi.org/10.1214/ss/1009213286)
[^agresti1998]: Agresti, A., & Coull, B. A. (1998). Approximate is better than “exact” for interval estimation of binomial proportions. The American Statistician, 52(2), 119-126. [doi](https://doi.org/10.2307/2685469 )
