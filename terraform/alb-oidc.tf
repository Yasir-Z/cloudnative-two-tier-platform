resource "aws_iam_openid_connect_provider" "default" {
  url = "https://oidc.eks.us-east-1.amazonaws.com/id/D375D6B648CC47619577F7710B401F0D"

  client_id_list = ["sts:awsamazone.com"]

}

