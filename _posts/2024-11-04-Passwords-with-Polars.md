---
title: Passwords with Polars
subtitle: Wrangling csv password manager exports
last_modified_at: 2024-11-04
tags: [python,coding,polars,csv]
mathjax: false
categories: [blog,code]
header_type: hero
header_img: /assets/images/2024/11/04/hans-jurgen-mager-ffE6g1p5mjc-unsplash.jpg
og_image: /assets/images/2024/11/04/hans-jurgen-mager-ffE6g1p5mjc-unsplash.jpg
description: Wrangling passwords with Polars
excerpt: >
    I've used several approaches to password management. Not all passwords 
    have been migrated when switching solution. In this post, I'll consolidate `.csv` 
    exports from different password managers, and analyze the resulting dataset.
    I'll tackle this challenge with Polars.
layout: default
---

_Header image credit_[^1]

[^1]: Crop from a photo by <a href="https://unsplash.com/@hansjurgen007?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Hans-Jurgen Mager</a> on <a href="https://unsplash.com/photos/polar-bear-on-snow-covered-ground-during-daytime-ffE6g1p5mjc?utm_content=creditCopyText&utm_medium=referral&utm_source=unsplash">Unsplash</a>

## Introduction

Over time, I have tried several approaches to password management:
[LastPass](https://www.LastPass.com/), [Firefox](https://www.mozilla.org/en-US/firefox/), 
and Safari (now Apple's Passwords app). Not all passwords have been migrated when 
switching solution. In this post, I'll consolidate `.csv` exports from different 
password managers, and analyze the resulting dataset. This is somewhat complicated as
each manager has its own format and content. Furthermore, there is overlap between the
different exports.

I'll tackle this challenge with [Polars](https://docs.pola.rs/) - a fast DataFrame 
library for manipulating structured data written in [Rust](https://www.rust-lang.org/), 
with a Python interface. Being well-versed in [Pandas](https://pandas.pydata.org), I 
took this project as an opportunity to explore Polars and understand its unique 
strengths and abilities.

_Note: Be carefull with your passwords, and don't read any of this as security advice._

## Python environment

I'm using the python 3.12 standard library and Polars 1.12.0 (the latest 
version as of 2024-11-04). 

```python
import hashlib
from enum import Enum
from pathlib import Path
from typing import Self
import requests
from collections.abc import Collection
from dataclasses import dataclass

import polars as pl f
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception
```

## Fun with File Formats

Each password manager exports data in its own format. I printed the column headers from 
the first line of each file and found the following:

{% figure [caption:"**Table 1**: Initial column headers from different password managers"] %}

| Source    | Columns                                                                                                                                          |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| Safari    | `Title`, `Url`, `Username`, `Password`, `OTPAuth`                                                                                                |
| Passwords | `Title`, `URL`, `Username`, `Password`, `Notes`, `OTPAuth`                                                                                       |
| LastPass  | `url`, `username`, `password`, `totp`, ~~`extra`~~, `name`, ~~`grouping`~~, ~~`fav`~~                                                            |
| Firefox   | `url`, `username`, `password`, ~~`httpRealm`~~, ~~`formActionOrigin`~~, ~~`guid`~~, ~~`timeCreated`~~, ~~`timeLastUsed`~~, `timePasswordChanged` |

{% endfigure %}

They have different columns, with different names, and Firefox has two header rows. 
The second header row must be skipped, not to appear as junk data in the imported `.csv`. 
I put all Columns I won't bother with in strike-through.

I'm not using LastPass or Firefox at the moment, and Safari's passwords are superseded 
by Apple Passwords, so I will try to make all formats like that. So, I came up with the 
following mapping to a unified Output column set:

{% figure [caption:"**Table 2**: Mapping columns to a unified output format"] %}


| Output     | Safari     | LastPass   | Firefox    |
| ---------- | ---------- | ---------- | ---------- |
| `Title`    | `Title`    | `name`     | `url`      |
| `URL`      | `Url`      | `url`      | `url`      |
| `Username` | `Username` | `username` | `username` |
| `Password` | `Password` | `password` | `password` |
| `Notes`    | ""         | ""         | ""         |
| `OTPAuth`  | `OTPAuth`  | `totp`     | ""         |

{% endfigure %}

To represent formats, I made a `dataclass` `Source` with the name of the columns,
and a mapping to the output column names. Then, all `Source`s were put in an `Enum` to
keep things tidy. I added  additional properties to support additional differences in 
the data sets: `header_rows` to handle longer headers, and `modification_date` if there 
is a column with that in the source data. 

```python
@dataclass(frozen=True)
class Source:
    title: str
    url: str
    username: str
    password: str
    notes: str
    otp_auth: str
    header_rows: int = 1
    modification_date: str | None = None

    def mapping(self).
        return {
            "Title": self.title,
            "URL": self.url,
            "Username": self.username,
            "Password": self.password,
            "Notes": self.notes,
            "OTPAuth": self.otp_auth,
        }


class Sources(Source, Enum):
    APPLE = "Title", "URL", "Username", "Password", "Notes", "OTPAuth"
    FIREFOX = "url", "url", "username", "password", None, None, 2, "timePasswordChanged"
    LASTPASS = "name", "url", "username", "password", None, "totp"
    SAFARI = "Title", "Url", "Username", "Password", None, "OTPAuth"
```

This approach keeps things neat and tidy, and I can rely on type hints and be less
likely to run into issues with misspelled keys.

## Lazy Loading

Polars' `scan_csv` function allows lazy loading of data (as `LazyFrame`), which 
deferrs computations until explicitly collected. This is great for handling large inputs 
without consuming excessive memory. While my password files are too small for this to
make any noticeable differences, I wanted to take this opportunity to learn how to use 
this Polars feature.

In `scan_csvs`, I'm concatenating LazyFrames representing data from a specific source
type, such as a particular password manager. Additionally, I'm adding metadata columns
for the input file:

* `path`: the input file path - to make it easier to track down input file problems.
* `modification_date`: last modification timestamp - to select the most recent version 
  of a duplicate entry.
* `source`: the password manager used - to better undestand coversion issues.

```python
def scan_csvs(paths , source):
    return pl.concat(
        [
            pl.scan_csv(
                str(path),
                has_header=True,
                skip_rows_after_header=source.header_rows - 1,
            ).with_columns(
                pl.lit(path.name).alias("path"),
                pl.lit(path.stat().st_mtime).alias("modification_date"),
                pl.lit(source.name.lower()).alias("source"),
            )
            for path in paths
        ]
    )
```

With this I can Polars up to process my inputs, like this:
```python
lastpass_df = scan_csvs(Path('store/LastPass').glob("*.csv"), Sources.LASTPASS)
firefox_df = scan_csvs(Path('store/Firefox').glob("*.csv"), Sources.FIREFOX)
```

To print a data frame to markdown for a blog like this one, you can use
```python
with pl.Config(
    tbl_cols=-1, 
    fmt_str_lengths=8, 
    set_tbl_width_chars=200, 
    set_tbl_formatting='ASCII_MARKDOWN'
) as cfg:
    print(lastpass_df.collect())
    print(firefox_df.collect())
```
Note, that to see a table I need to `collect()` the data first. The formatting is quite
flexible, but tends to shorten most entires. For the markdown to work on my blog, 
I had to remove the header separator and the type line. Here's the  output for some 
dummy inputs:

{% figure [caption:"**Table 3**: Example output from LastPass data"] %}
| url         | username    | password | totp | extra | name        | grouping | fav | path        | modifica... | source   |
|-------------|-------------|----------|------|-------|-------------|----------|-----|-------------|-------------|----------|
| https://... | dummy@dm... | secret   |      |       | dummy.co... |          | 0   | lastpass... | 16068464... | lastpass |
| https://... | dummy@dm... | password |      |       | dummy.or... |          | 0   | lastpass... | 16699184... | lastpass |
{% endfigure %}

{% figure [caption:"**Table 4**: Example output from Firefox data"] %}
| url         | username | password    | httpReal... | formActi... | guid        | timeCrea... | timeLast... | timePass... | path        | modifica... | source  |
|-------------|----------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|-------------|---------|
| https://... | benutzer | gehemini... |             | https://... | b4f76bb8... | 17014544... | 17040464... | 17014544... | firefox_... | 2023-12-... | firefox |
{% endfigure %}

All the expected columns are read in!

## Transformation

Next, I need to apply format-specific mapping to the data to make data from the 
different sources compatible. This will rename columns according to the 
`Source.mapping()`. For missing columns (which are represented as `None` in the 
`Source` field) an empty string column will be added to ensure all expected columns 
will exist in the output. 

```python
def apply_column_mapping(df, source):
    return df.with_columns(
        (
            pl.col(source_col).alias(target_col)
            if source_col
            else pl.lit("").alias(target_col)
        )
        for target_col, source_col in source.mapping().items()
    )
```

The modification dates are useful to resolve duplicate entries. All inputs files have 
the `modification_date` column, but for Firefox data also hase `timePasswordChanged` 
per entry. File modification dates are represented as floating-point seconds since the 
Unix epoch, whereas `timePasswordChanged` is an integer in milliseconds. To maintain 
consistency, I scale the seconds and cast all values to integers.

```python
def fix_modification_date(df, source):
    return df.with_columns(
        (
            pl.col(source.modification_date).alias("modification_date")
            if source.modification_date
            else pl.col("modification_date") * 1000
        ).cast(pl.Int64)
    )
```

With this, all data have a common set of columns, and a `modification_date` usable for 
comparisons, and is ready to be concatenated:

```python
def combine_dataframes(source_paths):
    return pl.concat(
        [
            scan_csvs(paths, source)
            .pipe(apply_column_mapping, source)
            .pipe(fix_modification_date, source)
            .select(
                [
                    "Title",
                    "URL",
                    "Username",
                    "Password",
                    "Notes",
                    "OTPAuth",
                    "modification_date",
                    "source",
                    "path",
                ]
            )
            for source, paths in source_paths.items()
        ]
    )

```

Now I can combine several data sets:

```python
combined_df = combine_dataframes(
    {
        Sources.FIREFOX: Path("store/Firefox").glob("*.csv"),
        Sources.LASTPASS: Path("store/Lastpass").glob("*.csv"),
    }
)
```

{% figure [caption:"**Table 5**: Combined dataset after mapping and modification date adjustment"] %}
| Title            | URL                    | Username        | Password  | Notes | OTPAuth | modification_date | source   | path              |
|------------------|------------------------|-----------------|-----------|-------|---------|-------------------|----------|-------------------|
| dummy.com        | https://www.dummy.com/ | dummy@dmail.com | secret    |       |         | 1606846453000     | lastpass | lastpass_2020.csv |
| dummy.org        | https://dummy.org      | dummy@dmail.com | password  |       |         | 1669918453000     | lastpass | lastpass_2021.csv |
| https://dummy.at | https://dummy.at       | benutzer        | geheminis |       |         | 1701454453123     | firefox  | firefox_2023.csv  |
{% endfigure %}

All the inputs have been combined to a single dataset with unified modification dates.

## Fun with Filters

With the unified dataset, it is time to filter the data. To get rid of duplicates, I 
group by `Title`, `URL`, and `Username` and select only the latest entry based on 
`modification_date`. This approach has some potential risks, as actual modification 
dates can sometimes be earlier than file modification dates, but it works well with the 
data I have.

```python
def get_latest(df):
    return df.filter(
        pl.col("modification_date")
        == pl.col("modification_date").max().over(["Title", "URL", "Username"])
    )
```

Next, I want to exclude certain rows based on specific criteria, using 
[regular expressions](https://en.wikipedia.org/wiki/Regular_expression)s:
on the different column values. I'm using a dictionary with a list of rules, like this:

```python
excludes = {
    "Title": [r"Facebook"],
    "URL": [r"dummy\.org", "dummy\.net"]
    "Username": ["benutzer",
}
```

To apply them, I concatenate the rules for each column, and reduce all filters to a 
single expression that can be used with `df.filter`:

```python
def exclude_entries(df, excludes):
    if not excludes:
        return df
    filters = [
        ~pl.col(c).str.contains("|".join(exprs))
        for c, exprs in excludes.items()
        if exprs
    ]
    combined_filter = (
        filters if len(filters) == 0 else pl.reduce(lambda acc, f: acc & f, filters)
    )
    return df.filter(combined_filter) if filters else df
```

Now, I can chain it all together

```python
result = (
    combine_dataframes({
        Sources.APPLE: Path('store/Apple').glob("*.csv"),
        Sources.SAFARI: Path('store/Safari').glob("*.csv"),
        Sources.FIREFOX: Path('store/Firefox').glob("*.csv"),
        Sources.LASTPASS: Path('store/Lastpass').glob("*.csv"),
    })
    .pipe(get_latest)
    .pipe(exclude_entries, excludes=excludes)
)
```

To see the Polars' query plan, you can print `result`:

```python
print(result)
```

{% figure [caption:"**Figure 1**: Polars query plan. It's huge."] %}
![](/assets/images/2024/11/04/polars_lazy_graph.png){: #figure-1 alt="Polars query plan"}
{% endfigure %}

Now the data is as clean as it is going to get.

## Make it useful!

An obvious use of the combined dataset is be to use 
[value_counts](https://docs.pola.rs/api/python/stable/reference/expressions/api/polars.Expr.value_counts.html)
to see how often values have been used:

```python
combined_df.select(pl.col("URL").value_counts(sort=True, name="n")).unnest("URL")
combined_df.select(pl.col("Password").value_counts(sort=True, name="n")).unnest("Password")
combined_df.select(pl.col("Username").value_counts(sort=True, name="n")).unnest("Username")
```
With my dummy data I get:

{% figure [caption:"**Table 6**: URL usage counts"] %}
| URL                    | n   |
|------------------------|-----|
| https://www.dummy.com/ | 1   |
| https://dummy.org      | 1   |
| https://dummy.at       | 1   |
{% endfigure %}

{% figure [caption:"**Table 7**: Password usage counts"] %}
| Password  | n   |
|-----------|-----|
| secret    | 1   |
| password  | 1   |
| geheminis | 1   |
{% endfigure %}

{% figure [caption:"**Table 8**: Username usage counts"] %}
| Username        | n   |
|-----------------|-----|
| dummy@dmail.com | 2   |
| benutzer        | 1   |
{% endfigure %}

With this I can figure out URL and emails that I may want to put in my exclude list, or
identify reused passwords. I can also sort the data by time stamp to catch the oldest 
entries:
```python
combined_df.sort("modification_date")
```
and course save the combined output
```python
combined.write_csv("combined.csv")
````
And this file I can import into Apple passwords again, to have everything in the same
place. But before I do that, I should check if the passwords have been compromised.

## Have I Been Pwned?

[Have I Been Pwned API](https://haveibeenpwned.com/API/v3) (HIBP) offers a free API to 
query wether passwords have been exposed in a data breach. The API uses a pretty nice 
way to ensure [K-anonymity](https://en.wikipedia.org/wiki/K-anonymity) of request 
password hashes. With this approach, you send only the first 5 characters of a passwords 
sha-1 hash. The result contains many pwned hashes, and to check for a breach you only
match the last 5 characters of your hash with the response. As many different passwords
share the partial hash, request traffice can't be pinned down to any specific person.

Not to abuse the free API, i use [tenacity](https://tenacity.readthedocs.io/en/latest/)
to ensure my requests handle rate limiting. Careless querying may cause the API to ban 
your IP from making queries. Here is how to check one password:

```python
from requests.status_codes import codes

def should_retry(exception):
    return (
        isinstance(exception, requests.exceptions.HTTPError)
        and exception.response.status_code == codes.too_many_requests
    )

@retry(
    retry=retry_if_exception(should_retry),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    stop=stop_after_attempt(5),
)
def pwn_check(password):
    sha1_password = hashlib.sha1(password.encode("utf-8")).hexdigest().upper()
    prefix, suffix = sha1_password[:5], sha1_password[5:]
    response = requests.get(f"https://api.pwnedpasswords.com/range/{prefix}")
    response.raise_for_status()
    return any(line.split(":")[0] == suffix for line in response.text.splitlines())
```

Next, I want to do this for all the unique passwords in my dataframe with 
[map_elements](https://docs.pola.rs/api/python/stable/reference/expressions/api/polars.Expr.map_elements.html).
Finally, I return the entries where `pwn_check` is `True`:
```python
def pwn_check_unique_passwords(df: pl.DataFrame) -> pl.DataFrame:
    unique_passwords = (
        df.filter(pl.col("Password").is_not_null()).select("Password").unique()
    )
    compromised = unique_passwords.with_columns(
        pl.col("Password")
        .map_elements(pwn_check, return_dtype=pl.Boolean)
        .alias("haveibeenpwnd")
    )
    return (
        df.join(compromised, on="Password", how="left")
        .with_columns(
            pl.col("haveibeenpwnd").fill_null(False)
        )
        .select(pl.all().exclude("Password"))
    )
```

I removed passwords here as I don't need them to check the breached accounts. The 
resulting dataframe cointains accounts that aren't neccissarily compromised, but that at
some point that password has been in a breach. The search found a few old bad passwords, 
that I had to reset / remove.

Here's an example of the output for my dummy data:

{% figure [caption:"**Table 9**: Accounts with potentially compromised passwords"] %}
| Title            | URL                    | Username        | Notes | OTPAuth | modification_date | source   | path              | haveibeenpwnd |
|------------------|------------------------|-----------------|-------|---------|-------------------|----------|-------------------|---------------|
| dummy.com        | https://www.dummy.com/ | dummy@dmail.com |       |         | 1606846453000     | lastpass | lastpass_2020.csv | True          |
| dummy.org        | https://dummy.org      | dummy@dmail.com |       |         | 1669918453000     | lastpass | lastpass_2021.csv | False         |
| https://dummy.at | https://dummy.at       | benutzer        |       |         | 1701454453123     | firefox  | firefox_2023.csv  | True          |
{% endfigure %}

## Conclusion

Polars is fast and powerful, and it encourages the style of coding I prefer when using 
Pandas. I found some tasks with Polars slightly more challenging, but that could be that
I'm still learning. Still, Polars’ lazy loading and transformation capabilities allowed
me to efficiently standardize, clean, and merge password data from multiple sources.

It was useful to get a list of used accounts, I could immediately delete a bunch of old
data. I enjoyed figuring out the HIBP check, tenacity makes it very clean. For the most
used passwords I can manually check on the HIBP website (the API for accounts is not 
free). I picked up some new techniques for filtering and selecting data within 
Polars DataFrames. For my dataset, I didn't really need the additional performance over 
Pandas, but it is nice to have another tool available when it is needed. I like how 
Polars has improved on Pandas, the de facto standard library for data frames in data 
science. I will certainly keep exploring Polars in further projects.
