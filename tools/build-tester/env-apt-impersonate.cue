package cake

import (
	"duponey.cloud/scullery"
	"duponey.cloud/buildkit/types"
)

UserDefined: scullery.#Icing & {
	buildkit: {
		address: "tcp://buildkit.local:443"
		// name: "buildkit.local"
		// XXX Could use <<<"yada yada" ?
		// or some other form of temp?
		// ca: "/Users/dmp/Projects/Distribution/docker-images/config/home/ca.pem"
		// cert: "/Users/dmp/Projects/Distribution/docker-images/config/home/cert.pem"
		// key: "/Users/dmp/Projects/Distribution/docker-images/config/home/key.pem"
	}

	hosts: {
		// This allows usage of the apt-front with mTLS
		"snapshot.debian.org": {
			ip: "10.0.4.109"
			https: {
				login: "dubodubonduponey"
				password: "aFBZBVJ6EjcFXyktok3osCeV6pc"
			}
		}
		"security.debian.org": {
			ip: "10.0.4.109"
			https: {
				login: "dubodubonduponey"
				password: "aFBZBVJ6EjcFXyktok3osCeV6pc"
			}
		}
		"deb.debian.org": {
			ip: "10.0.4.109"
			https: {
				login: "dubodubonduponey"
				password: "aFBZBVJ6EjcFXyktok3osCeV6pc"
			}
		}
		"archive.debian.org": {
			ip: "10.0.4.109"
			https: {
				login: "dubodubonduponey"
				password: "aFBZBVJ6EjcFXyktok3osCeV6pc"
			}
		}
		"apt-front.local": {
			ip: "10.0.4.109"
			https: {
				login: "dubodubonduponey"
				password: "aFBZBVJ6EjcFXyktok3osCeV6pc"
			}
		}
		"apt-mirror.local": {
			ip: "10.0.4.107"
			https: {
				login: "dubodubonduponey"
				password: "aFBZBVJ6EjcFXyktok3osCeV6pc"
			}
		}
		//"registry.local": {
		//	ip: "10.0.4.102"
		//}
		// XXX are go tools able to resolve using NSS? If no, then the IP is mandatory here
		"go.local": {
			ip: "10.0.4.98"
			https: {
				login: "dubodubonduponey"
				password: "aFBZBVJ6EjcFXyktok3osCeV6pc"
			}
		}
		// For proxy-ed testing purpose only
		"apt-proxy.local": {
			ip: "10.0.4.97"
			https: {
				login: "dubodubonduponey"
				password: "aFBZBVJ6EjcFXyktok3osCeV6pc"
			}
		}
	}

	// This is really problematic as it depends on the targetted date, but is for now the only way around short of committing our private mirror
	subsystems: {
		curl: {
			user_agent: "DuboDubonDuponey/1.0 (curl)"
		}
		apt: {
			user_agent: "DuboDubonDuponey/1.0 (apt)"

			// Proxy scenario
			//proxy: "https://apt-proxy.local"
			//sources: #"""
			//# Bullseye circa June 1st 2021
			//deb http://snapshot.debian.org/archive/debian/20210701T000000Z bullseye main
			//deb http://snapshot.debian.org/archive/debian-security/20210701T000000Z bullseye-security main
			//deb http://snapshot.debian.org/archive/debian/20210701T000000Z bullseye-updates main

			//"""#

			// This is problematic - it does impact debian debootstrap, which is pinned at 07-01
			// We should really get done with this, once we have apt-front serving http redirects?
			sources: #"""
			# Bullseye circa June 1st 2021
			deb https://snapshot.debian.org/archive/debian/20210801T000000Z bullseye main
			deb https://snapshot.debian.org/archive/debian-security/20210801T000000Z bullseye-security main
			deb https://snapshot.debian.org/archive/debian/20210801T000000Z bullseye-updates main

			# Cannot work with the proxy
			#deb https://apt-mirror.local/archive/bullseye/20210701T000000Z bullseye main
			#deb https://apt-mirror.local/archive/bullseye-updates/20210701T000000Z bullseye-updates main
			#deb https://apt-mirror.local/archive/bullseye-security/20210701T000000Z bullseye-security main

			"""#
			check_valid: false
		}
		go: {
			proxy: "https://go.local"
		}
	}

	trust: {
		authority: #"""
			-----BEGIN CERTIFICATE-----
			MIIBozCCAUmgAwIBAgIQBd+mZ7Uj+1lnuzBd1klrvzAKBggqhkjOPQQDAjAwMS4w
			LAYDVQQDEyVDYWRkeSBMb2NhbCBBdXRob3JpdHkgLSAyMDIwIEVDQyBSb290MB4X
			DTIwMTEzMDIzMTA0NVoXDTMwMTAwOTIzMTA0NVowMDEuMCwGA1UEAxMlQ2FkZHkg
			TG9jYWwgQXV0aG9yaXR5IC0gMjAyMCBFQ0MgUm9vdDBZMBMGByqGSM49AgEGCCqG
			SM49AwEHA0IABOzpNQ/wkHMGFibVR5Gk14PspP+kQ5LpR3XWwvD+rpJjhylvQLW3
			/ZvOzKHKHfilkOHI3FCHct8IImF5qhpbJF6jRTBDMA4GA1UdDwEB/wQEAwIBBjAS
			BgNVHRMBAf8ECDAGAQH/AgEBMB0GA1UdDgQWBBTGwiMW3cMgyEeZY09nyHbUWMCt
			5TAKBggqhkjOPQQDAgNIADBFAiBKZePDr6aXHiMwESluwVM1/y/WVMr4dPNcf2+4
			JX0jYwIhALi9+u+eHd2DGP93NXXMgcZMV+YwhSuaFu04pY6Mdwul
			-----END CERTIFICATE-----

			"""#

		// Useful with apt-mirror, but does not work when repo=snapshot
		//gpg: "../../config/home/trusted.gpg"

		certificate: #"""
			-----BEGIN CERTIFICATE-----
			MIIBHzCBxgIJALF+7AsQz4aOMAoGCCqGSM49BAMCMDAxLjAsBgNVBAMTJUNhZGR5
			IExvY2FsIEF1dGhvcml0eSAtIDIwMjAgRUNDIFJvb3QwHhcNMjEwNzAxMDAzMzA1
			WhcNMjIwNzAxMDAzMzA1WjAAMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEn0cz
			Tjv3/P4OoUmnPEXQIdUB4OHTWcU2XAWisSrjCTWum8nrJpkVOlyGg9M1tKFRJa8F
			Dl0GEshRFQRc0b1/1jAKBggqhkjOPQQDAgNIADBFAiEA8H8n9xxSfFG1mVWZ3221
			wPx8lzs0tx3xeAwytyZKziMCIEQIw0/ei8ubhCmUtw/P9SS0JWZAXCIcktCZc7uH
			7OeY
			-----END CERTIFICATE-----

			"""#

		key: #"""
			-----BEGIN EC PRIVATE KEY-----
			MHcCAQEEIMMiHMv4aai/3PNh+4TM+NId5h4opm1FikGHUkF8D8fLoAoGCCqGSM49
			AwEHoUQDQgAEn0czTjv3/P4OoUmnPEXQIdUB4OHTWcU2XAWisSrjCTWum8nrJpkV
			OlyGg9M1tKFRJa8FDl0GEshRFQRc0b1/1g==
			-----END EC PRIVATE KEY-----

			"""#

		// Unseal Key: j0XY4SOrDBbP0WxH5xHA/Ls/COq6Y5iMI8SVKqLgdYU=
 		// Root Token: s.vJD8smSEQmWJ6KuKQBp4Hb1t
	}

	// XXX this is not good and a conundrum - the location of this is a function of the image target and name
	cache: {
		base: types.#CacheFrom & {#fromString: * (types.#CacheFrom & {
			type: types.#CacheType.#LOCAL
			location: "./cache/buildkit"
		}).toString | string @tag(cache_base, type=string)}
	}

}
