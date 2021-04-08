variable "okta_org_name" {}
variable "okta_base_url" {}
variable "okta_api_token" {}
variable "google_client_id" {}
variable "google_client_secret" {}
variable "login_redirect_urls" {}
variable "logout_redirect_urls" {}

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


# Groups

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


# Groups roles

resource "okta_group_role" "collection_administrators" {
  group_id          = okta_group.collection_administrators.id
  role_type         = "USER_ADMIN"
  target_group_list = [okta_group.collection_administrators.id, okta_group.collection_line_managers.id, okta_group.collection_team.id, okta_group.collection_guests.id]
}

resource "okta_group_role" "collection_line_managers" {
  group_id          = okta_group.collection_line_managers.id
  role_type         = "USER_ADMIN"
  target_group_list = [okta_group.collection_team.id, okta_group.collection_guests.id]
}


# Oauth application

resource "okta_app_oauth" "collection_app" {
  label                      = "Collection app"
  type                       = "browser"
  redirect_uris              = var.login_redirect_urls
  post_logout_redirect_uris  = var.logout_redirect_urls
  groups                     = [okta_group.collection_administrators.id, okta_group.collection_line_managers.id, okta_group.collection_team.id, okta_group.collection_guests.id]
  response_types             = ["code"]
  grant_types                = ["authorization_code"] # enable Refresh Token (token rotation feature) from ui
  token_endpoint_auth_method = "none"
}


# Google identity provider

resource "okta_idp_social" "google" {
  type                = "GOOGLE"
  protocol_type       = "OIDC"
  name                = "collection google idp"
  scopes              = ["profile", "email", "openid"]
  client_id           = var.google_client_id
  client_secret       = var.google_client_secret
  username_template   = "idpuser.email"
  subject_match_type  = "USERNAME"
  provisioning_action = "DISABLED"
}


# Collection user type

resource "okta_user_type" "collection_user" {
  name         = "collection_user"
  display_name = "Collection User"
  description  = "Collection User"
}


# Collection user custom properties

resource "okta_user_schema" "squad" {
  user_type = okta_user_type.collection_user.id
  index     = "squad"
  title     = "Squad"
  type      = "string"
  scope     = "SELF"
}

resource "okta_user_schema" "target" {
  user_type = okta_user_type.collection_user.id
  index     = "target"
  title     = "Target"
  type      = "string"
  scope     = "SELF"
}

resource "okta_user_schema" "joiningDate" {
  user_type = okta_user_type.collection_user.id
  index     = "joiningDate"
  title     = "Joining Date"
  type      = "string"
  scope     = "SELF"
}

resource "okta_user_schema" "leaveDate" {
  user_type = okta_user_type.collection_user.id
  index     = "leaveDate"
  title     = "Leave Date"
  type      = "string"
  scope     = "SELF"
}

resource "okta_user_schema" "employmentType" {
  user_type = okta_user_type.collection_user.id
  index     = "employmentType"
  title     = "Employment type"
  type      = "string"
  scope     = "SELF"
}


# Collection application user custom properties

resource "okta_app_user_schema" "squad" {
  app_id = okta_app_oauth.collection_app.id
  index  = "squad"
  title  = "Squad"
  type   = "string"
  scope  = "SELF"
}

resource "okta_app_user_schema" "target" {
  app_id = okta_app_oauth.collection_app.id
  index  = "target"
  title  = "Target"
  type   = "string"
  scope  = "SELF"
}

resource "okta_app_user_schema" "joiningDate" {
  app_id = okta_app_oauth.collection_app.id
  index  = "joiningDate"
  title  = "Joining Date"
  type   = "string"
  scope  = "SELF"
}

resource "okta_app_user_schema" "leaveDate" {
  app_id = okta_app_oauth.collection_app.id
  index  = "leaveDate"
  title  = "Leave Date"
  type   = "string"
  scope  = "SELF"
}

resource "okta_app_user_schema" "employmentType" {
  app_id = okta_app_oauth.collection_app.id
  index  = "employmentType"
  title  = "Employment type"
  type   = "string"
  scope  = "SELF"
}

# This is not working on dev organization
# Mapping Collection user properties to Collection app user properties

# resource "okta_profile_mapping" "collection_app" {
#   source_id = okta_user_type.collection_user.id
#   target_id = okta_app_oauth.collection_app.id

#   mappings {
#     id         = "employmentType"
#     expression = "user.employmentType"
#   }
#   mappings {
#     id         = "joiningDate"
#     expression = "user.joiningDate"
#   }
#   mappings {
#     id         = "leaveDate"
#     expression = "user.leaveDate"
#   }
#   mappings {
#     id         = "joiningDate"
#     expression = "user.joiningDate"
#   }
#   mappings {
#     id         = "squad"
#     expression = "user.squad"
#   }
# }
