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
