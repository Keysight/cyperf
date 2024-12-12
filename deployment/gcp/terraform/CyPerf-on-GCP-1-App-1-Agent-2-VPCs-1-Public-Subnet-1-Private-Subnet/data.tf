data "google_client_config" "current" {}

data "google_client_openid_userinfo" "current" {}

data "http" "ip" {
	url = "https://ifconfig.me"
}