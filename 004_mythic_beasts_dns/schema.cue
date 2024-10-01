package dns

import (
	"net"
	"struct"
)

zones: [_]: #Zone

#Zone: {
	[#Host]: {
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
#MX: [#FQDN]: #Record & {
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
