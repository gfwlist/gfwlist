# Introduction #

This page will explain the rules being used by gfwlist. It's easy to learn.

# Details #

Currently these formats are supported in rules:

  * example.com
Matching: http://www.example.com/foo
Matching: http://www.google.com/search?q=www.example.com
Not match: https://www.example.com/
Use when example.com is a URL keyword, any http connection (notincluding https)

  * ||example.com
Matching: http://example.com/foo
Matching: https://subdomain.example.com/bar
Not matching: http://www.google.com/search?q=example.com
Match the whole domain and second-level domain no matter http or https, used when site's IP is blocked.

  * |https://ssl.example.com
Match all address beginning with https://ssl.example.com, used when some IP's HTTPS is specifically blocked.

  * |http://example.com
Match all address beginning with http://example.com, used for short domains, like URL shortening services to avoid "slow rules". Also a temporary fix for [issue 117](https://code.google.com/p/autoproxy-gfwlist/issues/detail?id=117).

  * /<sup>https?:\/\/[</sup>\/]+example\.com/
Match domain including "example.com" chars, it's a regex, used when the chars are DNS poisoning keyword.

  * @@||example.com
The highest privilege rule, all websites matching ||example.com aren't proxied, sometimes used for websites in China mainland.

  * !Foo bar
Beginning with !, just for explanation.