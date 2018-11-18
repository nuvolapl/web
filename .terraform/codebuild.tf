resource "aws_iam_role" "codebuild-project-web" {
    name               = "nuvola-codebuild-project-web"
    assume_role_policy = <<JSON
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "codebuild.amazonaws.com"
            }
        }
    ]
}
JSON
}

resource "aws_iam_role_policy" "codebuild-project-web" {
    name   = "nuvola-codebuild-project-web"
    role   = "${aws_iam_role.codebuild-project-web.id}"

    policy = <<JSON
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": "*",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "ecr:GetAuthorizationToken",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "${var.s3-bucket-arn}",
                "${var.s3-bucket-arn}/*"
            ],
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:PutObject"
            ]
        }
    ]
}
JSON
}

resource "aws_codebuild_project" "web" {
    name          = "nuvola-web"
    build_timeout = 5
    service_role  = "${aws_iam_role.codebuild-project-web.arn}"

    artifacts {
        type = "CODEPIPELINE"
    }

    environment {
        type            = "LINUX_CONTAINER"
        compute_type    = "BUILD_GENERAL1_SMALL"
        image           = "aws/codebuild/docker:17.09.0"
        privileged_mode = true

        environment_variable {
            "name"  = "REGION"
            "value" = "${var.region}"
        }

        environment_variable {
            "name"  = "REPOSITORY_URI"
            "value" = "${aws_ecr_repository.web.repository_url}"
        }

        environment_variable {
            "name"  = "CONTAINER_NAME"
            "value" = "web" // TODO: ?
        }

        environment_variable {
            "name"  = "APP_ENV"
            "value" = "prod" // TODO: ?
        }

        environment_variable {
            "name"  = "APP_DEBUG"
            "value" = 0 // TODO: ?
        }

        environment_variable {
            "name"  = "APP_SECRET"
            "value" = "89d043af398ea705f7cb64a3054b2f03" // TODO: ?
        }
    }

    source {
        type      = "CODEPIPELINE"
        buildspec = <<YML
version: 0.2

phases:
    pre_build:
        commands:
            - $(aws ecr get-login --region $REGION --no-include-email)
            - docker pull $REPOSITORY_URI:latest || true
    build:
        commands:
            - docker build --cache-from $REPOSITORY_URI:latest -f ./.docker/services/web/Dockerfile -t $REPOSITORY_URI:latest --build-arg APP_ENV=$APP_ENV --build-arg APP_DEBUG=$APP_DEBUG --build-arg APP_SECRET=$APP_SECRET .
    post_build:
        commands:
            - docker push $REPOSITORY_URI:latest
            - printf '[{"name":"%s","imageUri":"%s"}]' $CONTAINER_NAME $REPOSITORY_URI:latest > image-definition.json
artifacts:
    files: image-definition.json
YML
    }
}
