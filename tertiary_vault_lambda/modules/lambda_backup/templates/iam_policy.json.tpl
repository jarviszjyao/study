{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${s3_bucket}",
        "arn:aws:s3:::${s3_bucket}/*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey*"
      ],
      "Resource": [
        "${rds_kms_key_arn}",
        "${s3_kms_key_arn}"
      ],
      "Effect": "Allow"
    },
    {
      "Action": "rds:DescribeDBInstances",
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": "rds-db:connect",
      "Resource": "${rds_db_resource_arn}",
      "Effect": "Allow"
    }
  ]
}
