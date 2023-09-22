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
