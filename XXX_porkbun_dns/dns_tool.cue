package dns

import (
	"tool/http"
	"tool/cli"
	"tool/os"
	"encoding/json"
	"encoding/yaml"
)

command: one_time_import: {
	env: os.Environ & {
		PORKBUN_API_KEY_ID: string
		PORKBUN_API_SECRET: string
	}
	auth: {
		apikey:       env.PORKBUN_API_KEY_ID
		secretapikey: env.PORKBUN_API_SECRET
	}
	for zone_name, records in _porkbun_zone_records
	for id, record in records {
		api_request="import_\(id)": http.Post & {
			url: "https://porkbun.com/api/json/v3/dns/create/\(zone_name)"
			request: body:        json.Marshal(record & auth)
			response: statusCode: 200 | 400
		}
		"response_\(id)": cli.Print & {
			text: json.Marshal({(id): json.Unmarshal(api_request.response.body)})
		}
	}
}

command: dump: cli.Print & {
	//text: yaml.Marshal(zones)
	text: yaml.Marshal(_porkbun_zone_records)
}

// https://www.mythic-beasts.com/support/api/dnsv2#sec-request-body-json1
_porkbun_zone_records: [Zone=string]: [string]: _PorkbunZoneRecord
_porkbun_zone_records: {
	for zone_name, zone_config in zones {
		(zone_name): {
			for host_name, record_types in zone_config
			for record_type, records in record_types
			for record_content, record in records
			let id = "\(host_name).\(zone_name):\(record_type):\(record_content)" {
				(id): {
					if record_type == "ANAME" {
						type: "ALIAS"
					}
					if record_type != "ANAME" {
						type: record_type
					}
					content: record_content
					if record.pri != _|_ {prio: record.pri}
					if host_name != "@" {name: host_name}
					if record.ttl != _|_ {ttl: record.ttl}
				}
			}
		}
	}
}

_PorkbunZoneRecord: {
	name?:    string
	type!:    "A" | "MX" | "CNAME" | "ALIAS" | "TXT" | "NS" | "AAAA" | "SRV" | "TLSA" | "CAA"
	content!: string
	ttl?:     int
	prio?:    int
}
