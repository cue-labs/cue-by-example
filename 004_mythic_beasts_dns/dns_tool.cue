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
			for rrtype in ["A", "AAAA", "ANAME", "CNAME", "NS", "TXT"]
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
