variable "okta_org_name" {}
variable "okta_base_url" {}
variable "okta_api_token" {}
variable "google_client_id" {}
variable "google_client_secret" {}
variable "login_redirect_url" {}
variable "logout_redirect_url" {}

terraform {
  required_providers {
    okta = {
      source  = "oktadeveloper/okta"
      version = "~> 3.6"
    }
  }
}

provider "okta" {
  org_name  = var.okta_org_name
  base_url  = var.okta_base_url
  api_token = var.okta_api_token
}


# groups

resource "okta_group" "collection_team" {
  name        = "Collection_Team"
  description = "Collection app team members"
}

resource "okta_group" "collection_administrators" {
  name        = "Collection_Administrators"
  description = "Collection app administrators"
}

resource "okta_group" "collection_line_managers" {
  name        = "Collection_Line_Managers"
  description = "Collection app line managers"
}

resource "okta_group" "collection_guests" {
  name        = "Collection_Guests"
  description = "Collection app guests"
}


# groups roles

resource "okta_group_role" "collection_administrators" {
  group_id  = okta_group.collection_administrators.id
  role_type = "USER_ADMIN"
}

resource "okta_group_role" "collection_line_managers" {
  group_id          = okta_group.collection_line_managers.id
  role_type         = "GROUP_MEMBERSHIP_ADMIN"
  target_group_list = [okta_group.collection_team.id, okta_group.collection_guests.id]
}


# application

resource "okta_app_oauth" "collection_app" {
  label                      = "Collection app"
  type                       = "browser"
  redirect_uris              = [var.login_redirect_url]
  post_logout_redirect_uris  = [var.logout_redirect_url]
  groups                     = [okta_group.collection_administrators.id, okta_group.collection_line_managers.id, okta_group.collection_team.id, okta_group.collection_guests.id]
  response_types             = ["code"]
  grant_types                = ["authorization_code", "refresh_token"] # enable token rotation feature
  token_endpoint_auth_method = "none"
}


# google idp

resource "okta_idp_social" "google" {
  type                = "GOOGLE"
  protocol_type       = "OIDC"
  name                = "collection google idp"
  scopes              = ["profile", "email", "openid"]
  client_id           = var.google_client_id
  client_secret       = var.google_client_secret
  username_template   = "idpuser.email"
  subject_match_type  = "USERNAME"
  provisioning_action = "AUTO"
}


# user custom type

resource "okta_user_type" "collection_user" {
  name   = "collection_user"
  display_name = "Collection App User"
  description = "Collection App User"
}


# user custom properties

resource "okta_user_schema" "squad" {
  index       = "squad"
  title       = "Squad"
  type        = "string"
  scope       = "SELF"
}

resource "okta_user_schema" "joiningDate" {
  index       = "joiningDate"
  title       = "Joining Date"
  type        = "string"
  scope       = "SELF"
}

resource "okta_user_schema" "leaveDate" {
  index       = "leaveDate"
  title       = "Leave Date"
  type        = "string"
  scope       = "SELF"
}

resource "okta_user_schema" "employmentType" {
  index       = "employmentType"
  title       = "Employment type"
  type        = "string"
  scope       = "SELF"
}


# application user properties
# (mapping needed from custom user profile to app profile)

resource "okta_app_user_schema" "example" {
  app_id      = okta_app_oauth.collection_app.id
  index       = "customPropertyName"
  title       = "customPropertyName"
  type        = "string"
  description = "My custom property name"
  scope       = "SELF"
}
