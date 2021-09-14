#!/bin/sh
set -e

# Content Security Policy
# Note: Add “plugin-types ;” when you add “object-src”
IFS='' read -r -d '' CSP <<-'EOD' || true
	sandbox
		allow-scripts
		allow-forms
		allow-same-origin;
	referrer
		no-referrer;
	reflected-xss
		block;
	report-uri
		/api/rpc/csp_report;
	default-src
		'none';
	img-src
		'self' ;
	style-src
		'self'
		cdnjs.cloudflare.com;
	font-src
		'self'
		cdn.auth0.com
		cdnjs.cloudflare.com;
	script-src
		'self'
		example.auth0.com
		cdn.auth0.com
		code.jquery.com
		cdnjs.cloudflare.com;
	connect-src
		'self'
		example.auth0.com;
EOD

# Remove newlines
CSP=$(echo "$CSP" | tr '[\t\n]' ' ')

cat > /etc/nginx/conf.d/default.conf <<-'EOD'

	# Override some defaults
	charset utf-8;
	server_tokens off;
	underscores_in_headers on;

	# Log to files
	error_log /var/log/nginx/error.log warn;
	access_log /var/log/nginx/access.log;

EOD

# Check if we have a domain and certificate, if not, skip the TLS.
certfile="/etc/ssl/certs/live/{{ cookiecutter.domain_name }}/privkey.pem"
if [ \( -z "{{ cookiecutter.domain_name }}" \) -o \( ! -f ${certfile} \) ]; then

	echo "WARNING: No certificate found. Starting with no TLS configuration"

	cat >> /etc/nginx/conf.d/default.conf <<-'EOD'
		# Serve on http
		server {
			listen 80;
			listen [::]:80 ipv6only=on;

			# ACME challenges for letsencrypt
			location /.well-known/acme-challenge {
				default_type text/plain;
				root /srv/acme-challenge;
				try_files $uri =404;
			}

			# Proxy api requests to the PostgREST
			location /api/ {
				proxy_pass http://api:3000/;
				
				# Rewrite Content-Location header
				proxy_hide_header Content-Location;
				add_header  Content-Location  /api$upstream_http_content_location;
				proxy_hide_header Location;
				add_header  Location  /api$upstream_http_location;
			}
		}
	EOD
	
else
	
	cat >> /etc/nginx/conf.d/default.conf <<-'EOD'
		# Force secure protocols
		ssl_protocols TLSv1.1 TLSv1.2;
		ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
		ssl_prefer_server_ciphers on;
		ssl_session_cache shared:SSL:10m;

		# Load custom DH parameters
		ssl_dhparam /etc/ssl/certs/dhparam.pem;

		# OCSP stapling
		ssl_stapling on;
		ssl_stapling_verify on;
		resolver 8.8.8.8 8.8.4.4 valid=300s;
		resolver_timeout 5s;

		# Add headers to tell browsers to be stricter
		add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload" always;
		add_header X-Content-Type-Options "nosniff" always;
		add_header X-Frame-Options "DENY" always;
		add_header X-XSS-Protection "1; mode=block" always;
		add_header Content-Security-Policy "CONTENTSECURITYPOLICY" always;
		add_header Access-Control-Allow-Origin "https://{{ cookiecutter.domain_name }}" always;

		# Redirect all http to https (except the ACME challenge)
		server {
			listen 80;
			listen [::]:80 ipv6only=on;

			# ACME challenges for letsencrypt
			location /.well-known/acme-challenge {
				default_type text/plain;
				root /srv/acme-challenge;
				try_files $uri =404;
			}

			# Redirect to TLS
			location / {
				return 301 https://{{ cookiecutter.domain_name }}$request_uri;
			}
		}

		server {
			listen 443 default_server;
			listen [::]:443 default_server ipv6only=on;
			server_name {{ cookiecutter.domain_name }};

			# Certificates
			ssl on;
			ssl_certificate     /etc/ssl/certs/live/{{ cookiecutter.domain_name }}/fullchain.pem;
			ssl_certificate_key /etc/ssl/certs/live/{{ cookiecutter.domain_name }}/privkey.pem;

			# Proxy api requests to the PostgREST
			location /api/ {
				proxy_pass http://api:3000/;

				# Rewrite Content-Location header
				proxy_hide_header Content-Location;
				add_header  Content-Location  /api$upstream_http_content_location;
				proxy_hide_header Location;
				add_header  Location  /api$upstream_http_location;
			}
		}
	EOD

	sed -i "s|CONTENTSECURITYPOLICY|${CSP}|g" /etc/nginx/conf.d/default.conf

fi

exec nginx -g 'daemon off;'
