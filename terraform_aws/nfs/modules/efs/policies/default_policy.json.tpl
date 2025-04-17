{
  "Version": "2012-10-17",
  "Id": "DefaultEfsFileSystemPolicy",
  "Statement": [
    {
      "Sid": "EnforceEncryptionInTransit",
      "Effect": "Deny",
      "Principal": {"AWS": "*"},
      "Action": [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite"
      ],
      "Resource": "${file_system_arn}",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    },
    {
      "Sid": "BlockPublicAccess",
      "Effect": "Deny",
      "Principal": {"AWS": "*"},
      "Action": [
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:ClientRootAccess"
      ],
      "Resource": "${file_system_arn}",
      "Condition": {
        "Bool": {
          "elasticfilesystem:AccessedViaMountTarget": "true"
        },
        "NotIpAddress": {
          "aws:SourceIp": ${allowed_ips}
        }
      }
    }
  ]
} 