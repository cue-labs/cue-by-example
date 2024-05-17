# Managing [Mythic Beasts DNS](https://www.mythic-beasts.com/support/domains/primarydns) zones with CUE
<sup>by [Jonathan Matthews](https://jonathanmatthews.com)</sup>
<sup>with essential CUE contributions from [Roger Peppe](https://github.com/rogpeppe)</sup>

## Introduction

[Mythic Beasts](https://www.mythic-beasts.com/) is a UK-based company whose
["About" page](https://www.mythic-beasts.com/article/about) says they are ...

> a privately owned hosting ISP with a focus on providing services to
> technically capable customers.

Mythic Beasts publishes an API that allows customers to replace all the DNS
records in a specific zone *without* using a web-based control panel.

This guide demonstrates how CUE can be used to keep the underlying DNS records
in an elegant and compact format that uses templating to DRY out
configurations, whilst also allowing policy enforcement to guard against
mistakes.

It also uses CUE's scripting layer as the mechanism that triggers API-based
replacements of DNS zones hosted by Mythic Beasts. However, this implementation
detail is relatively unimportant because of some good design decisions made by
the Mythic Beasts DNS API.

## Set up

### Prerequisites

To use this guide, you need to:

- [install the `cue` command](https://alpha.cuelang.org/docs/introduction/installation/)
- have one or more domains with a DNS service
  [provided by Mythic Beasts](https://www.mythic-beasts.com/customer/domains)

### Create CUE files

5 files need to be created. They're presented inline, in this guide, and also
as stand-alone files in this guide's directory in this repo.

The first 3 files, `zones.cue`, `policy.cue`, and `shared.cue`, are data files.
Their contents must be adapted to reflect your DNS zones and records.

The last 2 files, `schema.cue` and `dns_tool.cue`, should be used exactly as
presented in this guide. They contain the system's implementation, and don't
need to be adapted in any way.

#### :arrow_right: Create `zones.cue`

:floppy_disk: `zones.cue`
```CUE
package dns

// This file contains DNS records for 3 separate zones:
//   - "my-primary-domain.test"
//   - "infrastructure-domain.test"
//   - "another-domain.example"

// Each zone has Google Workspace email-related DNS records (MX, SPF, and
// DKIM), as templated by the CUE in "shared.cue".

// Additionally, in this file:
// "my-primary-domain.test" is a domain containing:
//   - a Wordpress site at my-primary-domain.test
//   - a different website at www.my-primary-domain.test
//   - a Wordpress-hosted blog at blog.my-primary-domain.test
//   - a test blog at test.blog.my-primary-domain.test
//   - an internally-hosted site split across 2 servers at dev.my-primary-domain.test
zones: "my-primary-domain.test": {
	// the zone apex uses the provider's ANAME/ALIAS feature for CNAME-like
	// behaviour at the zone's root, resolving to a Wordpress.com-hosted site
	"@": ANAME: "lb.wordpress.com": ttl: 3600

	// "www" has a pair of IPv4 and IPv6 records, with harmonised TTLs
	www: {
		_www_ttl: 300
		A: "192.0.2.0": ttl:                                 _www_ttl
		A: "198.51.100.0": ttl:                              _www_ttl
		AAAA: "2001:db8:0001:0001:0001:0001:0001:0001": ttl: _www_ttl
		AAAA: "2001:db8:ffff:ffff:ffff:ffff:ffff:ffff": ttl: _www_ttl
	}

	// "blog" is a Wordpress.com site with a custom domain
	blog: CNAME: "lb.wordpress.com": ttl: 3600

	// "test.blog" is a CNAME towards a Heroku-hosted test instance of Wordpress
	"test.blog": CNAME: "whispering-willow-5678.ssl.herokudns.com": ttl: 3600

	// "dev" has round-robin A records, with linked TTLs
	dev: A: "192.168.0.1": ttl: 600
	dev: A: "192.168.1.1": ttl: 2 * dev.A."192.168.0.1".ttl
}

// "infrastructure-domain.test" is a domain containing:
//   - a site at the domain apex
//   - a pointer to a different site at "www."
//   - some IPv4 and IPv6 records at "local."
zones: "infrastructure-domain.test": {
	// the zone apex A record
	"@": A: "172.20.1.2": ttl: 3600

	// "www" is a CNAME to another host"
	www: CNAME: "www.example.com": ttl: 300

	// "local" has both v4 and v6 IP records
	local: {
		A: "127.0.0.1": ttl:          3600
		AAAA: "0:0:0:0:0:0:0:1": ttl: 3600
	}
}

// "another-domain.example" is a domain containing:
//   - a pointer to a site at the domain apex
//   - a pointer to the domain apex at "www."
zones: "another-domain.example": {
	// the zone apex uses the provider's ANAME/ALIAS feature for CNAME-like
	// behaviour at the zone's root
	"@": ANAME: "www.example.com": ttl: 86400

	// "www" is a CNAME to the zone apex
	www: CNAME: "another-domain.example": ttl: 300
}
```

`zones.cue` contains the structured data that represents each zone - notice how
compact the data format is. Later in this guide you'll adapt this file to
reflect your DNS zones.

#### :arrow_right: Create `policy.cue`

:floppy_disk: `policy.cue`
```CUE
package dns

zones?: {
	// These policies apply to all zones
	[_]: {
		// www must exist
		www!: _
	}

	// These policies apply only to our primary domain
	"my-primary-domain.test": {
		// "blog.my-primary-domain.test", must exist (as it makes all our revenue)
		blog!: _
	}
}

// The definition of #TTL in `schema.cue` unifies with this definition.
// Require that all TTLs are 60 seconds or greater
#TTL: >=60
```

#### :arrow_right: Create `shared.cue`

:floppy_disk: `shared.cue`
```CUE
package dns

zones: [Zone=string]: {
	"@": {
		MX: {
			_mx_ttl: 3600
			"aspmx.l.google.com": {pri: 1, ttl: _mx_ttl}
			"alt1.aspmx.l.google.com": {pri: 5, ttl: _mx_ttl}
			"alt2.aspmx.l.google.com": {pri: 5, ttl: _mx_ttl}
			"alt3.aspmx.l.google.com": {pri: 10, ttl: _mx_ttl}
			"alt4.aspmx.l.google.com": {pri: 10, ttl: _mx_ttl}
		}
		TXT: "v=spf1 include:_spf.google.com ~all": ttl: 3600
	}
	#DKIM?: pubkey?: string
	if #DKIM != _|_ if #DKIM.pubkey != _|_ {
		"google._domainkey": TXT: "v=DKIM1; k=rsa; p=\(#DKIM.pubkey)": ttl: 600
	}
}

zones: "my-primary-domain.test": #DKIM: pubkey:
	"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApINijpsDxy12WvwIoNZvO4hT+73BatBfqMUWMS+DWwRV6kJHlil0TJUZWJ/TwwfRGFbkjz4EIsmk+YipLRdBIYD9NDF7c2fP23+XWXJtIq27n/88m/jZyDr5N4YQCXM4yUpYbal84RKAdebEqeInwTk2UKqfQ4ysoJdWZzY8wkCUIND3AyU8gBX+uq3bdLLWUNJp4Uwe4EY0TEn28xZy5R0hdILPANS/l07QpOocw3/1IWChmRb/2h4/64PLJfKveTApGJBNNNqBTqolKAMZjbVu6gNMWi04tGkEcD2o7zenHF8pLKuUxmZAM1Z/voTjxiDfr1q9pOS+vqg2LXv1UwIDAQAB"

zones: "infrastructure-domain.test": #DKIM: pubkey:
	"MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApINijpsDxy12WvwIoNZvO4hT+73BatBfqMUWMS+DWwRV6kJHlil0TJUZWJ/TwwfRGFbkjz4EIsmk+YipLRdBIYD9NDF7c2fP23+XWXJtIq27n/88m/jZyDr5N4YQCXM4yUpYbal84RKAdebEqeInfkskvmkl4mg34gGdsfg%hy53refgshtrwedsdgdfhhSSSSSSafgrthgdsdcc\vftjhjasafas/fdsssdf/gfddasdhhrgrsd2h4/64PLJfKveTApGJBNNNqBTqolKAMZjbVu6gNMWi04tGkEcD2o7zenHF8pLKuUxmZAM1Z/voTjxiDfr1q9pOS+vqg2LXv1UwIDAQAB"

zones: "another-domain.example": #DKIM: pubkey:
	"MIIBIjANBgakvk4kfmkddddadvrefsdgfsdfdasgfQEApINijpsDxy12WvwIoNZvO4hT+73BatBfqMUWMS+DWwRV6kJHlil0TJUZWJ/TwwfRGFbkjz4EIsmk+YipLRdBIYt4kfcklsdamkvkldfslamncvkdmaslfnvnkslmvmsdv/aefmksdlsdmgmksadmgkdshHGET$HS3ttg5zY8wkCUIND3AyU8gBX+uq3bdLLWUNJp4Uwe4EY0TEn28xZy5R0hdILPANS/l07QpOocw3/1IWChmRb/2h4/64PLJfKveTApGJBNNNqBTqolKAMZjbVu6gNMWi04tGkEcD2o7zenHF8pLKuUxmZAM1Z/voTjxiDfr1q9pOS+vqg2LXv1UwIDAQAB"
```

`shared.cue` uses CUE's "template" feature to add records to all the zones
contained in `zones.cue`. We use it in this guide's example data to create the
same Google Workspace MX (Mail eXchanger) and SPF (Sender Policy Framework)
records in every zone, and to set up DKIM-related CNAMEs that have
zone-specific keys placed inside a standardised record structure.

Note that *these are simply examples* of specifying types of DNS records that
often need to be kept in sync across multiple domains - you don't *need* to
have them set up like this.

#### :arrow_right: Create `schema.cue`

:floppy_disk: <code>schema.cue</code>

```CUE
package dns

import (
	"net"
	"struct"
)

zones: [_]: #Zone

#Zone: {
	[#Host]: {
		struct.MinFields(1)
		A?:     #A
		AAAA?:  #AAAA
		ANAME?: #ANAME
		CNAME?: #CNAME
		MX?:    #MX
		NS?:    #NS
		TXT?:   #TXT
	}
	#DKIM?: pubkey?: string
}

#Host: #FQDN | "@" // "@" indicates the zone apex/root
#FQDN: net.FQDN & string

#A: [#IPv4]:     #Record
#AAAA: [#IPv6]:  #Record
#ANAME: [#FQDN]: #Record
#CNAME: [#FQDN]: #Record
#MX: [#FQDN]:    #Record & {
	pri: int
}
#NS: [#FQDN]:   #Record
#TXT: [string]: #Record

#Record: {
	ttl: #TTL
	...
}
#TTL: int & >=0 & <=2147483647

#IPv6: string // https://github.com/cue-lang/cue/issues/2614
#IPv4: net.IPv4 & string
```

`schema.cue` contains the schema for the DNS zones and records you'll provide.
CUE will validate your data against this schema each time the data is used,
flagging up mistakes before they're submitted to the API.

This file should be used as presented, without adapting it. It doesn't contain
any zone- or record-specific data.

#### :arrow_right: Create `dns_tool.cue`

<hr>
<details>
<summary>
:floppy_disk: <code>dns_tool.cue</code> (click to open)
</summary>

```CUE
package dns

import (
	"tool/http"
	"tool/cli"
	"tool/os"
	"encoding/base64"
	"encoding/json"
	"encoding/yaml"
)

command: update: {
	// https://www.mythic-beasts.com/support/api/auth
	auth: {
		env: os.Environ & {
			MYTHIC_BEASTS_API_KEY_ID: string
			MYTHIC_BEASTS_API_SECRET: string
		}
		login: http.Post & {
			_auth: {
				username: env.MYTHIC_BEASTS_API_KEY_ID
				password: env.MYTHIC_BEASTS_API_SECRET
				header:   "Basic " + base64.Encode(null, "\(username):\(password)")
			}

			// https://www.mythic-beasts.com/support/api/auth#sec-obtaining-a-token
			url: "https://auth.mythic-beasts.com/login"
			tls: verify:   true
			request: body: "grant_type=client_credentials"
			request: header: Authorization:  _auth.header
			request: header: "Content-Type": "application/x-www-form-urlencoded"
			response: statusCode: 200
		}

		// https://www.mythic-beasts.com/support/api/auth#sec-making-api-requests
		token: "Bearer " + json.Unmarshal(login.response.body).access_token
	}
	for zone_name, records in _mythic_beast_zone_records {
		api_request="replace_\(zone_name)": http.Put & {
			// https://www.mythic-beasts.com/support/api/dnsv2#ep-put-zoneszonerecords
			url: "https://api.mythic-beasts.com/dns/v2/zones/\(zone_name)/records?exclude-template&exclude-generated"
			request: body: json.Marshal({"records": records})
			request: header: Authorization:  auth.token
			request: header: "Content-Type": "application/json"
			response: statusCode: 200
		}
		"response_\(zone_name)": cli.Print & {
			text: json.Marshal({(zone_name): json.Unmarshal(api_request.response.body)})
		}
	}
}

command: dump: cli.Print & {
	text: yaml.Marshal(zones)
}

// https://www.mythic-beasts.com/support/api/dnsv2#sec-request-body-json1
_mythic_beast_zone_records: [Zone=string]: [..._MythicBeastsZoneRecord]
_mythic_beast_zone_records: {
	for zone_name, zone_config in zones {
		(zone_name): [
			for host_name, host_config in zone_config
			for rrtype in [ "A", "AAAA", "ANAME", "CNAME", "NS", "TXT"]
			for _data, _record in (*host_config[rrtype] | {}) {
				{host: host_name, ttl: _record.ttl, type: rrtype, data: _data}
			},
			for host_name, host_config in zone_config
			for _data, _record in (*host_config.MX | {}) {
				{host: host_name, ttl: _record.ttl, type: "MX", data: _data, "mx_priority": _record.pri}
			},
		]
	}
}

_MythicBeastsZoneRecord: {
	host: string
	ttl:  int
	type: "A" | "AAAA" | "ANAME" | "CNAME" | "MX" | "NS" | "TXT"
	data: string
}
```
</details>
<hr>

As with `schema.cue`, `dns_tool.cue` is part of the system's implementation,
and should be used as presented.

`dns_tool.cue` contains a CUE workflow command which performs the necessary API requests
to replace all DNS zones' records. A CUE workflow command is included here to provide a
way of using the `cue` command, by itself, to drive changes via the Mythic
Beasts API.

However, because using a CUE workflow command to *perform* these requests isn't the main
point of this guide, you should feel free to swap it out for anything that
suits your needs better - a shell script, a Golang utility, a Python script:
any language will easily be able to make the necessary requests. 

This is because the *specific* Mythic Beasts API targetted is both *genuinely*
declarative (meaning it's not just *mostly* declarative, but also treats
"missing" records in its input as a request to *delete* those records) and
atomic (meaning each DNS zone update either succeeds or fails completely).

These two properties mean that *any* tooling could make the API requests, using
JSON exported by CUE. CUE would still perform early, powerful data validatation
and composition, through the contents of all the CUE files (except
`dns_tool.cue`), but no complex request payload calculation or interdependent
request sequencing would need to be performed by the *tool* that calls the API.

## Make DNS changes

### Grant API access to the system

#### :arrow_right: Create an API key

Create an API key via
[the Mythic Beasts UI](https://www.mythic-beasts.com/customer/api-users/create).

Give the API key an appropriate name.

Under the `Primary DNS API v2` heading click "Add permit" once for each zone
you want the system to manage.

For each zone, add a permit with a Hostname setting of `*`, a Zone setting
matching the DNS zone's name, and a Type setting of `(all)`.

Click "Create API key" at the bottom of the page, and copy the API key's ID and
secret from the next page that the site displays.

#### :arrow_right: Export the API key

Expose the API key to the system by exporting the API key's ID and secret via 2
environment variables:

- `MYTHIC_BEASTS_API_KEY_ID`: your API key ID
- `MYTHIC_BEASTS_API_SECRET`: your API secret

### Edit the DNS records to match your zones

#### :arrow_right: Add your DNS records

Replace the contents of `zones.cue`, `policy.cue`, and `shared.cue` so that
they reflect *your* DNS zones' records - both the zone-specific and shared
records, along with any policies you want to impose on the records now and in
the future.

Make sure to include **all** DNS records that already exist in your zones.

#### :arrow_right: Validate the DNS records

Use the `dump` CUE workflow command to display all the records you've configured.

:rotating_light::rotating_light::rotating_light:\
**For each zone you've configured, ONLY the records displayed will exist after
using this system. Every currently-existing record that's *missing* from the
`dump` workflow command's output will be REMOVED - so check the output against your
current zone contents carefully!**\
:rotating_light::rotating_light::rotating_light:

:computer: `terminal`
```sh
cue cmd dump
```

Output like this (truncated) example will be displayed:

```
my-primary-domain.test:
  '@':
    ANAME:
      lb.wordpress.com:
        ttl: 3600
    MX:
      aspmx.l.google.com:
        pri: 1
        ttl: 3600
      alt1.aspmx.l.google.com:
        pri: 5
        ttl: 3600
      alt2.aspmx.l.google.com:
        pri: 5
        ttl: 3600
      alt3.aspmx.l.google.com:
        pri: 10
        ttl: 3600
      alt4.aspmx.l.google.com:
        pri: 10
[ ... truncatated ... ]
```

### Replace DNS zones

#### :arrow_right: Change *all* DNS records in *all* zones

|   :exclamation: WARNING :exclamation:   |
|:--------------------------------------- |
| The API calls used by this guide **completely replace ALL existing records stored in a Mythic Beasts DNS zone**.<br>It is **not possible** to bring such a DNS zone *incrementally* under the control of the system outlined in this guide.<br><br>To use this guide safely, either use a test DNS zone with unimportant contents, or export the contents of a non-test zone and convert them *exhaustively and carefully* into the structured data format demonstrated in this guide.

Having read the warning, above, invoke the CUE workflow command as follows.

*This will **replace** all DNS records across all the zones you've configured*:

:computer: `terminal`
```sh
cue cmd update
```

Upon success, the following output is displayed:

```
{"infrastructure-domain.test":{"message":"11 records added","records_added":11,"records_removed":11}}
{"my-primary-domain.test":{"message":"16 records added","records_added":16,"records_removed":12}}
{"another-domain.example":{"message":"9 records added","records_added":9,"records_removed":13}}
```

#### :arrow_right: Save your files

Version control all the files that you amended or copied. These should include:

- `zones.cue`
- `policy.cue`
- `shared.cue`
- `schema.cue`
- `dns_tool.cue`

One of CUE's nice properties is that, once you understand how its core
"unification" mechanism works, you can trivially split the contents of all
these files into as many files as you like. For example, you can keep each
zone in its own file if that layout suits you best.

## Related content

- Mythic Beasts API accepts these record types, with these schemata:
  - https://www.mythic-beasts.com/support/api/dnsv2#ep-get-record-types
  - https://api.mythic-beasts.com/dns/v2/record-types
- The DNS API's OpenAPI schema:
  - https://www.mythic-beasts.com/support/api/dnsv2?format=yaml
