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
