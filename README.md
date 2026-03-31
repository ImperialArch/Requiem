# Requiem
Crawls a URL and finds every link that's already dead (pretty straightforward).

## What It Does
It fetches the page, extracts every `https?` href, and checks them concurrently. Follows up to 5 redirects. Falls back from HEAD to GET on servers that don't support it.

Two categories of failure:
- dead - got a response but wasn't 2xx
- unreachable - connection failed entirely

## Dependencies
```
cpan LWP::UserAgent
cpan JSON
```
I was able to run it without having to run `cpan JSON` on a fresh perl install but for safety measures if you run into any issue.

## Usage
```
perl requiem.pl <url> [--concurrency=N] [--output=filename]
```
 - `--concurrency` defaults to 12.
 - `--output` saves results as a json.

## Example
```
perl requiem.pl https://en.wikipedia.org/wiki/Perl --concurrency=15 --output=perlWiki
```

Output:
```
Total Links: 511
Unreachable Links: 112
Dead Links: 40
```
Check `example\perlWiki.json` for a sample JSON output

## Little Note
I built this partially because I'm overwhelmed currently by taking large projects and needed to just have fun a bit. Also don't ask why Perl. I know you are running Linux which has perl installed by default :)
